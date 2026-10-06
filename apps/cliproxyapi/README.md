# CLIProxyAPI and Oh My CPA

This alternative to 9router runs CLIProxyAPI `v8.0.16` and Oh My CPA `v0.1.2`.
9router remains available at its existing `aiproxy.*` addresses.

| Endpoint | OISD domain | Tailscale domain |
| --- | --- | --- |
| Dashboard | https://ai.oisd.dev/omc/ | https://ai.ison-mirfak.ts.net/omc/ |
| OpenAI-compatible base URL | https://ai.oisd.dev/v1 | https://ai.ison-mirfak.ts.net/v1 |
| Gateway health | https://ai.oisd.dev/healthz | https://ai.ison-mirfak.ts.net/healthz |

The hostname root returns CLIProxyAPI's endpoint discovery document. Both ingresses
preserve `/omc` when routing to the dashboard. The OISD domain uses the existing
wildcard DNS and Traefik TLS certificate; the Tailscale operator provisions `ai`
and its HTTPS certificate. Access follows the existing tailnet policy. The OISD
wildcard currently points to a tailnet address, so it also requires tailnet access.

## First sign-in

The dashboard password is the management key in the namespace-bound SealedSecret.
Retrieve it locally without saving it to Git:

```sh
rtk proxy kubie exec OISD cliproxyapi kubectl get secret cliproxyapi-credentials -o jsonpath='{.data.management-key}' | base64 --decode
```

Sign in at either dashboard URL and add provider credentials or OAuth accounts.
No providers or credentials are copied from 9router. A separate initial client key
is seeded into CPA; retrieve it with:

```sh
rtk proxy kubie exec OISD cliproxyapi kubectl get secret cliproxyapi-credentials -o jsonpath='{.data.initial-api-key}' | base64 --decode
```

Use that client key as the Bearer token, or create and revoke keys through the
dashboard. The Secret retains the **initial** key even if it is later revoked.
`GET /v1/models` lists the configured models; model inference needs a provider.

## Storage and security

One pod contains the gateway and dashboard. Its 2 GiB Longhorn volume has separate
`cpa` and `omc` directories for mutable configuration, OAuth credentials, plugins,
and the dashboard's SQLite database. The init container creates CPA's configuration
only when absent. Dashboard changes survive restarts and GitOps reconciliation;
editing the starter ConfigMap does not overwrite existing settings.

The management API rejects remote connections (`management.allow-remote: false`).
Oh My CPA connects over loopback. Do not set CPA's `MANAGEMENT_PASSWORD` environment
variable: upstream treats it as an override enabling remote management. CPA hashes
the initial management key in its writable configuration on first startup.

Both processes run as UID/GID 10001 with read-only root filesystems, dropped
capabilities, and no Kubernetes API token. NetworkPolicy accepts ingress only from
Traefik and Tailscale, and allows outbound cluster DNS and TCP/443 for provider APIs,
OAuth, catalogs, and update checks. Providers on other ports need an explicit policy
change. Internal clients in other namespaces also need an explicit ingress rule.

The single replica and `Recreate` strategy protect SQLite's single-writer ownership
and the ReadWriteOnce volume. Oh My CPA is the only usage collector. Resource
requests and limits are initial allocations for a new instance; adjust them against
observed usage as traffic grows. Startup probes use the existing 9router allowance
of 24 attempts at five-second intervals. Request records use OMC's default 90-day
retention; monitor volume space as usage grows.

Back up the volume **and** `cliproxyapi-credentials` securely. The `master-key`
encrypts dashboard data and must be retained for restores. Do not replace it when
upgrading, or regenerate the SealedSecret for an existing volume. Changes to the
management key must also update CPA's persisted configuration and OMC's Secret.

## Deployment

The root Argo CD application discovers `application.yaml` after these files are
published to Git. The application uses the local Kustomization and automatic sync.
For an initial deployment before publishing:

```sh
rtk proxy kubie exec OISD cliproxyapi kubectl apply -k apps/cliproxyapi
rtk proxy kubie exec OISD cliproxyapi kubectl rollout status deployment/cliproxyapi --timeout=60s
```

Do not apply `application.yaml` before its source path is available in the remote
repository. Once published, Argo CD adopts the same resources.

Useful checks:

```sh
rtk proxy kubie exec OISD cliproxyapi kubectl apply --dry-run=server -k apps/cliproxyapi
rtk proxy kubie exec OISD cliproxyapi kubectl get pods,pvc,externalsecret,ingress
rtk proxy curl --fail --silent --show-error https://ai.oisd.dev/omc/api/healthz
rtk proxy curl --fail --silent --show-error https://ai.ison-mirfak.ts.net/omc/api/healthz
```

Check that OMC reports `status: ok`, not `degraded`: a degraded gateway connection
can still produce HTTP 200 from its health endpoint.
