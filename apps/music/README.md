# Music stack

This namespace runs qBittorrent, Prowlarr, FlareSolverr, Lidarr, Navidrome,
slskd, Soularr, and MusicGrabber. All eight applications run as UID/GID
`1000`. qBittorrent, Lidarr, Navidrome, slskd, Soularr, and MusicGrabber
access the NFS export, which must have matching ownership and permissions
before downloads start.
Create `multimedia/Downloads/music` and
`multimedia/Downloads/slskd/{complete,incomplete}` on the export before the
first sync.

NFS is mounted directly by the Pods. The NAS is `610n1r0`, with export
`/srv/nfs/raid`. Pods connect to the NAS through `192.168.2.1` so mounts stay
on the allowed LAN path. qBittorrent and Lidarr mount the export at `/nas`; use
`/nas/multimedia/Downloads` for downloads and `/nas/multimedia/Music` as the
Lidarr root folder. This common mount keeps imports as atomic moves or
hardlinks. Navidrome mounts the same export read-only and scans
`/nas/multimedia/Music`. Soularr mounts the completed slskd directory at the
same path used by Lidarr and slskd. MusicGrabber writes finished tracks to the
Music directory and mounts completed slskd downloads read-only as acquisition
staging.

Internal service URLs are:

- qBittorrent: `http://qbittorrent.music.svc.cluster.local:8080`
- Prowlarr: `http://prowlarr.music.svc.cluster.local:9696`
- FlareSolverr: `http://flaresolverr.music.svc.cluster.local:8191`
- Lidarr: `http://lidarr.music.svc.cluster.local:8686`
- Navidrome: `http://navidrome.music.svc.cluster.local:4533`
- slskd: `http://slskd.music.svc.cluster.local:5030`
- MusicGrabber: `http://musicgrabber.music.svc.cluster.local:8080`

Soularr has no Service or ingress. Its upstream web UI has no authentication
and exposes its Lidarr and slskd API keys, so this deployment disables it.
Soularr reads its sealed configuration and runs every five minutes.

The CPU and memory budgets are conservative starting bounds for one replica
per service. MusicGrabber idle use was 2.2m CPU and 146Mi memory. Its first
browser-based Spotify import must be measured before adding a CPU limit.

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
5. Open slskd at <https://slskd.ison-mirfak.ts.net>. The username is `admin`.
   Read the generated password locally with:

   ```sh
   kubectl -n music get secret slskd-credentials \
     -o jsonpath='{.data.SLSKD_PASSWORD}' | base64 -d
   ```

   Enter the Soulseek network username and password in the slskd options.
   Completed files use `/nas/multimedia/Downloads/slskd/complete`; partial
   files use `/nas/multimedia/Downloads/slskd/incomplete`.
6. Confirm that slskd shows **Connected**. In Lidarr, monitor one wanted album
   that is missing from the library. Soularr processes one missing album per
   scan for the initial end-to-end test. The flow is Digarr to Lidarr, Soularr
   to slskd, then Lidarr import from the shared NFS path. Increase
   `number_of_albums_to_grab` in the sealed Soularr configuration only after
   the first import succeeds.
7. Open MusicGrabber at <https://musicgrabber.ison-mirfak.ts.net>. Soulseek is
   already enabled and uses the existing slskd credentials and read-only
   download staging.
   Keep **Convert audio** disabled. MusicGrabber then preserves native lossless
   files and does not put lossy audio in a FLAC container.

The services are ClusterIP-only. FlareSolverr has no external ingress and
accepts requests only from Prowlarr. qBittorrent peer ports and the slskd
Soulseek listen port `50300` are not exposed by a Service. slskd can use
indirect connections, but a firewalled peer can remain unavailable. Digarr
and SUB/WAVE are documented in their own operator README.

## Exact Spotify track import

MusicGrabber accepts Spotify playlist URLs as watched playlists or bulk
imports. It ranks confident native-lossless Monochrome/Qobuz and Soulseek
results ahead of lossy sources. A preferred source only breaks a tie inside
the same quality tier. YouTube and other lossy sources remain fallbacks.

For an Exportify CSV, convert it to the `Artist - Title` format used by the
MusicGrabber Bulk Import page:

```sh
python3 apps/music/scripts/exportify_to_musicgrabber.py \
  ~/Downloads/spotify_playlists/Liked_Songs.csv
```

Upload `Liked_Songs.musicgrabber.txt` in **Bulk Import**, review the detected
tracks, and start the import. The server continues the import after the browser
tab closes. MusicGrabber v4.0.2 does not restore the active import panel after a
page reload; use `GET /api/bulk-imports` to find the import ID and
`GET /api/bulk-import/<id>/status` to read its progress. The Queue shows only
tracks that the sequential bulk worker has already searched and queued; pending
bulk tracks are stored separately in the database. Search admission uses the
upstream maximum concurrency of five for the measured 1,599-track import.

Use a watched Spotify playlist with **Append**
sync for playlists that must keep receiving new tracks.

spotDL is not part of this stack. It uses Spotify only for metadata and gets
audio from YouTube. Its upstream maximum is 128 kbps without YouTube Music
Premium and 256 kbps with it. MusicGrabber already provides this lossy
fallback after its lossless sources, so a second spotDL path adds no quality.

Tubifarry is also not installed. The existing Soularr and slskd flow already
handles missing Lidarr albums, while MusicGrabber handles exact Spotify
tracks. Adding a second Lidarr slskd indexer and downloader would create a
duplicate acquisition path.
