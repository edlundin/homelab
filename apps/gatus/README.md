# Gatus

[Gatus](https://github.com/TwiN/gatus) provides a dark-mode service status page.
[gatus-sidecar](https://github.com/home-operations/gatus-sidecar) watches the
Kubernetes API and generates checks from opted-in resources, without restarts.
Pulse remains the infrastructure dashboard; its Service is the first opted-in check.

## Deployment and access

The root Argo CD application discovers `application.yaml`. Kustomize includes
only the workload resources, not the Application itself. Commit and push through
the normal GitOps workflow to deploy; local edits alone do not change the cluster.

- Namespace: `gatus`
- Traefik URL: `https://gatus.oisd.dev`
- Private URL: `https://gatus.ison-mirfak.ts.net` (after Tailscale provisions it)
- Internal URL: `http://gatus.gatus.svc.cluster.local:8080`
- Traefik uses the shared security-header/rate-limit middleware and wildcard TLS
  certificate copied from its namespace by External Secrets. DNS for
  `gatus.oisd.dev` must resolve to the Traefik ingress address.
- No application login: anyone who can reach the Traefik route can view the status
  page and monitored service names. Tailscale access is controlled by tailnet policy.
- SQLite history: `/data/gatus.db`, backed by an initial 1Gi Longhorn PVC.
- One replica with `Recreate` avoids concurrent SQLite writers and RWO conflicts.

Checks run **inside the cluster**, not from an external uptime vantage point.
The local Gatus check keeps the configuration valid before discovery completes
and when no resources opt in; it does not prove external accessibility.

## Opt in a service or route

Add these annotations to a Service, networking.k8s.io Ingress, or Traefik
IngressRoute in its Git manifest:

```yaml
metadata:
  annotations:
    gatus.home-operations.com/enabled: "true"
    gatus.home-operations.com/endpoint: |
      name: My application
      group: Applications
      interval: 1m
      conditions:
        - "[STATUS] == 200"
```

For an Ingress or IngressRoute, the sidecar derives the URL from the host,
TLS configuration, and path. Services default to a TCP/UDP check on their
first port; override `url` for an HTTP health check, as in `apps/pulse/service.yaml`:

```yaml
gatus.home-operations.com/endpoint: |
  name: My application
  group: Applications
  url: http://my-app.my-namespace.svc.cluster.local:8080/health
  conditions:
    - "[STATUS] == 200"
```

The network policy permits DNS, the OISD API, HTTP(S), and Pulse's internal
port. **Add a scoped egress rule for other ports**, and allow Gatus in the
target workload's ingress policy if that workload is isolated. Protected routes
need a reachable health endpoint and appropriate success conditions; do not
disable TLS validation to mask connectivity problems.

Per-kind prefixes prevent collisions when a Service and route share a name.
Do not opt in multiple resources for the same check unless separate internal
and ingress checks are intentional. Remove the annotation or set it to
`"false"` to remove a check. HTTPRoute discovery is not enabled.

## Automatic image updates

Argo CD Image Updater manages both images through the `homelab-services`
ImageUpdater resource. It selects stable semver releases within Gatus 5.x and
sidecar 0.x, writes the image pins to `apps/gatus/kustomization.yaml` on `master`,
and Argo CD automatically syncs those commits. Prereleases are excluded; major
version changes require updating the constraints deliberately.

## Configuration and security

Base config is mounted under `/etc/gatus/base`; the sidecar writes
`/config/gatus-sidecar.yaml` atomically into a shared emptyDir mounted read-only
at `/etc/gatus/generated` in Gatus. Gatus recursively merges YAML from
`GATUS_CONFIG_PATH=/etc/gatus` and hot-reloads changes. Sibling mounts avoid
creating nested mountpoints inside a read-only volume and exclude the image's
example configuration.

The sidecar has only get/list/watch access to Services, Ingresses,
IngressClasses, and IngressRoutes. Only it receives a projected API token;
Gatus receives neither the token nor Secret access. Both containers run
non-root with read-only root filesystems and resource limits. Resource requests
are initial allocations, not measured sizing; adjust using observed usage.

Gatus has startup, readiness, and liveness HTTP probes. Sidecar 0.6.0 exposes
no health endpoint or probe command and contains no shell, so it has no probes;
Kubernetes restarts it on process exit. A stalled discovery watch is not detected
by Gatus's health endpoint. Review sidecar logs when configuration stops updating.

Only trusted manifest authors should be allowed to set discovery annotations:
they control probe destinations and endpoint configuration.

## Checks after GitOps deployment

```bash
kubie exec OISD gatus kubectl rollout status deployment/gatus
kubie exec OISD gatus kubectl logs deployment/gatus -c gatus-sidecar
kubie exec OISD gatus kubectl logs deployment/gatus -c gatus
kubie exec OISD gatus kubectl get ingress gatus
```

Confirm that the page lists Gatus and Pulse, and that annotation updates change
the generated checks without a rollout. Deployment readiness alone does not
establish that discovery or target health checks work.
