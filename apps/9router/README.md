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
`https://search.oisd.dev/search`. This hostname resolves to the Tailscale ingress
address inside the cluster. The 9router NetworkPolicy allows outbound TCP/443.
SearXNG's endpoint is `/search`; `/v1/search` is the 9router API endpoint.

9router 0.5.95 currently rejects administrator-configured private search endpoints
at runtime because of [upstream issue #3756](https://github.com/decolua/9router/issues/3756).
The HTTPS endpoint returns JSON successfully when called directly, but its
Tailscale address may still be rejected by 9router's private-address guard until the fix in
[upstream PR #3793](https://github.com/decolua/9router/pull/3793) ships in a
9router release.

To move the Seneca configuration, open its 9router dashboard and use **Profile →
Database → Download Backup**. On the new instance, use **Profile → Database →
Import Backup** and select that JSON file. The import replaces the new instance's
database, including its dashboard password and API keys. Sign in afterward with
the Seneca dashboard password. Keep the backup private because it contains provider
credentials and API keys.
