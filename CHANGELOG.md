# Changelog

## 2026-08-20

- **chore**: Remove the unused Pocket TTS sidecar, persistent model cache, and image-update tracking after returning SUB/WAVE to Piper. ([03a4de1](https://github.com/edlundin/homelab/commit/03a4de15d02b20e0d2e97fbfd320181899ef8922))
- **fix**: Expand the Lidarr PVC from 2Gi to 6Gi and the MusicGrabber PVC from 1Gi to 3Gi based on measured full-volume usage, restoring storage headroom for music acquisition. ([pending](https://github.com/edlundin/homelab/commit/pending))

## 2026-08-19

- **fix**: Let the pod `fsGroup` grant Pocket TTS cache access instead of running a `chown` after the init container drops the required capability. ([c20e96b](https://github.com/edlundin/homelab/commit/c20e96b))
- **feat**: Add the CPU-only Pocket TTS sidecar to SUB/WAVE with persistent model caching and automated image updates. ([f25f1db](https://github.com/edlundin/homelab/commit/f25f1db))
- **fix**: Remove MusicGrabber API-key authentication because its v4.0.2 browser client does not send the required header, which restores settings load and save through the private Tailscale route. ([5a516a7](https://github.com/edlundin/homelab/commit/5a516a7))
- **feat**: Add MusicGrabber for lossless-first Spotify exact-track acquisition through existing slskd/Soulseek and Monochrome/Qobuz, with lossy fallback, CSV conversion, private Tailscale access with a sealed API key, NFS music/staging mounts, and Argo CD Image Updater tracking. ([5831ddb](https://github.com/edlundin/homelab/commit/5831ddb9a6d2c2fdef5092907379fdf4585d4689))
- **fix**: Expose the SUB/WAVE Liquidsoap TCP 1234 control endpoint through the Service and NetworkPolicy so the controller can manage the mixer. ([aa8916a](https://github.com/edlundin/homelab/commit/aa8916a0764bf20e76fef1cb5a42aeaca580794c))
- **feat**: Add Soularr to bridge Lidarr wanted albums to slskd, with sealed configuration, a shared NFS path, and Argo CD Image Updater tracking. ([15a9953](https://github.com/edlundin/homelab/commit/15a99537239fc303e04162f05a0ca2b6800da0e))
- **feat**: Add slskd as a Soulseek download target for Digarr and Lidarr, with NAS storage, Tailscale access, sealed credentials, and automated image updates. ([c631838](https://github.com/edlundin/homelab/commit/c63183851035fc585a87ca9d5fc45c730cf1e98c))
- **fix**: Enable Digarr field encryption with a persistent sealed key so saved API and OAuth credentials are not stored as plaintext. ([695f90b](https://github.com/edlundin/homelab/commit/695f90b9bf33d3725b648c95a27c599a0350d50d))
- **feat**: Add an internal FlareSolverr proxy for Prowlarr, automate all 13 radio-stack images through Argo CD Image Updater, and repair Pulse image write-back. ([200ec0f](https://github.com/edlundin/homelab/commit/200ec0f0ad149b4dc1d8e84a01fd2450face18b4))
- **fix**: Expose host CPU features, including SSE4.2, to both K3s agent VMs so Bun-based workloads can run without the `qemu64` CPU incompatibility. ([88cbbef](https://github.com/edlundin/homelab/commit/88cbbef184c7e247f9109ab9e3df457f6fecd435))

## 2026-08-18

- **fix**: Schedule Digarr on the node where its runtime is stable and use a recreate rollout for its single-writer backup volume. ([b412ca7](https://github.com/edlundin/homelab/commit/b412ca7a256142d755d07d44b70c995c49606032))
- **fix**: Run Digarr's Debian image to avoid the Alpine runtime OOM and set its HTTPS origin for browser authentication. ([dce5900](https://github.com/edlundin/homelab/commit/dce5900c5c6fffc0e96bbddfa72bf5ab2b091e6c))
- **fix**: Reuse the existing PostgreSQL service for Digarr, with an idempotent database bootstrap, sealed credentials, and restricted cross-namespace access. ([6a57459](https://github.com/edlundin/homelab/commit/6a574590d87098d7840814dbb61b3cd75e8f3e5b))
- **fix**: Replace Digarr's failing embedded PGlite startup with its supported bundled PostgreSQL backend and a sealed database credential. ([eccbb8f](https://github.com/edlundin/homelab/commit/eccbb8fd0499eec3100c3a2985e88b24245c8baa))
- **chore**: Remove Picsou and Tandoor from Argo CD and infrastructure-as-code definitions to retire their deployments. ([f821de0](https://github.com/edlundin/homelab/commit/f821de0445f5ed8c3cf31fbb00463ada1fc61a58))
- **fix**: Remove the remaining radio rollout blockers by breaking the SUB/WAVE readiness deadlock and raising Digarr's memory tripwire after a confirmed 1Gi OOM. ([dc7e479](https://github.com/edlundin/homelab/commit/dc7e479cac3017b218c4e3ea3ac580d92770106b))
- **fix**: Repair the first Spotify music radio rollout by routing NFS over the NAS LAN address, allowing LinuxServer root initialization before the PUID/PGID drop, fixing SUB/WAVE web and broadcast startup permissions, and raising Digarr memory after a 512Mi OOM. ([5b38b43](https://github.com/edlundin/homelab/commit/5b38b43232206d5e3bf1f6efba250fa287475085))
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
