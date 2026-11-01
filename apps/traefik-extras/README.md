# Traefik Extras

This application contains additional Traefik resources that are not part of the Helm chart:

- `dashboard-ingress.yaml` - Ingress for Traefik dashboard at proxy.oisd.dev
- `garage-webui-endpoint.yml` - IngressRoute for S3 service at s3.oisd.dev
- `middlewares.yaml` - Custom middlewares for security and rate limiting
- `traefik-secrets-sealed.yaml` - Sealed secrets for authentication

These are deployed as a separate application to avoid conflicts with the multi-source Helm deployment.

`external-endpoints/wirebos-s3.yaml` routes only `/wirebos-core` and its child
paths on `https://s3.oisd.dev` to Garage's S3 API on port 3900. WireBOS uses
path-style signing, bucket `wirebos-core`, and region `garage`. The existing
Garage web UI remains on port 3909 for every other path. Bucket credentials
must stay in private operational configuration, never in these manifests.

## Cluster DNS

CoreDNS forwards external queries directly to AdGuard at `192.168.2.1`, avoiding
intermittent `SERVFAIL` responses from the node's Tailscale resolver. The
`ison-mirfak.ts.net` zone still uses `100.100.100.100` through
`coredns-custom.yaml`. No public DNS resolver is configured in CoreDNS.

Apply `coredns.yaml` directly with Kubie if DNS failure prevents ArgoCD from
resolving GitHub. CoreDNS reloads the mounted ConfigMap automatically; check
resolution through both replicas after applying. Commit and push the same change
when authorized so ArgoCD's desired configuration matches the live fix.
