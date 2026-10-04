# 9router

The single 9router replica stores its database on a Longhorn volume. It is served at
`https://aiproxy.oisd.dev` through Traefik and at
`https://aiproxy.ison-mirfak.ts.net` through Tailscale ingress. The image is pinned
to `decolua/9router:0.5.95`.

The initial dashboard password is generated during manifest creation and stored in
the `9router-initial-password` SealedSecret. Retrieve it from the live Secret:

```nu
kubie exec OISD 9router kubectl get secret 9router-initial-password -o jsonpath='{.data.password}' | decode base64 | decode utf-8
```

## Web search

`SEARXNG_URL` points 9router's built-in SearXNG provider at
`http://searxng.searxng.svc.cluster.local:8080/search`. The 9router NetworkPolicy
allows TCP/8080 only to the SearXNG application pods in the `searxng` namespace.

9router 0.5.95 currently rejects administrator-configured private search endpoints
at runtime because of [upstream issue #3756](https://github.com/decolua/9router/issues/3756).
The manifest configuration is ready, but `/v1/search` will return
`502 Blocked URL: internal host` until the fix in
[upstream PR #3793](https://github.com/decolua/9router/pull/3793) ships in a
9router release.

To move the Seneca configuration, open its 9router dashboard and use **Profile →
Database → Download Backup**. On the new instance, use **Profile → Database →
Import Backup** and select that JSON file. The import replaces the new instance's
database, including its dashboard password and API keys. Sign in afterward with
the Seneca dashboard password. Keep the backup private because it contains provider
credentials and API keys.
