# Changelog

## 2026-08-18

- **fix**: Repair the first Spotify music radio rollout by routing NFS over the NAS LAN address, allowing LinuxServer root initialization before the PUID/PGID drop, fixing SUB/WAVE web and broadcast startup permissions, and raising Digarr memory after a 512Mi OOM. ([pending](https://github.com/edlundin/homelab/commit/pending))
- **feat**: Add the Spotify-to-Digarr-to-Lidarr/Prowlarr/qBittorrent-to-NFS-to-Navidrome-to-SUB/WAVE stack with private Tailscale ingress at https://wave.ison-mirfak.ts.net. ([9477a45](https://github.com/edlundin/homelab/commit/9477a45f3cbe9a6ad443677c957fd20b2649571b))
- **feat**: Upgrade the Tailscale Kubernetes operator and proxy images from 1.98.9 to 1.102.2 and configure Argo CD Image Updater to track and write back future stable semantic-version releases. ([82f223d](https://github.com/edlundin/homelab/commit/82f223dd4983ae7b383181335e10d935522073e6))

## 2026-08-09

- **fix**: Set Tandoor's `TANDOOR_PORT` to `80` so its container listens on the port used by the Kubernetes Service and ingress. ([818109e](https://github.com/edlundin/homelab/commit/818109e))
- **fix**: Send `Host: tandoor.oisd.io` on Tandoor HTTP health probes so Django accepts them. ([5724305](https://github.com/edlundin/homelab/commit/5724305))
- **fix**: Allow Tandoor ingress from the actual `tailscale-system` namespace in its NetworkPolicy, restoring the tailnet route. ([eea6f5c](https://github.com/edlundin/homelab/commit/eea6f5c))

## 2026-08-08

- **fix**: Configure Argo CD to ignore the K3s-owned CoreDNS `/data/NodeHosts` field, stopping the repeated OutOfSync/self-heal loop while preserving other drift detection. ([07b67f0](https://github.com/edlundin/homelab/commit/07b67f0))
- **fix**: Upgrade the Tailscale Kubernetes operator and proxies from 1.96.5 to 1.98.9 to fix the TS-2026-008 denial-of-service exposure for Serve/Funnel, including the public n8n Funnel. ([d8d07c8](https://github.com/edlundin/homelab/commit/d8d07c8))
- **feat**: Make Pulse available privately over HTTPS at https://pulse.ison-mirfak.ts.net through the Tailscale ingress/operator. ([cd4c23a](https://github.com/edlundin/homelab/commit/cd4c23a))
- **fix**: Constrain Pulse image automation to v6 so it cannot downgrade the v6 deployment to v5. ([43ed2b0](https://github.com/edlundin/homelab/commit/43ed2b0))
- **feat**: Add Tandoor Recipes through Argo CD with persistent media, a dedicated PostgreSQL database, and public and tailnet routes. ([35c4538](https://github.com/edlundin/homelab/commit/35c4538))

## 2026-08-05

- **fix**: Use server-side apply for Traefik so Argo CD updates large CRDs and restores `IngressRoute` routing. ([e3e1650](https://github.com/edlundin/homelab/commit/e3e1650))
- **feat**: Upgrade Pulse from v5.1.30 to v6.1.2, retain the existing data volume, and use the v6 `FRONTEND_PORT` setting. ([99136f7](https://github.com/edlundin/homelab/commit/99136f7de314c0c3ffa3c4d7fedb648f34e3c2fb))
- **chore**: Ignore local subagent and graph output so generated tool data does not enter commits. ([8222e42](https://github.com/edlundin/homelab/commit/8222e42))
- **fix**: Keep plaintext secret and Helm values files out of Argo CD directory deployments, and deploy the sealed Picsou secret. ([d6c6715](https://github.com/edlundin/homelab/commit/d6c6715))
- **fix**: Restrict K3s kubeconfig and agent credential files to their owner on provisioned nodes. ([23b23ee](https://github.com/edlundin/homelab/commit/23b23ee083548b6dc4958b902cffd61c74b8adca))
