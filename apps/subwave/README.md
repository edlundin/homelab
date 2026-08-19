# SUB/WAVE

SUB/WAVE 1.8.0 runs as one Deployment with Caddy, web, controller, broadcast,
the lean analyzer, and the CPU-only Pocket TTS sidecar. The images are
digest-pinned. Caddy is the only
ingress backend and the only service exposed to Tailscale at
<https://wave.ison-mirfak.ts.net>. The service names and ports match the
upstream Caddy/controller configuration: `caddy:80`, `web:7700`,
`controller:7701`, `broadcast:7702`, and `analyzer:8080`. Pocket TTS uses
loopback port `8081` because the analyzer already owns port `8080` in the pod.

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
setup are complete. Chatterbox and the Docker-socket proxy are intentionally
not deployed.

## Pocket TTS

The sidecar loads only Pocket TTS on CPU and uses `estelle` as its default
voice. Select `pocket-tts` for the applicable personas or as the default TTS
engine in SUB/WAVE settings. The first start downloads model weights. A 5 GiB
Longhorn volume keeps that cache across pod replacements. Current language
weights range from about 225 MiB for English to 641 MiB for French.

SUB/WAVE 1.8.0 calls Pocket TTS without a language selector. Pocket TTS then
loads its default English model, not the separate `french_24l` model. The
sidecar enables the supported upstream integration, but this release cannot
guarantee native French pronunciation through Pocket TTS.

The policy allows the standard 9router port `20128`. If the instance uses a
different non-HTTP private port, add that port to `network-policy.yaml`.
