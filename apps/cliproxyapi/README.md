# CLIProxyAPI and Oh My CPA

CLIProxyAPI `v8.0.28` provides the inference gateway; [Oh My CPA](https://github.com/WizisCool/oh-my-cpa)
`0.2.9` provides its dashboard, configuration editor and usage collector.
The ArgoCD root application discovers `application.yaml` automatically.

## Access

- Dashboard: `https://ai.oisd.dev/omc/` and `https://ai.ison-mirfak.ts.net/omc/`
- On both AI hostnames and the `cpa.ison-mirfak.ts.net` dashboard alias, only
  `GET /` redirects to `/omc/`; other methods return 404.
- The existing `cpa.ison-mirfak.ts.net` dashboard alias remains available.
- OpenAI-compatible API bases: `https://ai.oisd.dev/v1` and
  `https://ai.ison-mirfak.ts.net/v1`
- Gemini-compatible routes: `/v1beta/…` on either AI hostname.
- Pi's CLIProxyAPI extension uses `/backend-api/codex/responses` on either AI
  hostname. Configure its base URL as `https://ai.oisd.dev` (or
  `https://ai.ison-mirfak.ts.net`) and authenticate with a client API key.

The Traefik hostnames need the same DNS routing as other `*.oisd.dev` applications.
The `ai` Tailscale ingress routes `/omc` to the dashboard and `/v1`, `/v1beta`
and `/backend-api/codex/responses` to inference. A small non-root nginx sidecar redirects only exact `GET /` requests to `/omc/`
and returns 404 for unmatched paths, never forwarding them to CPA.
Sign in with the management key, then configure providers and OAuth in Oh My CPA.
No upstream provider credentials are preconfigured.

Retrieve the initial credentials after synchronization (these commands display secrets;
run them privately and do not paste their output into logs or chat):

```bash
kubie exec OISD cliproxyapi kubectl get secret cliproxyapi-credentials -o jsonpath='{.data.management-key}' | base64 -d
kubie exec OISD cliproxyapi kubectl get secret cliproxyapi-credentials -o jsonpath='{.data.client-api-key}' | base64 -d
```

The second key is the initial inference client key. Manage client keys in the dashboard
after initialization; changing the bootstrap Secret does not rotate keys in an existing
configuration. Back up the management key and master key securely. The master key is
required to decrypt Oh My CPA's database; do not regenerate it on upgrades.

## Persistence and security

The gateway, dashboard and root-redirect containers share one pod and a 2 Gi Longhorn PVC, with one replica and `Recreate`
rollouts. Both run as UID/GID 10001 without a Kubernetes service-account token.
The PodDisruptionBudget preserves one healthy pod during voluntary evictions,
including descheduler balancing. With one replica, draining its node requires a
planned interruption and an explicit temporary adjustment of the budget. Unhealthy
pods may still be evicted. The budget does not prevent node failures or downtime
during the deployment's `Recreate` rollouts.
The PVC contains mutable `config.yaml`, OAuth credentials in `auths/`, logs, the plugin
directory (plugins are initially disabled), and Oh My CPA's SQLite data under `omc/`.
Back up the complete PVC together with the sealed credentials and the cluster's
Sealed Secrets recovery keys. No PVC deletion or migration of 9router is included.

The init container copies `config-map.yaml` and inserts a randomly generated client
key **only when no persisted configuration exists**. Subsequent changes belong in
the dashboard; modifying the bootstrap ConfigMap does not overwrite live configuration.

Oh My CPA reaches CPA over loopback. Upstream `MANAGEMENT_PASSWORD` enables remote
management regardless of `management.allow-remote`; that flag is not a security
boundary in this deployment. Traefik exposes the root redirect, dashboard and inference paths,
never CPA's `/v0/management` or `/v8/management`. NetworkPolicy limits
inbound traffic to Traefik and Tailscale proxies. Unmatched tailnet paths reach
only the redirect sidecar, which returns 404. Do not add a catch-all route to CPA
or expose port 8317 directly. Oh My CPA authenticates its dashboard with the
management key and uses secure cookies for its configured HTTPS public URL.

Only Oh My CPA should consume this CPA instance's destructive usage queue. Do not
attach a second usage collector. Container health probes check CPA's TCP listener and
Oh My CPA's `/omc/api/healthz`; they do not establish provider authentication or
successful inference. CPU/memory settings are initial scheduling budgets, not measured
capacity guarantees.

## Validation and deployment

```bash
kustomize build apps/cliproxyapi
kubie exec OISD cliproxyapi kubectl apply --dry-run=client -k apps/cliproxyapi
```

Commit and push through the normal authorized Git workflow to let ArgoCD deploy.
Then verify pod readiness, dashboard login, provider configuration and an authenticated
inference request on both AI hostnames. Image versions are pinned in
`kustomization.yaml`. ArgoCD Image Updater tracks stable CPA `8.x` and Oh My CPA
`0.x` releases with semver and writes updates back to this Kustomization. Major
version upgrades require an explicit compatibility review (Oh My CPA requires CPA v8+).
