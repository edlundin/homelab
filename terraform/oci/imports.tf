# One-time adoption of the load balancer created in the OCI console on
# 2026-11-13. After the first successful apply, delete this file and the
# nlb_id, nsg_id and nsg_rule_id variables.

import {
  to = oci_core_network_security_group.doh_nlb
  id = var.nsg_id
}

import {
  to = oci_core_network_security_group_security_rule.doh_nlb_https_in
  id = "networkSecurityGroups/${var.nsg_id}/securityRules/${var.nsg_rule_id}"
}

import {
  to = oci_network_load_balancer_network_load_balancer.doh
  id = var.nlb_id
}

import {
  to = oci_network_load_balancer_backend_set.doh
  id = "networkLoadBalancers/${var.nlb_id}/backendSets/${var.backend_set_name}"
}

import {
  for_each = local.backends
  to       = oci_network_load_balancer_backend.doh[each.key]
  id       = "networkLoadBalancers/${var.nlb_id}/backendSets/${var.backend_set_name}/backends/${each.key}"
}

import {
  to = oci_network_load_balancer_listener.doh
  id = "networkLoadBalancers/${var.nlb_id}/listeners/${var.listener_name}"
}
