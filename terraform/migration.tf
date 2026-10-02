# Carry the active VM and its cloud-init snippets to the single-node resource.
moved {
  from = proxmox_virtual_environment_vm.k3s_agents[1]
  to   = proxmox_virtual_environment_vm.k3s_node
}

moved {
  from = proxmox_virtual_environment_file.nvidia_user_data_cloud_config
  to   = proxmox_virtual_environment_file.k3s_node_user_data
}

moved {
  from = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_agent[1]
  to   = proxmox_virtual_environment_file.k3s_node_meta_data
}

# Destroy retired VMs 100-103 and their cloud-init snippets. VM 104 is moved above.
removed {
  from = proxmox_virtual_environment_vm.k3s_master_init
  lifecycle { destroy = true }
}

removed {
  from = proxmox_virtual_environment_vm.k3s_masters
  lifecycle { destroy = true }
}

removed {
  from = proxmox_virtual_environment_vm.k3s_agents
  lifecycle { destroy = true }
}

removed {
  from = proxmox_virtual_environment_file.user_data_cloud_config
  lifecycle { destroy = true }
}

removed {
  from = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_master
  lifecycle { destroy = true }
}

removed {
  from = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_agent
  lifecycle { destroy = true }
}

# Remove the retired one-time provisioners from Terraform state.
removed {
  from = null_resource.k3s_master_init_setup
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_masters_setup
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_agents_setup
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_master_init_dns_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_master_init_service_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_masters_dns_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_masters_api_endpoint_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_agents_dns_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_agents_api_endpoint_config
  lifecycle { destroy = true }
}

removed {
  from = null_resource.k3s_worker_topology_labels
  lifecycle { destroy = true }
}

removed {
  from = null_resource.install_sealed_secrets
  lifecycle { destroy = true }
}
