# Plane

[Plane](https://github.com/makeplane/plane) Community Edition v1.5.1 runs from the
upstream Helm chart (`plane-ce` 1.9.2 from `https://helm.plane.so/`) through
Kustomize: api, worker, beat-worker, web, space, admin and live, one replica each,
with the chart's Valkey, RabbitMQ and MinIO.

- https://ticket.oisd.dev — Traefik with the existing wildcard certificate.
- https://ticket.oisd.dev/god-mode — instance administration.

## First login

Open https://ticket.oisd.dev/god-mode right after the first deployment and create
the instance admin before anyone else can reach it. Then configure sign-up,
SMTP and telemetry there.

## Routing

The chart's IngressRoute is disabled (`ingress.enabled: false`); `ingress.yaml`
reproduces its routes on `websecure` with the shared `default-chain` middleware
and a 20 MiB body limit: `/spaces` → space, `/god-mode` → admin,
`/api`, `/auth` and `/static/` → api, `/live` → live (websocket), object keys under
`/uploads/` and presigned POSTs to the bucket root → MinIO, everything else → web.
The chart makes the bucket public-read with MinIO's `download` policy, which also
allows anonymous listing; keeping other bucket-root requests away from MinIO
prevents enumerating upload keys. `ingress.appHost` and `ssl.externalTermination` still make
the chart set `WEB_URL=https://ticket.oisd.dev` and the CORS origins.

## Dependencies and data

- The shared PostgreSQL 18 service hosts a dedicated `plane` database and login.
  An idempotent bootstrap Job in `postgres` creates them before app sync. Plane
  documents PostgreSQL 15.7+/16.x; 18 runs through Django 5.2 but is not
  validated upstream. Take a `pg_dump` of `plane` before Plane upgrades.
- Valkey (cache, live-server pub/sub) and RabbitMQ (Celery broker) run in the
  namespace on 1Gi Longhorn PVCs. Uploads live in MinIO's public-read `uploads`
  bucket on a 10Gi Longhorn PVC (`pvc-plane-minio-vol-plane-minio-wl-0`). None
  is enrolled in a Longhorn recurring backup group.
- All Secrets are SealedSecrets; the chart renders none (`external_secrets.*`):
  - `plane`: `DATABASE_URL`, `REDIS_URL`, `AMQP_URL`, `SECRET_KEY`,
    `LIVE_SERVER_SECRET_KEY`. `SECRET_KEY` encrypts instance settings such as the
    SMTP password and OAuth secrets: never regenerate it.
  - `plane-doc-store`: MinIO credentials, bucket, endpoint and `FILE_SIZE_LIMIT`
    (keep it equal to the `body-limit` Middleware).
  - `plane-rabbitmq`: RabbitMQ credentials, matching `AMQP_URL`.
  - `postgres-plane-credentials` (namespace `postgres`): must match the password
    in `DATABASE_URL`; reseal both together.
- NetworkPolicies allow ingress from Traefik to the routed ports (3000, 8000,
  9000), traffic between the release's pods, and egress to DNS, PostgreSQL and
  public HTTP(S)/SMTP, excluding private networks.
- The upstream images run as root and the chart exposes no securityContext;
  `kustomization.yaml` adds the RuntimeDefault seccomp profile, disallows
  privilege escalation and disables service-account token mounting.

## Rendering

```sh
kustomize build apps/plane --enable-helm > /tmp/plane-rendered.yaml
```

Argo CD needs `kustomize.buildOptions: --enable-helm`
(`apps/argocd-extras/kustomize-helm.yaml`). To upgrade, bump the chart `version`
in `kustomization.yaml` and `planeVersion` in `values.yaml`. The migration and
bucket Jobs keep the name suffix `-1` under `helm template`, so they carry
`Force=true,Replace=true` and are recreated when their image changes.
