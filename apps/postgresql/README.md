# PostgreSQL Database

A generic PostgreSQL instance deployed via Bitnami Helm chart, designed to host databases for multiple services.

## Overview

- **Chart**: Bitnami PostgreSQL from https://charts.bitnami.com/bitnami
- **Version**: 18.1.1
- **Architecture**: Standalone (single instance)
- **Storage**: 15Gi Longhorn persistent volume
- **Namespace**: postgresql

## Design Philosophy

This PostgreSQL instance is designed to be **multi-tenant** and **generic**:

- Uses the default `postgres` admin user
- Each service gets its own database and user via init scripts
- Easy to add new services by adding init scripts
- Centralized database management

## Current Databases

| Database | User | Service | Description |
|----------|------|---------|-------------|
| `synapse` | `synapse` | Matrix Synapse | Matrix homeserver database |

## Configuration

### Database Details

- **Admin Database**: `postgres`
- **Admin Username**: `postgres`
- **Encoding**: UTF8 with C locale
- **Max Connections**: 200
- **Port**: 5432

### Service Databases

Service databases are created automatically via init scripts in `values.yaml`. Each service gets:
- Its own database
- Its own user with ownership of that database
- Password stored in the `postgresql-credentials` secret

### Resources

- **CPU**: 250m (request) / 1000m (limit)
- **Memory**: 512Mi (request) / 2Gi (limit)

### Performance Tuning

The PostgreSQL instance is optimized for general workloads with:
- Increased `shared_buffers` (256MB)
- Tuned `work_mem` for concurrent connections
- WAL configuration for better write performance
- Extended logging for troubleshooting
- `pg_stat_statements` extension enabled

## Files

- `application.yaml` - ArgoCD Application definition
- `values.yaml` - Helm chart configuration
- `.secrets.yaml` - Template for credentials (DO NOT COMMIT)
- `postgresql-secrets-sealed.yaml` - Sealed secret for production

## Deployment

### 1. Generate Credentials

First, create secure passwords for each service:

```bash
# Generate passwords for postgres admin
openssl rand -base64 32  # postgres admin password

# Generate passwords for each service
openssl rand -base64 32  # synapse password
openssl rand -base64 32  # replication password

# For each new service, generate another password
openssl rand -base64 32  # nextcloud password (example)
```

### 2. Update Secrets Template

Edit `apps/postgresql/.secrets.yaml` with the generated passwords:

```yaml
stringData:
  postgres-password: <admin_password>
  password: <admin_password>  # Same as postgres-password
  replication-password: <replication_password>
  SYNAPSE_PASSWORD: <synapse_password>
  # Add more service passwords as needed:
  # NEXTCLOUD_PASSWORD: <nextcloud_password>
```

### 3. Seal the Secret

```bash
# Using taskfile
task generate-sealed-secrets

# Or manually
kubeseal --format=yaml < apps/postgresql/.secrets.yaml > apps/postgresql/postgresql-secrets-sealed.yaml
```

### 4. Deploy via ArgoCD

```bash
kubectl apply -f apps/postgresql/application.yaml
```

## Adding a New Service Database

To add a database for a new service (e.g., Nextcloud):

### 1. Add Password to Secrets

Edit `apps/postgresql/.secrets.yaml`:

```yaml
stringData:
  # ... existing entries ...
  NEXTCLOUD_PASSWORD: CHANGE_ME_GENERATE_SECURE_PASSWORD
```

### 2. Add Init Script

Edit `apps/postgresql/values.yaml` and add a new init script:

```yaml
primary:
  initdbScripts:
    01-create-synapse.sh: |
      # ... existing synapse script ...
    
    02-create-nextcloud.sh: |
      #!/bin/bash
      set -e
      
      echo "Creating nextcloud database and user..."
      
      NEXTCLOUD_PASSWORD="${NEXTCLOUD_PASSWORD}"
      
      if [ -z "$NEXTCLOUD_PASSWORD" ]; then
        echo "Warning: NEXTCLOUD_PASSWORD not set"
        exit 1
      fi
      
      psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        -- Create nextcloud user
        DO \$\$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'nextcloud') THEN
            CREATE ROLE nextcloud WITH LOGIN PASSWORD '$NEXTCLOUD_PASSWORD';
            RAISE NOTICE 'Created nextcloud user';
          END IF;
        END
        \$\$;
        
        -- Create nextcloud database
        SELECT 'CREATE DATABASE nextcloud OWNER nextcloud ENCODING UTF8'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nextcloud')\gexec
        
        -- Grant privileges
        GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
      EOSQL
      
      echo "Nextcloud database and user setup completed"
```

### 3. Reseal and Deploy

```bash
task generate-sealed-secrets
git add apps/postgresql/
git commit -m "Add nextcloud database to PostgreSQL"
git push
```

