# Longhorn Extras

This application contains additional Longhorn resources that are not part of the Helm chart:

- `middlewares.yaml` - Basic auth middleware for Longhorn UI
- `longhorn-backup-secrets-sealed.yaml` - Sealed secrets for S3 backup credentials
- `weekly-backup-recurringjob.yaml` - Sunday 03:00 backup for volumes in the
  `default` group, retaining two backups per volume
- `actual-budget-daily-backup-recurringjob.yaml` - Daily 02:00 backup for the
  Actual Budget volume, retaining three backups

These are deployed as a separate application to avoid conflicts with the multi-source Helm deployment.
