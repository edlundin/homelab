# Music stack

This namespace runs SoulSync, slskd, and Navidrome. The services run as
UID/GID `1000` and use the NFS export at `192.168.2.1:/srv/nfs/raid`.

SoulSync downloads completed files from slskd at `/app/downloads` and writes
the music library to `/app/Transfer`. These paths map to
`multimedia/Downloads/slskd/complete` and `multimedia/Music` on the NFS
export. Navidrome scans the same music directory read-only.

Internal service URLs are:

- Navidrome: `http://navidrome.music.svc.cluster.local:4533`
- slskd: `http://slskd.music.svc.cluster.local:5030`
- SoulSync: `http://soulsync.music.svc.cluster.local:8008`

## One-time setup

1. Open Navidrome at <https://navidrome.ison-mirfak.ts.net> and create its
   first administrator. Its music folder is already
   `/nas/multimedia/Music`.
2. Open slskd at <https://slskd.ison-mirfak.ts.net>. The username is `admin`.
   Read the generated password locally with:

   ```sh
   kubie exec OISD music kubectl get secret slskd-credentials \
     -o jsonpath='{.data.SLSKD_PASSWORD}' | base64 --decode
   ```

   Enter the Soulseek network credentials in the slskd options. Completed
   files use `/nas/multimedia/Downloads/slskd/complete`; partial files use
   `/nas/multimedia/Downloads/slskd/incomplete`.
3. Confirm that slskd shows **Connected**.
4. Open SoulSync at <https://soulsync.ison-mirfak.ts.net>. Configure its slskd
   service as `http://slskd.music.svc.cluster.local:5030`, with downloads at
   `/app/downloads`, and get the existing slskd API key with:

   ```sh
   kubie exec OISD music kubectl get secret slskd-credentials \
     -o jsonpath='{.data.SLSKD_API_KEY}' | base64 --decode
   ```

   Configure SoulSync's transfer or music path as `/app/Transfer`, and its
   Navidrome service as `http://navidrome.music.svc.cluster.local:4533`.
   The Spotify OAuth callback is
   `https://soulsync.ison-mirfak.ts.net/callback`.
5. Configure at least one folder that you are willing to expose as a share
   in slskd before the first download. Soulseek can ban accounts that do not
   share files.

Start with one small Spotify playlist and Soulseek. Do not enable automatic
mirror for the same playlist in more than one application. YouTube PO-token
support is unconfirmed; test full downloads before relying on YouTube.
