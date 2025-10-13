# Longhorn Extras

This application contains additional Longhorn resources that are not part of the Helm chart:

- `middlewares.yaml` - Basic auth middleware for Longhorn UI
- `longhorn-backup-secrets-sealed.yaml` - Sealed secrets for S3 backup credentials

These are deployed as a separate application to avoid conflicts with the multi-source Helm deployment.