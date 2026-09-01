# Changelog

## 2026-09-01

- **fix**: Migrate homelab service hosts, wildcard certificates, and DNS configuration to `oisd.dev`. ([pending](https://github.com/edlundin/homelab/commit/pending))

## 2026-08-29

- **fix**: Reduce Longhorn weekly-backup retention from 7 to 4 snapshots to limit backup storage growth while retaining four weekly recovery points. ([pending](https://github.com/edlundin/homelab/commit/pending))
- **fix**: Migrate Navidrome, SUB/WAVE, Pulse, and Chatterbox to measured smaller Longhorn PVCs with new v2 claim names, reducing overprovisioned storage while preserving workload data. ([753f515](https://github.com/edlundin/homelab/commit/753f515))
- **fix**: Rename the K3s worker identity from `610n1r0` to `sarasate` across CoreDNS, Digarr node selection, descheduler documentation, and Terraform topology labeling. ([437f78a](https://github.com/edlundin/homelab/commit/437f78a))
- **fix**: Use the official Pulse Helm chart and its stable-release channel so Argo CD tracks the latest v6 release while excluding `-rc` prereleases. ([d52a123](https://github.com/edlundin/homelab/commit/d52a123))
- **fix**: Upgrade Longhorn as one coordinated chart release, remove unsafe manager/UI image overrides, and preserve Pulse's recovered Longhorn PV binding. ([41ae5be](https://github.com/edlundin/homelab/commit/41ae5be))
- **fix**: Complete the staged Longhorn upgrade on the 1.12 line and track coordinated patch releases without allowing automatic minor-version jumps. ([9e40d07](https://github.com/edlundin/homelab/commit/9e40d07))
- **fix**: Exclude SUB/WAVE from GPU descheduler LowNodeUtilization eviction so long-running audio fingerprint backfills survive the analyzer's high CPU use. ([76db769](https://github.com/edlundin/homelab/commit/76db769))

## 2026-08-27

- **fix**: Raise the SUB/WAVE controller upstream timeout from 600s to 3 hours (10,800,000 ms) after the 600-second deadline still interrupted heavy audio fingerprinting, and raise analyzer CPU request/limit from 100m/1 core to 1/4 cores after 999m saturation and 75% throttled periods. ([1f7cd48](https://github.com/edlundin/homelab/commit/1f7cd48))
- **feat**: Make SUB/WAVE use the heavy CLAP/Demucs analyzer, track its releases with Argo CD Image Updater, and set a 1Gi memory request with a 6Gi memory limit. ([0548ebc](https://github.com/edlundin/homelab/commit/0548ebc))

## 2026-08-22

- **fix**: Raise the SoulSync Kubernetes memory limit from 2Gi to 5Gi after measured OOM kills, restoring headroom for the music workload. ([0b21c5f](https://github.com/edlundin/homelab/commit/0b21c5f))

## 2026-08-21

- **feat**: Track the Longhorn manager and UI images with Argo CD Image Updater so stable semantic-version releases write back into the chart values and drive automatic Longhorn upgrades. ([385bdb5](https://github.com/edlundin/homelab/commit/385bdb5))
- **chore**: Remove MusicGrabber, Lidarr, Soularr, Prowlarr, FlareSolverr, and qBittorrent with their dedicated services, storage, access, and network resources, leaving SoulSync, slskd, and Navidrome as the music stack. ([ede6263](https://github.com/edlundin/homelab/commit/ede6263))
- **feat**: Add SoulSync as a parallel Spotify-to-Soulseek/Navidrome trial with private Tailscale access, persistent configuration, NFS storage, and isolated network access. ([fc68448](https://github.com/edlundin/homelab/commit/fc68448))
- **fix**: Label `k3s-agent-1` and `k3s-agent-2` as topology zone `nietzsche`, label node `610n1r0` as zone `sarasate` through Terraform, and require two Traefik replicas to spread across those physical failure domains. ([997ae32](https://github.com/edlundin/homelab/commit/997ae32))
- **fix**: Preserve the GPU ROM BAR and ignore managed cloud-init SSH user-data drift so Terraform does not replace K3s VMs and LXC containers. ([0ef6219](https://github.com/edlundin/homelab/commit/0ef6219))
- **fix**: Add the Rootshell FIDO2 public SSH key to Terraform-managed VM and container access. ([cd3b600](https://github.com/edlundin/homelab/commit/cd3b600))
- **fix**: Use the dedicated `homelab_oisd` SSH key for Ansible and Terraform, add account-scoped authorized-key bootstrapping, silence Python interpreter discovery warnings, and persist the updated Terraform state. ([bc0d870](https://github.com/edlundin/homelab/commit/bc0d870))
- **perf**: Set MusicGrabber `SEARCH_CONCURRENCY=5` for the measured 1,599-track bulk import and document its background progress endpoints and queue behavior. ([e4f9251](https://github.com/edlundin/homelab/commit/e4f9251))
- **fix**: Improve worker scheduling with preempting GPU workload priority, measured LowNodeUtilization rebalancing, and scheduler-visible resource requests. ([37dae51](https://github.com/edlundin/homelab/commit/37dae51))

## 2026-08-20

- **feat**: Let SUB/WAVE use the existing GPU-backed Chatterbox server through its OpenAI-compatible TTS API. ([b27b4ca](https://github.com/edlundin/homelab/commit/b27b4ca))
- **fix**: Configure the NVIDIA CUDA library path for Chatterbox so the GPU-backed TTS service can load its runtime libraries. ([411ee27](https://github.com/edlundin/homelab/commit/411ee27))
- **fix**: Allow the NVIDIA device plugin to run on the dedicated GPU node without Node Feature Discovery labels. ([d1b423b](https://github.com/edlundin/homelab/commit/d1b423b))
- **feat**: Provision `k3s-agent-2` with GTX 1070 passthrough and NVIDIA driver sources/packages, deploy the NVIDIA device plugin, and expose a GPU-backed Chatterbox Turbo TTS service. ([0a130a8](https://github.com/edlundin/homelab/commit/0a130a8))
- **fix**: Ensure Terraform-managed VMs and containers receive the managed SSH public key alongside configured keys for account access. ([1323836](https://github.com/edlundin/homelab/commit/1323836))
- **chore**: Remove the unused Pocket TTS sidecar, persistent model cache, and image-update tracking after returning SUB/WAVE to Piper. ([03a4de1](https://github.com/edlundin/homelab/commit/03a4de15d02b20e0d2e97fbfd320181899ef8922))
- **fix**: Expand the Lidarr PVC from 2Gi to 6Gi and the MusicGrabber PVC from 1Gi to 3Gi based on measured full-volume usage, restoring storage headroom for music acquisition. ([f8f1b3c](https://github.com/edlundin/homelab/commit/f8f1b3c))

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
- **fix**: Send `Host: tandoor.oisd.dev` on Tandoor HTTP health probes so Django accepts them. ([5724305](https://github.com/edlundin/homelab/commit/5724305))
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
