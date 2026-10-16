# Traefik Extras

This application contains additional Traefik resources that are not part of the Helm chart:

- `dashboard-ingress.yaml` - Ingress for Traefik dashboard at proxy.oisd.dev
- `garage-webui-endpoint.yml` - IngressRoute for S3 service at s3.oisd.dev
- `middlewares.yaml` - Custom middlewares for security and rate limiting
- `traefik-secrets-sealed.yaml` - Sealed secrets for authentication

These are deployed as a separate application to avoid conflicts with the multi-source Helm deployment.