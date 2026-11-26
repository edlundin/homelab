# It's a Plan

[It's a Plan](https://github.com/croffasia/itsaplan) 1.13.0 runs from the upstream
Helm chart (`oci://ghcr.io/croffasia/charts/itsaplan`) through Kustomize, with
one api, web and worker pod and the chart's RustFS object store.

- https://plan.oisd.dev — Traefik with the existing wildcard certificate.

## First login

The first account registered becomes the instance admin. Register right after the
first deployment, before anyone else can reach the sign-up page.

## Routing

`API_URL` is `https://plan.oisd.dev/api`, so the web app and api share one
hostname and certificate. `ingress.yaml` sends `/api/*` to the api with the
prefix stripped, the OAuth discovery documents under `/.well-known/` to the api
unchanged (MCP clients), and everything else to the web app. The chart's own
Ingress modes need a second hostname or Traefik entrypoint, so they are off.

## Dependencies and data

- The shared PostgreSQL 18 service hosts a dedicated `itsaplan` database and
  login. An idempotent bootstrap Job in `postgres` creates them before app sync.
  The api image ships the PostgreSQL 18 client, matching the server for the
  pre-migration `pg_dump` taken by the api's `migrate` init container. That dump
  lives in an emptyDir and is lost with the pod.
- Attachments are stored in RustFS on a 5Gi Longhorn PVC (`itsaplan-minio`).
  It is not enrolled in a Longhorn recurring backup group.
- `itsaplan-secrets-sealed.yaml` replaces the chart's plaintext Secret (deleted
  in `kustomization.yaml`). It holds `DATABASE_URL`, `BETTER_AUTH_SECRET`,
  `APP_ENCRYPTION_KEY` and the RustFS credentials. `APP_ENCRYPTION_KEY` encrypts
  stored provider API keys: do not regenerate it, or they become unreadable.
  The database password in `DATABASE_URL` must match
  `postgres-itsaplan-credentials-sealed.yaml`; reseal both together.
- The Telegram bot is disabled. Telemetry is disabled.
- NetworkPolicies allow ingress from Traefik to web/api, traffic between the
  app's own pods, and egress to DNS, PostgreSQL and public HTTP(S)/SMTP,
  excluding private networks.
- The upstream images run as root; containers drop all capabilities and
  disallow privilege escalation.

## Rendering

```sh
kustomize build apps/itsaplan --enable-helm > /tmp/itsaplan-rendered.yaml
```

Argo CD needs `kustomize.buildOptions: --enable-helm`
(`apps/argocd-extras/kustomize-helm.yaml`). To upgrade, bump the chart `version`
in `kustomization.yaml`; the chart's `appVersion` selects the image tag.
