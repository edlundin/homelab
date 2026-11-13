# Public DoH fallback on peirce and soteria

AdGuard Home on the Oracle E2 Micro VMs peirce and soteria normally serves
clients over Tailscale. Their DoH, DoT and dashboard ports listen on the
`*.ison-mirfak.ts.net` names. This setup adds a public DoH endpoint on port
443 for the times when Tailscale is unavailable. Devices use one address,
`https://doh.oisd.dev/dns-query/<ClientID>`, served by an OCI Always Free
Network Load Balancer (public IP 88.96.55.143) in front of both VMs. The VMs'
own public IPs do not accept 443. Caddy also answers to a per-host name, for
testing one backend over Tailscale or from inside the VCN (these names have no
public DNS record; use `curl --resolve`):

| Host    | Per-host name          | Private IP | Tailscale IP    |
| ------- | ---------------------- | ---------- | --------------- |
| peirce  | `dns.peirce.oisd.dev`  | 10.0.1.31  | 100.64.26.122   |
| soteria | `dns.soteria.oisd.dev` | 10.0.1.13  | 100.101.130.116 |

The VM configuration (Caddy, certbot, AdGuard, sync) was done by hand on
2026-11-13; this document records how to rebuild it. The load balancer is
described in `terraform/oci/`. Secrets are not stored here; see
[Secrets](#secrets).

## Request path

```text
client --TCP 443--> OCI NLB 88.96.55.143 (doh.oisd.dev) --TCP passthrough-->
       Caddy :443 on peirce or soteria (TLS for doh.oisd.dev / dns.<host>.oisd.dev)
       --only /dns-query/<allowed ClientID>--> AdGuard Home https://127.0.0.1:4043
```

## Network Load Balancer

Created in the OCI console, then described in `terraform/oci/` (a separate
root module with API-key auth from `~/.oci/config` and OCIDs in a local,
git-ignored `terraform.tfvars`). `imports.tf` adopts the console resources on
the first apply; delete it afterwards. Settings:

- Public, in the VMs' subnet (10.0.1.0/24), with a reserved public IP and an
  ephemeral private IP. NSG `nsg-dns-nlb` allows TCP 443 from `0.0.0.0/0`.
- Listener TCP 443 to one backend set: peirce and soteria on port 443,
  weight 1 each, 5-tuple hash policy, preserve source IP off, proxy protocol
  off. Default idle timeouts (TCP 360 s, longer than Caddy's 5-minute idle
  timeout, so Caddy closes idle connections first).
- Health check: DNS over TCP on port 53, query `example.com.` IN A, RCODE
  NOERROR, 10 s interval, 3 s timeout, 3 retries. It probes AdGuard on the
  private IP, so the subnet security list must allow TCP 53 from
  `10.0.0.0/16`. It does not cover Caddy. An HTTPS check is not used because
  OCI does not document whether it sends SNI or a Host header.
- TLS passes through untouched, so both VMs carry a certificate for
  `doh.oisd.dev`. Cloudflare has a DNS-only `A doh.oisd.dev 88.96.55.143`.

Failover test on 2026-11-13: with AdGuard stopped on peirce, 5 of 12 queries
failed during the first ~20 s (until the health check marked it down), then
all succeeded through soteria. Clients retry, so this shows up as a short
delay rather than an outage.

## Exposure

- The subnet security list allows 443 and TCP 53 only from `10.0.0.0/16`,
  so the VMs' public IPs do not answer on 443. The load balancer is reachable
  from the internet only through its NSG rule. Both live in the same subnet,
  so removing the NSG rule closes `doh.oisd.dev`.
- Caddy listens on every interface: the load balancer reaches it on the
  private IPs, and Tailscale clients on the Tailscale IPs.
- Caddy proxies only the allow-listed `/dns-query/<ClientID>` paths. Every
  other path, including the AdGuard dashboard, returns 404.
- AdGuard keeps its own Tailscale certificate and configuration. Caddy
  verifies the upstream with `tls_server_name <host>.ison-mirfak.ts.net`.
- DoT (853) and the dashboard (4043/8080) are not opened publicly. The VM
  firewall rejects them, and the Oracle security list does not open them.
  Plain DNS on the VMs' public IPs is closed; home clients use Sarasate's
  AdGuard or the Tailscale IPs.

## Access control with ClientIDs

AdGuard Home reads a ClientID from the DoH path `/dns-query/<ClientID>`
(routes `GET|POST /dns-query/{ClientID}` are enabled by default). Caddy uses
that path as an access key:

- `/etc/caddy/doh-clients.caddy` (root:caddy, 0640) defines the allow list.
  It holds the real IDs and must stay private:

  ```caddyfile
  # Allowed AdGuard Home ClientIDs for public DoH. One path per client.
  @doh_allowed path /dns-query/<client-id> /dns-query/<another-client-id>
  ```

- A ClientID may contain only lowercase letters, digits and `-` (at most 64
  characters). Generate one per device, for example
  `printf 'mac-%s\n' "$(openssl rand -hex 12)"`.
- To add or revoke a device, edit the file on both VMs and run
  `sudo systemctl reload caddy`.
- AdGuard's own **Allowed clients** list is deliberately left empty. It
  applies to every protocol and would lock out the plain DNS (53) and
  Tailscale clients that rely on the current open access.
- Do not run Caddy with an environment-variable allow list: the packaged unit
  starts `caddy run --environ`, which prints the environment to the journal.

## DNS records (Cloudflare)

Only `A doh.oisd.dev 88.96.55.143`, **DNS only**. Records for the VMs
themselves (`peirce.oisd.dev`, `*.peirce.oisd.dev` and the soteria
equivalents) were removed so their public IPs are not published. Certbot's
DNS-01 challenge does not need them.

Keep `doh.oisd.dev` DNS only. Cloudflare's proxy would work technically
(Universal SSL covers `*.oisd.dev`, and "Full (strict)" accepts the origin
certificate), but it terminates TLS, so Cloudflare would see every query and
the ClientID in the path. Bot protection can also challenge DoH clients.
Second-level names such as `dns.peirce.oisd.dev` cannot be proxied on the
free plan at all (`ERR_SSL_VERSION_OR_CIPHER_MISMATCH`).

## Certificates

Each VM holds a Let's Encrypt certificate for its own wildcard
(`*.peirce.oisd.dev`, `*.soteria.oisd.dev`) plus the shared `doh.oisd.dev`,
issued by certbot with the Cloudflare DNS-01 plugin.
Caddy's apt package has no Cloudflare module, and a custom Caddy build would
be overwritten by `apt upgrade`, so certbot owns issuance.

```sh
sudo apt-get install certbot python3-certbot-dns-cloudflare
# /etc/letsencrypt/cloudflare.ini (root, 0600):
#   dns_cloudflare_api_token = <Zone:DNS:Edit token for oisd.dev only>
sudo certbot certonly -n --agree-tos -m edvard.lundin@pm.me --no-eff-email \
  --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  --cert-name "$(hostname).oisd.dev" -d "*.$(hostname).oisd.dev" -d doh.oisd.dev
```

`certbot.timer` renews the certificate. The deploy hook
`/etc/letsencrypt/renewal-hooks/deploy/caddy-certs.sh` copies it to a path
the `caddy` user can read. Run the hook by hand once after the first issuance,
because certbot runs directory hooks only on renewal:

```sh
#!/bin/sh
# Copy the *.<host>.oisd.dev certificate where Caddy (user caddy) can read it, then reload.
set -e
name=$(basename "$RENEWED_LINEAGE")
[ "$name" = "$(hostname).oisd.dev" ] || exit 0
install -d -m 750 -o root -g caddy /etc/caddy/certs
install -m 644 -o root -g caddy "$RENEWED_LINEAGE/fullchain.pem" /etc/caddy/certs/$name.crt
install -m 640 -o root -g caddy "$RENEWED_LINEAGE/privkey.pem" /etc/caddy/certs/$name.key
systemctl reload caddy || true
```

```sh
sudo env RENEWED_LINEAGE=/etc/letsencrypt/live/$(hostname).oisd.dev \
  /etc/letsencrypt/renewal-hooks/deploy/caddy-certs.sh
sudo certbot renew --dry-run --no-random-sleep-on-renew --cert-name "$(hostname).oisd.dev"
```

## Caddy

Caddy comes from the official repository (`dl.cloudsmith.io/public/caddy/stable`).
`/etc/caddy/Caddyfile` imports `/etc/caddy/dns.caddy`; on soteria the
Caddyfile also serves other sites. `dns.caddy` for peirce (replace the host
name for soteria):

```caddyfile
dns.peirce.oisd.dev, doh.oisd.dev {
	tls /etc/caddy/certs/peirce.oisd.dev.crt /etc/caddy/certs/peirce.oisd.dev.key
	import /etc/caddy/doh-clients.caddy
	handle @doh_allowed {
		reverse_proxy https://127.0.0.1:4043 {
			transport http {
				tls_server_name peirce.ison-mirfak.ts.net
			}
		}
	}
	respond 404
}
```

AdGuard's web address must include loopback for this upstream. Both VMs use
`http.address: 0.0.0.0:8080`, with `tls.port_https: 4043`. Stop AdGuard Home
before editing `/opt/AdGuardHome/AdGuardHome.yaml`, because it rewrites the
file on shutdown.

## Configuration sync

soteria is the source of truth. `adguardhome-sync` runs on soteria in Docker
and copies soteria's AdGuard settings (upstreams, filters, user rules,
rewrites, clients, services, query-log and stats settings) to peirce every
10 minutes. Make AdGuard changes on soteria only; changes made on peirce are
overwritten. DHCP and TLS settings are excluded, because the TLS certificate
paths differ per host.

