# PostgreSQL Deployment (Helm + ArgoCD)

This directory contains the PostgreSQL deployment configuration using the Bitnami PostgreSQL Helm chart, managed by ArgoCD.

## Overview

- **Chart**: Bitnami PostgreSQL
- **Architecture**: Standalone (single primary instance)
- **Namespace**: `postgres`
- **Default Database**: `postgres` (with `postgres` user)
- **Additional Databases**: `n8n` (with dedicated `n8n` user)

## How it works

- **Deployment**: Managed by the Bitnami PostgreSQL Helm chart (see `application.yaml`)
- **Configuration**: All custom settings are in `values.yaml`
- **Secrets**: Passwords stored in `.secrets.yaml` (seal with kubeseal before committing)
- **Init Scripts**: Automatically creates n8n database and user on first deployment
- **ArgoCD**: The `application.yaml` defines a multi-source ArgoCD Application

## Files

- `application.yaml` — ArgoCD Application definition for PostgreSQL
- `values.yaml` — Custom Helm values (persistence, databases, users, init scripts)
- `.secrets.yaml` — Unencrypted secrets (DO NOT COMMIT - seal first!)
- `postgres-secrets-sealed.yaml` — Encrypted secrets (safe to commit)
- `README.md` — This file

## Databases and Users

### Default Database
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: Stored in `postgres-password` secret (key: `postgres-password`)

### n8n Database
- **Database**: `n8n`
- **User**: `n8n`
- **Password**: Stored in `postgres-n8n-credentials` secret (key: `password`)
- **Auto-created**: Yes (via init script in `values.yaml`)

## Setup Instructions

### 1. Generate Passwords

Generate secure passwords for PostgreSQL users:

```bash
# Generate postgres admin password
openssl rand -hex 32

# Generate replication password
openssl rand -hex 32

# Generate n8n user password
openssl rand -hex 32
```

### 2. Update .secrets.yaml

Edit `apps/postgres/.secrets.yaml` and replace all `PLACEHOLDER_*` values with actual passwords:

```yaml
stringData:
  postgres-password: "your-generated-postgres-password"
  replication-password: "your-generated-replication-password"
---
stringData:
  password: "your-generated-n8n-password"
  database: "n8n"
  username: "n8n"
```

### 3. Seal Secrets

```bash
# Seal the secrets using the taskfile
task generate-sealed-secrets

# Or manually:
kubeseal --format=yaml < apps/postgres/.secrets.yaml > apps/postgres/postgres-secrets-sealed.yaml
```

### 4. Deploy

```bash
# Apply the ArgoCD application
kubectl apply -f apps/postgres/application.yaml

# Or use the root application to deploy all apps
kubectl apply -f apps/argocd/application.yaml
```

### 5. Verify Deployment

```bash
# Check PostgreSQL pod
kubectl get pods -n postgres

# Check logs
kubectl logs -n postgres -l app.kubernetes.io/name=postgresql

# Verify databases
kubectl exec -it -n postgres $(kubectl get pod -n postgres -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -c '\l'

# Verify n8n user can connect
kubectl exec -it -n postgres $(kubectl get pod -n postgres -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U n8n -d n8n -c '\dt'
```

## Connection Information

### From within the cluster

#### Default postgres user
- **Host**: `postgres-postgresql.postgres.svc.cluster.local`
- **Port**: `5432`
- **Database**: `postgres`
- **Username**: `postgres`
- **Password**: From secret `postgres-password` (key: `postgres-password`)

#### n8n user
- **Host**: `postgres-postgresql.postgres.svc.cluster.local`
- **Port**: `5432`
- **Database**: `n8n`
- **Username**: `n8n`
- **Password**: From secret `postgres-n8n-credentials` (key: `password`)

### Connection String Examples

```bash
# postgres user
postgresql://postgres:${PASSWORD}@postgres-postgresql.postgres.svc.cluster.local:5432/postgres

# n8n user
postgresql://n8n:${PASSWORD}@postgres-postgresql.postgres.svc.cluster.local:5432/n8n
```

## Storage

- **Persistence**: Enabled
- **Size**: 10Gi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: Default (uses cluster default)

## Resources

### PostgreSQL Primary
- **Requests**: 250m CPU, 256Mi memory
- **Limits**: 1000m CPU, 1024Mi memory

### Metrics Exporter
- **Requests**: 50m CPU, 64Mi memory
- **Limits**: 100m CPU, 128Mi memory

## Monitoring

Metrics are enabled and exported via the PostgreSQL exporter. These can be scraped by Prometheus for monitoring.

## Backup and Recovery

For production use, consider:
1. Setting up automated backups (pg_dump or Longhorn snapshots)
2. Configuring PostgreSQL archive mode for PITR (Point-In-Time Recovery)
3. Using Longhorn backup to S3 for volume snapshots

## Security Notes

- Passwords are managed via Sealed Secrets
- Never commit `.secrets.yaml` with real passwords
- Always seal secrets before pushing to Git
- Use strong, randomly generated passwords
- Consider enabling TLS for connections in production

## Troubleshooting

### Check PostgreSQL logs
```bash
kubectl logs -n postgres -l app.kubernetes.io/name=postgresql --tail=100
```

### Connect to PostgreSQL shell
```bash
kubectl exec -it -n postgres $(kubectl get pod -n postgres -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres
```

### Check init script execution
```bash
kubectl logs -n postgres -l app.kubernetes.io/name=postgresql | grep "n8n database"
```

### Reset database (DANGER: Deletes all data!)
```bash
kubectl delete pvc -n postgres data-postgres-postgresql-0
kubectl delete pod -n postgres -l app.kubernetes.io/name=postgresql
```

## Updates

To update PostgreSQL:
1. Update `targetRevision` in `application.yaml`
2. Commit and push changes
3. ArgoCD will automatically sync the update
4. **Note**: Major version upgrades may require manual intervention

## Adding New Databases/Users

Edit `values.yaml` and add to the `initdb.scripts` section:

```yaml
initdb:
  scripts:
    init-myapp.sh: |
      #!/bin/bash
      psql -U postgres <<-EOSQL
        CREATE USER myapp WITH PASSWORD 'secure-password';
        CREATE DATABASE myapp OWNER myapp;
        GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp;
      EOSQL
```

Then create corresponding secrets and seal them.
