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

To move the Seneca configuration, open its 9router dashboard and use **Profile →
Database → Download Backup**. On the new instance, use **Profile → Database →
Import Backup** and select that JSON file. The import replaces the new instance's
database, including its dashboard password and API keys. Sign in afterward with
the Seneca dashboard password. Keep the backup private because it contains provider
credentials and API keys.
