# Matrix Synapse Deployment# Matrix Synapse (matrix.oisd.io)



This directory contains the Kubernetes manifests for running Matrix Synapse in the homelab cluster.This deploys a Matrix Synapse server (default: sqlite) for `matrix.oisd.io`.



## ComponentsFiles created:

- `application.yaml` - ArgoCD Application to deploy everything in this folder

- **ArgoCD Application**: Uses the official Matrix Synapse Helm chart- `deployment.yaml` - Deployment + PVC + Service for Synapse

- **Ingress**: Exposed at `matrix.oisd.io` with TLS- `ingress.yaml` - Traefik Ingress for `matrix.oisd.io`

- **Storage**: Uses Longhorn for persistent storage (both main storage and signing keys)- `external-secret.yaml` - ExternalSecret + Role/RoleBinding to copy wildcard TLS secret from `traefik` namespace into `matrix`

- **Database**: Initially configured with SQLite (can be migrated to PostgreSQL later if needed)

Notes:

## TLS Configuration- Synapse uses sqlite stored under `/data` (PVC `synapse-data`) for now.

- TLS is provided by the wildcard secret `wildcard-tls-oisd` copied into the `matrix` namespace via ExternalSecrets.

TLS is provided by the wildcard secret `wildcard-tls-oisd` copied into the `matrix` namespace via ExternalSecrets.- If you want Postgres instead of sqlite, modify `deployment.yaml` and add a Postgres chart + credentials.



## Post-Install StepsHow to apply (via ArgoCD):



1. Get the registration shared secret:```bash

   ```bashkubectl apply -f apps/matrix/application.yaml

   kubectl -n matrix get secret matrix-synapse -o jsonpath='{.data.registrationSharedSecret}' | base64 -d```

   ```

After the ArgoCD Application syncs, visit:

2. Create an admin user:

   ```bashhttps://matrix.oisd.io

   kubectl -n matrix exec -it deploy/matrix-synapse -- register_new_matrix_user \

     -c /synapse/config/homeserver.yaml \
     -u ADMIN_USERNAME \
     -p ADMIN_PASSWORD \
     -a
   ```

3. Verify the server is running:
   ```bash
   curl https://matrix.oisd.io/_matrix/client/versions
   ```

## Migration to PostgreSQL (Optional)

To migrate from SQLite to PostgreSQL:

1. Add a PostgreSQL instance (or connection details to existing one)
2. Update the `database` section in the Helm values
3. Follow the Matrix Synapse database migration guide