The admin login is the same on both instances and is stored on soteria in
`/etc/adguardhome-sync/{username,password}` (owner 1001, mode 0400; the image
runs as UID 1001). The container uses host networking and maps the Tailscale
names to the Tailscale IPs, because soteria does not use MagicDNS:

```sh
sudo docker run -d --name adguardhome-sync --restart unless-stopped --network host \
  --add-host soteria.ison-mirfak.ts.net:100.101.130.116 \
  --add-host peirce.ison-mirfak.ts.net:100.64.26.122 \
  -v /etc/adguardhome-sync/username:/run/secrets/username:ro \
  -v /etc/adguardhome-sync/password:/run/secrets/password:ro \
  -e CRON='*/10 * * * *' -e RUN_ON_START=true -e API_PORT=0 \
  -e ORIGIN_URL=https://soteria.ison-mirfak.ts.net:4043 \
  -e ORIGIN_USERNAME_FILE=/run/secrets/username -e ORIGIN_PASSWORD_FILE=/run/secrets/password \
  -e REPLICA1_URL=https://peirce.ison-mirfak.ts.net:4043 \
  -e REPLICA1_USERNAME_FILE=/run/secrets/username -e REPLICA1_PASSWORD_FILE=/run/secrets/password \
  -e FEATURES_DHCP_SERVER_CONFIG=false -e FEATURES_DHCP_STATIC_LEASES=false -e FEATURES_TLS_CONFIG=false \
  ghcr.io/bakito/adguardhome-sync:v0.9.6 run
```

