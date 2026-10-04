# Atuin

Atuin is deployed as a single sync-server replica backed by the shared PostgreSQL
service. Argo CD Image Updater tracks stable Atuin 18.x releases using semantic
versioning and refreshes the digest behind the PostgreSQL `18-alpine` bootstrap
image. It is available at:

- `https://atuin.oisd.dev`
- `https://atuin.ison-mirfak.ts.net`

The database role and database are reconciled by `atuin-database-bootstrap`. The
credential is stored in the `postgres-atuin-credentials` SealedSecret in the
`postgres` namespace and copied into an Atuin connection URI by External Secrets.

## Client setup

Set the server in `~/.config/atuin/config.toml`:

```toml
sync_address = "https://atuin.oisd.dev"
```

Register the first account and save its end-to-end encryption key:

```shell
atuin account register -u <username> -e <email>
atuin key
atuin sync
```

On another machine, configure the same `sync_address` and run `atuin account
login -u <username>`; Atuin prompts for the password and encryption key so they
do not enter shell history. Registration is initially enabled so the intended
accounts can be created. After they exist, set `ATUIN_OPEN_REGISTRATION` to
`"false"` in `deployment.yaml`.

## Atuin AI

The [`atuin-ai-server`](https://github.com/atuinsh/atuin-ai-server) gateway is
available at:

- `https://atuin-ai.oisd.dev`
- `https://atuin-ai.ison-mirfak.ts.net`

It translates Atuin's OSS AI protocol to the OpenAI-compatible 9router service
inside the cluster. The `luna` alias selects the upstream model
`cx/gpt-6-luna`; the model must continue to support tool calling.

Two credentials are intentionally kept separate:

- `CHAT_API_KEY` authenticates the gateway to 9router and remains server-side.
- `AUTH_TOKEN` authenticates Atuin clients to the gateway and belongs in each
  client's local configuration.

Configure a client with the `AUTH_TOKEN` from the `atuin-ai-secrets` Secret:

```toml
[ai]
enabled = true
endpoint = "https://atuin-ai.ison-mirfak.ts.net"
endpoint_protocol = "oss"
api_token = "<AUTH_TOKEN>"
model = "luna"
```

A ChatGPT subscription is not an OpenAI API credential and cannot be used as
the upstream for this gateway. Use an OpenAI-compatible endpoint and API key,
such as the configured 9router service.
