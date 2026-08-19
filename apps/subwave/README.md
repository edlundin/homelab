# SUB/WAVE

SUB/WAVE 1.8.0 runs as one Deployment with Caddy, web, controller, broadcast,
and the lean analyzer. The images are digest-pinned. Caddy is the only
ingress backend and the only service exposed to Tailscale at
<https://wave.ison-mirfak.ts.net>. The service names and ports match the
upstream Caddy/controller configuration: `caddy:80`, `web:7700`,
`controller:7701`, `broadcast:7702`, and `analyzer:8080`.

The shared `subwave-state` Longhorn PVC stores station state. The init
container creates `ADMIN_USER=admin` and a random `ADMIN_PASS` in
`/var/sub-wave/secrets.env` only when that file has no admin password. Retrieve
the generated password with:

```bash
kubectl -n subwave exec deploy/subwave -c controller -- sh -c 'grep "^ADMIN_" /var/sub-wave/secrets.env'
```

To change it, replace the `ADMIN_PASS` line in that file and restart the
Deployment. Keep the output private. No credential is stored in Git.

## One-time onboarding

1. Open <https://wave.ison-mirfak.ts.net/onboarding> and sign in with the
   generated admin credentials.
2. Configure Navidrome with
   `http://navidrome.music.svc.cluster.local:4533`, then the Navidrome user
   and password created during Navidrome setup.
3. Configure the OpenAI-compatible provider with the user's 9router base URL
   ending in `/v1`, the API key from its dashboard, and an exact model from
   `GET https://<9router-host>/v1/models`. Do not use ChatGPT Pro credentials.
4. Complete station setup and verify `/api/health` reports `on-air`.

Automatic operation starts only after this onboarding and the Music stack
setup are complete. Heavy TTS and the Docker-socket proxy are intentionally
not deployed.

The policy allows the standard 9router port `20128`. If the instance uses a
different non-HTTP private port, add that port to `network-policy.yaml`.