`API_PORT=0` disables the sync's web API, which would otherwise collide with
AdGuard's port 8080 on the host network. Check runs with
`sudo docker logs adguardhome-sync`.

## VM networking

Both VMs use a Tailscale exit node, which installs a default route in policy
table 52. Without a fix, replies to inbound public connections leave through
the exit node and never reach the client, so an open port looks filtered.
`/etc/systemd/system/ingress-reply-route.service` sends traffic sourced from
the private IP through the main table instead (use 10.0.1.13 on soteria):

```ini
[Unit]
Description=Send replies from 10.0.1.31 through ens3 instead of the Tailscale exit node
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/sbin/ip rule del from 10.0.1.31 lookup main priority 5200
ExecStart=/usr/sbin/ip rule add from 10.0.1.31 lookup main priority 5200
ExecStop=/usr/sbin/ip rule del from 10.0.1.31 lookup main priority 5200

[Install]
WantedBy=multi-user.target
```

Traffic that the VM starts itself still uses the exit node. The Oracle images
also filter with iptables, so 443 is allowed before the final `REJECT` rule
and saved in `/etc/iptables/rules.v4`:

```text
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
```

## macOS profiles

Each device (Mac, iPhone) gets one profile with its own ClientID, pointing at
`doh.oisd.dev`. `ServerAddresses` pins the load balancer IP, so the profile
needs no bootstrap DNS lookup. The same profile works on iOS 14 and later;
there, iCloud Private Relay bypasses it for Safari while enabled.

