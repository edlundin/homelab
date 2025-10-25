# Matrix Synapse (matrix.oisd.io)

This deploys a Matrix Synapse server with external PostgreSQL for `matrix.oisd.io`.

## Components

- **Matrix Synapse**: Homeserver application
- **PostgreSQL**: External database instance (deployed in `postgresql` namespace)
- **Redis**: External Redis instance (deployed in `redis` namespace)
- **Ingress**: HTTPS ingress at `matrix.oisd.io`
- **Storage**: Longhorn persistent volume for Synapse data

## Files

- `application.yaml` - ArgoCD Application to deploy Matrix Synapse
- `ingress.yaml` - Traefik Ingress for `matrix.oisd.io`
- `external-secret-tls.yaml` - ExternalSecret for TLS certificate
- `external-secret-redis.yaml` - ExternalSecret for Redis connection
- `external-secret-postgresql.yaml` - ExternalSecret for PostgreSQL credentials
- `.secrets.yaml` - Template for Matrix signing key secret (gitignored)
- `matrix-secrets-sealed.yaml` - SealedSecret for Matrix signing key

## Database Configuration

Matrix Synapse uses an external PostgreSQL database deployed in the `postgresql` namespace:

- **Service**: `postgresql-postgresql.postgresql.svc.cluster.local:5432`
- **Database**: `synapse`
- **User**: `synapse`
- **Credentials**: Synced from `postgresql` namespace via ExternalSecrets

See the [PostgreSQL app documentation](../postgresql/README.md) for database management.

## TLS Configuration

TLS is provided by the wildcard secret `wildcard-tls-oisd` copied into the `matrix` namespace via ExternalSecrets.

## How to apply (via ArgoCD)

**Prerequisites**: 
1. Deploy PostgreSQL first: `kubectl apply -f apps/postgresql/application.yaml`
2. Ensure PostgreSQL is healthy before deploying Matrix

Then deploy Matrix:
```bash
kubectl apply -f apps/matrix/application.yaml
```

After the ArgoCD Application syncs, visit: https://matrix.oisd.io

## Post-Install Steps

1. Wait for all pods to be ready:
   ```bash
   kubectl -n matrix get pods
   kubectl -n postgresql get pods
   ```

2. Get the registration shared secret:
   ```bash
   kubectl -n matrix get secret matrix-synapse -o jsonpath='{.data.registrationSharedSecret}' | base64 -d
   ```

3. Create an admin user:
   ```bash
   kubectl -n matrix exec -it deploy/matrix-synapse -- register_new_matrix_user \
     -c /synapse/config/homeserver.yaml \
     -u ADMIN_USERNAME \
     -p ADMIN_PASSWORD \
     -a
   ```

4. Verify the server is running:
   ```bash
   curl https://matrix.oisd.io/_matrix/client/versions
   ```

## Troubleshooting

### Check Synapse logs
```bash
kubectl -n matrix logs -f deploy/matrix-synapse
```

### Verify PostgreSQL connectivity
```bash
kubectl -n matrix exec -it deploy/matrix-synapse -- nc -zv postgresql-postgresql.postgresql.svc.cluster.local 5432
```

### Check database connection
```bash
# Get the database password
DB_PASS=$(kubectl -n postgresql get secret postgresql-credentials -o jsonpath='{.data.password}' | base64 -d)

# Test connection from Matrix pod
kubectl -n matrix exec -it deploy/matrix-synapse -- \
  psql "postgresql://synapse:$DB_PASS@postgresql-postgresql.postgresql.svc.cluster.local:5432/synapse" \
  -c "SELECT version();"
```

### Check ExternalSecrets status
```bash
kubectl -n matrix get externalsecrets
kubectl -n matrix describe externalsecret postgresql-db-secret
```

## Migration from SQLite

If migrating from a previous SQLite deployment, follow the [Matrix Synapse database migration guide](https://github.com/matrix-org/synapse/blob/develop/docs/postgres.md):

1. Ensure PostgreSQL is deployed and accessible
2. Use the `synapse_port_db` script from within the Synapse container
3. Update the application.yaml to use external PostgreSQL
4. Restart Synapse