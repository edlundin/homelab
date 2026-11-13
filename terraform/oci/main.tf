# OCI Always Free Network Load Balancer in front of AdGuard Home on peirce and
# soteria (public DoH at doh.oisd.dev). See docs/doh.md.
#
# Separate root module from ../ (Proxmox): it uses different credentials, and a
# Proxmox plan must not require OCI access. The VMs, VCN, subnet and the
# subnet's default security list were created in the console and are only
# referenced here by OCID.

terraform {
  required_version = ">= 1.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 9.13.0"
    }
  }
}

# API-key auth from ~/.oci/config (outside the repository).
provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.region
}

locals {
  doh_port = 443

  backends = {
    peirce  = "10.0.1.31"
    soteria = "10.0.1.13"
  }
}

resource "oci_core_network_security_group" "doh_nlb" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "nsg-dns-nlb"
}

resource "oci_core_network_security_group_security_rule" "doh_nlb_https_in" {
  network_security_group_id = oci_core_network_security_group.doh_nlb.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Public DoH"

  tcp_options {
    destination_port_range {
      min = local.doh_port
      max = local.doh_port
    }
  }
}

resource "oci_network_load_balancer_network_load_balancer" "doh" {
  compartment_id             = var.compartment_id
  display_name               = var.nlb_display_name
  subnet_id                  = var.subnet_id
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.doh_nlb.id]

  # The reserved public IP (88.96.55.143) is pinned in device profiles
  # (ServerAddresses) and in Cloudflare's doh.oisd.dev record.
  reserved_ips {
    id = var.reserved_public_ip_id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_network_load_balancer_backend_set" "doh" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.doh.id
  name                     = var.backend_set_name

  # 5-tuple: every TCP connection is balanced independently. Pinning clients
  # gains nothing, because both AdGuards are kept identical by adguardhome-sync.
  policy = "FIVE_TUPLE"

  # The VMs reply to the NLB inside the VCN; ClientIDs identify devices, so
  # the client address is not needed.
  is_preserve_source = false

  # Probe AdGuard itself on the private IP (the subnet security list allows
  # TCP 53 from the VCN). Caddy is not covered; OCI does not document whether
  # its HTTPS checker sends SNI or a Host header, which Caddy needs for routing.
  health_checker {
    protocol           = "DNS"
    port               = 53
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3

    dns {
      domain_name        = "example.com."
      query_class        = "IN"
      query_type         = "A"
      transport_protocol = "TCP"
      rcodes             = ["NOERROR"]
    }
  }
}

resource "oci_network_load_balancer_backend" "doh" {
  for_each = local.backends

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.doh.id
  backend_set_name         = oci_network_load_balancer_backend_set.doh.name
  name                     = each.key
  ip_address               = each.value
  port                     = local.doh_port
  weight                   = 1
}

resource "oci_network_load_balancer_listener" "doh" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.doh.id
  name                     = var.listener_name
  default_backend_set_name = oci_network_load_balancer_backend_set.doh.name
  protocol                 = "TCP"
  port                     = local.doh_port

  # TCP idle timeout stays at the 360 s default: longer than Caddy's
  # 5-minute idle timeout, so Caddy closes idle connections first.
  # TLS passes through, so PROXY protocol stays off (Caddy would otherwise
  # need it on every path, including Tailscale and private-IP access).
  is_ppv2enabled = false
}

output "public_ip" {
  value = [
    for ip in oci_network_load_balancer_network_load_balancer.doh.ip_addresses :
    ip.ip_address if ip.is_public
  ]
}