The init scripts are **idempotent** - they check if users/databases exist before creating them, so they're safe to run multiple times.

## Access

### Service Endpoints

Each service database is accessible at:

```
postgresql-postgresql.postgresql.svc.cluster.local:5432
```

**For Matrix Synapse:**
- Database: `synapse`
- User: `synapse`
- Password: From `postgresql-credentials` secret, key `SYNAPSE_PASSWORD`

**For admin access:**
- Database: `postgres`
- User: `postgres`
- Password: From `postgresql-credentials` secret, key `postgres-password`

### Connect from Another Pod

```bash
# Connect to a specific service database (e.g., synapse)
psql postgresql://synapse:PASSWORD@postgresql-postgresql.postgresql.svc.cluster.local:5432/synapse

# Or with kubectl exec to the postgres pod
kubectl -n postgresql exec -it postgresql-postgresql-0 -- psql -U synapse -d synapse

# Connect as admin
kubectl -n postgresql exec -it postgresql-postgresql-0 -- psql -U postgres -d postgres
```

### Get Passwords

```bash
# Get admin (postgres) password
kubectl -n postgresql get secret postgresql-credentials -o jsonpath='{.data.postgres-password}' | base64 -d

# Get synapse password
kubectl -n postgresql get secret postgresql-credentials -o jsonpath='{.data.SYNAPSE_PASSWORD}' | base64 -d
```

## Database Maintenance

### Backup Database

```bash
# Get the password
PGPASSWORD=$(kubectl -n postgresql get secret postgresql-credentials -o jsonpath='{.data.password}' | base64 -d)

# Create backup
kubectl -n postgresql exec -it postgresql-postgresql-0 -- \
  env PGPASSWORD=$PGPASSWORD pg_dump -U synapse synapse > backup-$(date +%Y%m%d-%H%M%S).sql
```

### Restore Database

```bash
# Restore from backup
cat backup.sql | kubectl -n postgresql exec -i postgresql-postgresql-0 -- \
  psql -U synapse synapse
```

### Check Database Size

```bash
kubectl -n postgresql exec -it postgresql-postgresql-0 -- \
  psql -U synapse -d synapse -c "SELECT pg_size_pretty(pg_database_size('synapse'));"
```

### Vacuum and Analyze

```bash
kubectl -n postgresql exec -it postgresql-postgresql-0 -- \
  psql -U synapse -d synapse -c "VACUUM ANALYZE;"
```

## Monitoring

### Check Pod Status

```bash
kubectl -n postgresql get pods
kubectl -n postgresql logs -f postgresql-postgresql-0
```

### Check PVC Status

```bash
kubectl -n postgresql get pvc
```

### Database Connections

```bash
kubectl -n postgresql exec -it postgresql-postgresql-0 -- \
  psql -U synapse -d synapse -c "SELECT count(*) FROM pg_stat_activity;"
```

### Check Performance Stats

```bash
kubectl -n postgresql exec -it postgresql-postgresql-0 -- \
  psql -U synapse -d synapse -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```

## Troubleshooting

### Pod Won't Start

Check logs and events:
```bash
kubectl -n postgresql describe pod postgresql-postgresql-0
kubectl -n postgresql logs postgresql-postgresql-0
```

### Connection Issues

Verify service and network:
```bash
kubectl -n postgresql get svc
kubectl -n postgresql exec -it postgresql-postgresql-0 -- pg_isready -U synapse
```

### Permission Issues

Check volume permissions:
```bash
kubectl -n postgresql exec -it postgresql-postgresql-0 -- ls -la /bitnami/postgresql
```

### Reset Database (WARNING: Data Loss)

```bash
# Delete the PVC (will destroy all data)
kubectl -n postgresql delete pvc data-postgresql-postgresql-0

# Restart the pod
kubectl -n postgresql delete pod postgresql-postgresql-0
```

## Consumers

This PostgreSQL instance currently hosts databases for:
- **Matrix Synapse** (`matrix` namespace) - `synapse` database

To connect a new service:
1. Add an init script (see "Adding a New Service Database" above)
2. Create an ExternalSecret in the service namespace to access the password
3. Configure the service to connect to `postgresql-postgresql.postgresql.svc.cluster.local:5432`

## Security

- Runs as non-root user (UID 1001)
- Capabilities dropped
- Secrets managed via SealedSecrets
- Network isolation via Kubernetes namespaces
- TLS/SSL can be enabled in values.yaml if needed

## Scaling

This deployment runs in standalone mode. For high availability:

1. Update `architecture` to `replication` in values.yaml
2. Configure read replicas count
3. Update resource requests/limits accordingly

See [Bitnami PostgreSQL Chart documentation](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) for more details.
