# qBittorrent and VueTorrent

The qBittorrent pod runs on Sarasate to keep the existing peer port at
`192.168.2.1:6881` (TCP and UDP). Its `/downloads` directory is the existing
`/mnt/raid/torrent` directory on Sarasate, mounted from the RAID 5 NFS export
`192.168.2.1:/srv/nfs/raid`. Its `/config` directory is
`/mnt/raid/qbittorrent/config` on the same export. An init container downloads
VueTorrent `v2.36.1` directly from its GitHub release, verifies the published
SHA-256, and caches it in `qBittorrent/vuetorrent-upstream-v2.36.1`. It skips
the download on later starts when that release is already present. qBittorrent
uses `WebUI\RootFolder=/config/qBittorrent/vuetorrent-upstream-v2.36.1`.

The UI is available over HTTPS at
<https://torrent.ison-mirfak.ts.net> through Tailscale and
<https://torrent.oisd.dev> through Traefik's existing wildcard certificate.

The LinuxServer image starts as root for its init process and runs qBittorrent
as UID/GID `1000` using `PUID` and `PGID`. The NFS export maps clients to
UID/GID `1000`. The existing download paths remain `/downloads/downloaded`,
`/downloads/downloading`, and `/downloads/torrent_files`.

Before enabling the Kubernetes replica, stop and disable the old
`composition-qbittorrent.service` on Sarasate. Copy its `/config` tree
from `/opt/docker-compositions/qbittorrent/data/qbittorrent/config` into
`/mnt/raid/qbittorrent/config`, excluding shell history and logs while preserving
the existing credentials, search plugins, and torrent resume state. Do not run
both replicas against the same downloads. The
repository does not contain the private configuration or WebUI credentials.
