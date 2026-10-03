# Tailscale ingress across two hosts

`ingress-two-hosts.yaml` creates two ingress proxies using a Tailscale
`ProxyGroup`. Its `ProxyClass` permits scheduling on the control-plane host and
requires the proxies to occupy different `topology.kubernetes.io/zone` values.
Both physical hosts must carry that label. The worker-only default class remains
in use for other proxies.

The live node mapping is `sarasate` → zone `sarasate` and `spinoza` → zone
`nietzsche`. These labels were applied to the nodes; retain them when rebuilding
or replacing a node. Terraform already configures Spinoza's `nietzsche` label.

`traefik-tailscale-ha` forwards HTTP and HTTPS to the existing Traefik pods through
the Tailscale Service `k3s-cluster-ha`. The existing `traefik-tailscale` endpoint is
retained during migration. Two Traefik replicas and two SearXNG replicas are also
spread across the physical hosts.

Before switching traffic:

1. Confirm both ProxyGroup pods are ready, with one on each physical host.
2. Confirm the operator's OAuth credentials have `General/Services` write scope,
   in addition to its device and auth-key scopes. Configure this in Tailscale's
   [Trust credentials](https://console.tailscale.com/admin/settings/trust-credentials)
   page, as described in the [operator installation guide](https://tailscale.com/docs/kubernetes-operator/install-operator).
   Credentials with only `devices:core` and `auth_keys` returned HTTP 404 when
   accessing the Services API during setup. Confirm that the tailnet policy
   permits the proxies to advertise the new Service. With the default `tag:k8s`
   tags, the relevant policy fragment is:

   ```json
   {"autoApprovers": {"services": {"tag:k8s": ["tag:k8s"]}}}
   ```

   Merge this with the existing policy. Existing access grants must also allow
   clients to reach the new Service; preserve the intended access restrictions.
3. Obtain the new Service's external virtual IP and verify HTTPS against it using
   the existing `search.oisd.dev` hostname and certificate.
4. In Cloudflare's `oisd.dev` zone, update the records that currently point to
   the `k3s-cluster` IP `100.98.143.92` to the new virtual IP. This is a shared
   entry point for all apps, so verify their routes before switching it. Keep
   these records DNS-only: the virtual IP is reachable through the tailnet.
   Test access from a tailnet client before retiring the old endpoint.

See the official [layer 3 ingress guide](https://tailscale.com/docs/kubernetes-operator/ingress/expose-workload-to-tailnet-l3)
and [permissions guide](https://tailscale.com/docs/kubernetes-operator/reference/rbac).

This duplicates the application and ingress paths. Redis remains standalone, and
the K3s API still has one control-plane server. Loss of that server can prevent
recovery and rescheduling even while existing pods on the other host continue
running. This configuration does not provide end-to-end host-failure tolerance.