Requirements found on macOS 26.1 and later:

- `PayloadScope` must be `System` at the top level. Without it, installation
  fails with "The 'VPN Service' payload could not be installed".
- Use new `PayloadUUID` values (`uuidgen`) for every generated profile.

Template (replace `<device>`, `<client-id>` and both UUIDs):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.apple.dnsSettings.managed</string>
      <key>PayloadIdentifier</key><string>dev.oisd.doh.<device>.settings</string>
      <key>PayloadUUID</key><string><uuid-1></string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadDisplayName</key><string>OISD DoH</string>
      <key>DNSSettings</key>
      <dict>
        <key>DNSProtocol</key><string>HTTPS</string>
        <key>ServerURL</key><string>https://doh.oisd.dev/dns-query/<client-id></string>
        <key>ServerAddresses</key><array><string>88.96.55.143</string></array>
      </dict>
      <key>OnDemandRules</key>
      <array>
        <dict>
          <key>Action</key><string>EvaluateConnection</string>
          <key>ActionParameters</key>
          <array><dict>
            <key>DomainAction</key><string>NeverConnect</string>
            <key>Domains</key><array><string>ts.net</string><string>local</string><string>lan</string></array>
          </dict></array>
        </dict>
        <dict><key>Action</key><string>Connect</string></dict>
      </array>
    </dict>
  </array>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadIdentifier</key><string>dev.oisd.doh.<device></string>
  <key>PayloadUUID</key><string><uuid-2></string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadScope</key><string>System</string>
  <key>PayloadDisplayName</key><string>OISD DoH (<device>)</string>
</dict>
</plist>
```

The `NeverConnect` domains stay on the system resolver (Tailscale MagicDNS,
mDNS and the LAN). The generated profiles embed the ClientID, so keep them out
of the repository.

### Interaction with Tailscale

A VPN's DNS settings take precedence over a DNS profile on macOS. With "Use
Tailscale DNS" on, every lookup goes through MagicDNS (100.100.100.100) and
the tailnet nameservers, and the profile is unused. It takes over when
Tailscale, or Tailscale DNS, is off. To keep non-tailnet lookups away from
the network's DHCP resolver while Tailscale is up, the tailnet's global
nameservers should be the AdGuard Tailscale IPs with **Override local DNS**
enabled (tailscale/tailscale#15512).

## Verification

```sh
# RFC 8484 GET for www.example.com A; expect 200 and a non-empty answer.
Q=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB
curl -s -o /dev/null -w '%{http_code}\n' -H 'accept: application/dns-message' \
  "https://doh.oisd.dev/dns-query/<client-id>?dns=$Q"
# Without an ID, with a wrong ID, or for /login.html: expect 404.
curl -s -o /dev/null -w '%{http_code}\n' "https://doh.oisd.dev/dns-query?dns=$Q"
# One backend directly: use https://dns.peirce.oisd.dev/... or dns.soteria.
# Through another interface: add --resolve dns.peirce.oisd.dev:443:<private-or-tailscale-ip>
```

## Secrets

Kept outside the repository:

- The Cloudflare API token (Zone:DNS:Edit, `oisd.dev` only) lives in
  `/etc/letsencrypt/cloudflare.ini` on each VM. Create a new scoped token for
  a rebuild; do not reuse cert-manager's cluster token, which covers more
  zones.
- ClientIDs live in `/etc/caddy/doh-clients.caddy` on the VMs and in the
  device profiles.
- The AdGuard admin login used by the sync lives in
  `/etc/adguardhome-sync/` on soteria.
