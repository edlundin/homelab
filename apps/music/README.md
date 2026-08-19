# Music stack

This namespace runs qBittorrent, Prowlarr, FlareSolverr, Lidarr, and
Navidrome. All five applications run as UID/GID `1000`. qBittorrent, Lidarr,
and Navidrome access the NFS export, which must have matching ownership and
permissions before downloads start. Create `multimedia/Downloads/music` on
the export before the first sync.

NFS is mounted directly by the Pods. The NAS is `610n1r0`, with export
`/srv/nfs/raid`. Pods connect to the NAS through `192.168.2.1` so mounts stay
on the allowed LAN path. qBittorrent and Lidarr mount the export at `/nas`; use
`/nas/multimedia/Downloads` for downloads and `/nas/multimedia/Music` as the
Lidarr root folder. This common mount keeps imports as atomic moves or
hardlinks. Navidrome mounts the same export read-only and scans
`/nas/multimedia/Music`.

Internal service URLs are:

- qBittorrent: `http://qbittorrent.music.svc.cluster.local:8080`
- Prowlarr: `http://prowlarr.music.svc.cluster.local:9696`
- FlareSolverr: `http://flaresolverr.music.svc.cluster.local:8191`
- Lidarr: `http://lidarr.music.svc.cluster.local:8686`
- Navidrome: `http://navidrome.music.svc.cluster.local:4533`

The CPU and memory budgets are conservative starting bounds for one replica
per service. Review actual usage before increasing them.

## One-time setup

1. Open qBittorrent at <https://qbittorrent.ison-mirfak.ts.net>. Set the
   `music` category to `/nas/multimedia/Downloads/music` (or another path
   below that directory), and keep the WebUI enabled on port 8080. The first
   temporary WebUI password is in `kubectl -n music logs deploy/qbittorrent`.
2. Open Prowlarr at <https://prowlarr.ison-mirfak.ts.net>. Under **Settings >
   Indexers**, add a FlareSolverr proxy with URL
   `http://flaresolverr.music.svc.cluster.local:8191` and tag
   `flaresolverr`. Add the same tag only to indexers that require it. Add
   indexers, then add the Lidarr application at
   `http://lidarr.music.svc.cluster.local:8686`.
3. Open Lidarr at <https://lidarr.ison-mirfak.ts.net>. Add root folder
   `/nas/multimedia/Music`. Add qBittorrent with host
   `qbittorrent.music.svc.cluster.local`, port `8080`, and category `music`.
   Complete the download-client test. Link Prowlarr's indexers to Lidarr.
4. Open Navidrome at <https://navidrome.ison-mirfak.ts.net> and create its
   first administrator. Its music folder is already
   `/nas/multimedia/Music`.

The services are ClusterIP-only. FlareSolverr has no external ingress and
accepts requests only from Prowlarr. qBittorrent peer ports are not exposed by
a Service. Digarr and SUB/WAVE are documented in their own operator README.
