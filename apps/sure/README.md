# Sure

Sure 0.7.6 runs from the [official Helm chart](https://docs.sure.am/self-hosting-helm),
with one Rails web pod and one Sidekiq worker.

- https://sure.oisd.dev — Traefik with the existing wildcard certificate.
- https://sure.ison-mirfak.ts.net — Tailscale HTTPS ingress.

## First login

Registration is **invite-only**, including the first account, which becomes the
super admin. Retrieve the initial single-use code locally (do not commit or share
it), then enter it on the signup page:

```sh
kubie exec OISD sure kubectl get secret sure-secrets \
  -o jsonpath='{.data.INITIAL_INVITE_CODE}' | base64 --decode
```

The web migration init container creates this invitation only while there are no
users; consuming it does not recreate it on subsequent starts. Generate further
invitations or close registration in Sure's self-hosting settings. SMTP, bank
credentials, and AI providers are not configured. Yahoo Finance is selected for
market data without requiring an API key.

`APP_DOMAIN` uses `sure.oisd.dev` for generated links. Passkeys are bound to that
hostname; use password login on the unrelated Tailscale hostname.

## Dependencies and data

- The existing PostgreSQL service hosts a dedicated `sure` database and login.
  An idempotent bootstrap Job in `postgres` creates these before app sync.
- The existing authenticated Redis master uses **DB 1**, reserved for Sure.
  This separates keys from DB 0, not access permissions or failure domains.
  Never flush the shared Redis instance.
- External Secrets copies only the required database credentials, Redis password,
  and wildcard TLS certificate using resource-scoped RBAC.
- Rails and Sidekiq share `/rails/storage` on a 2Gi Longhorn **RWX** PVC, so
  attachment processing works across nodes. RWX requires the nodes' NFS support.
  The PVC joins Longhorn's `default` recurring backup group. Database and Redis
  persistence remain with their existing deployments; volume snapshots alone
  are not a tested, transaction-consistent Sure restore procedure.
- Sealed Secrets stores the app's stable encryption keys, initial invitation,
  and PostgreSQL credentials. Preserve these keys along with the database and
  attachments. Rotating or losing encryption keys can make financial data
  unreadable; do not regenerate the sealed files during routine upgrades.
- NetworkPolicies permit ingress from Traefik/Tailscale and egress to DNS,
  PostgreSQL, Redis, and public HTTPS APIs, excluding private networks.

## Rendering and deployment

Kustomize fetches the pinned chart; its `charts/` cache is ignored. Small patches
add token-free service accounts and worker process probes because chart 0.7.6
has no values for those fields. Upstream web health probes use `/up`. Worker
probes check the process, not Redis health, to avoid restarting it during shared
service outages.

Argo CD needs `kustomize.buildOptions: --enable-helm`, declared in
`apps/argocd-extras/kustomize-helm.yaml`. Apply that prerequisite before syncing
this app. If adding other build flags later, preserve `--enable-helm`.

```sh
# Requires Helm 3.10+ and Kustomize with Helm support.
kustomize build apps/sure --enable-helm > /tmp/sure-rendered.yaml
kubie exec OISD sure kubectl apply --dry-run=server -f /tmp/sure-rendered.yaml

# After committing and pushing these files, enable GitOps:
kubie exec OISD argocd kubectl apply --server-side \
  --field-manager=argocd-controller -f apps/argocd-extras/kustomize-helm.yaml
kubie exec OISD argocd kubectl apply -f apps/sure/application.yaml
```

The root Argo CD application also discovers `application.yaml` automatically.
Database preparation runs in the web init container rather than the chart's
PostSync migration hook, avoiding an initial-install health deadlock. The worker
waits for pending migrations before starting its schedulers. Resource requests
start at the upstream defaults with 1 CPU / 1Gi limits per Rails container;
these are initial trial bounds, not measured sizing guidance.
