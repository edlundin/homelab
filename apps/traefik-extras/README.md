# Traefik Extras

This application contains additional Traefik resources that are not part of the Helm chart:

- `dashboard-ingress.yaml` - Ingress for Traefik dashboard at proxy.oisd.dev
- `garage-webui-endpoint.yml` - IngressRoute for S3 service at s3.oisd.dev
- `middlewares.yaml` - Custom middlewares for security and rate limiting
- `traefik-secrets-sealed.yaml` - Sealed secrets for authentication

These are deployed as a separate application to avoid conflicts with the multi-source Helm deployment.

## Cluster DNS

CoreDNS forwards external queries through its `/etc/resolv.conf`. With
`dnsPolicy: Default`, K3s supplies that file from the node's configured
`resolv-conf: /etc/rancher/k3s/resolv.conf`. Both Sarasate and Spinoza use:

```conf
nameserver 100.100.100.100
options timeout:2 attempts:2
```

This uses the node's Tailscale DNS resolver instead of contacting upstream DNS
servers at their public addresses. Tailscale must be running on both nodes.
Terraform maintains Spinoza's initial resolver file; Sarasate is managed outside
Terraform. After changing an existing node's file, recreate its CoreDNS pod so
the container receives the updated resolver configuration.
