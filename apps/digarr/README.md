# Digarr

Digarr is installed from the upstream v1.15.1 Helm chart with embedded
PGlite. The chart creates one Recreate Deployment, a Longhorn data PVC, a
Longhorn backup PVC, a dedicated tokenless ServiceAccount, probes, and a
default-deny NetworkPolicy. Its image is digest-pinned in `application.yaml`.

Open <https://digarr.ison-mirfak.ts.net> for first-run setup. Configure the
Lidarr service as `http://lidarr.music.svc.cluster.local:8686`. Configure an
OpenAI-compatible provider with the user's 9router base URL ending in `/v1`,
the API key from the 9router dashboard, and an exact model returned by:

```text
GET https://<9router-host>/v1/models
```

Do not put the 9router key in Git. Digarr's first-run UI stores application
configuration. Choose automatic approval only after reviewing the first
recommendations. Automatic operation starts only after this setup and the
Music stack setup are complete.

Create a Spotify developer application and register the callback below. In
Digarr, open **Settings > Connections > Spotify**, enter the client ID and
client secret, connect the account, and select Spotify as the listening
source. Keep the Spotify secret in Digarr, not in Git.

Spotify callback URL:

`https://digarr.ison-mirfak.ts.net/api/v1/auth/oauth/spotify/callback`

The policies allow the standard 9router port `20128` on the tailnet and LAN.
If the instance uses another private port, add that port to
`extra/network-policy.yaml` before setup.
