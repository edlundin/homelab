terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.85.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure

  ssh {
    agent            = true
    agent_forwarding = true
  }
}

data "local_file" "sealed-secret-keys" {
  filename = "secrets/sealed-secrets-keys.yaml"
}

locals {
  debian_13_lxc_template_filename      = "debian-13-standard_13.1-2_amd64.tar.zst"
  debian_13_lxc_template_path          = "${var.diskimages_storage}:vztmpl/${local.debian_13_lxc_template_filename}"
  debian_13_lxc_template_sha           = "5aec4ab2ac5c16c7c8ecb87bfeeb10213abe96db6b85e2463585cea492fc861d7c390b3f9c95629bf690b95e9dfe1037207fc69c0912429605f208d5cb2621f8"
  debian_13_lxc_template_sha_algorithm = "sha512"
  debian_13_lxc_template_url           = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  debian_13_genericcloud_filename      = "debian-13-genericcloud-amd64.qcow2"
  debian_13_genericcloud_path          = "${var.diskimages_storage}:vztmpl/${local.debian_13_genericcloud_filename}"
  debian_13_genericcloud_sha           = "aa1963a7356a7fab202e5eebc0c1954c4cbd4906e3d8e9bf993beb22e0a90cd7fe644bd5e0fb5ec4b9fbea16744c464fda34ef1be5c3532897787d16c7211f86"
  debian_13_genericcloud_sha_algorithm = "sha512"
  debian_13_genericcloud_url           = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"

  dns_server = "192.168.2.3"

  swap_size       = 512
  network_gateway = "192.168.2.254"

  k3s_vm_id_start = 100

  k3s_master_count = 3
  k3s_master_config = {
    node_name        = var.proxmox_node_name
    started          = true
    on_boot          = true
    os_template_path = local.debian_13_lxc_template_path
    os_type          = "debian"
    cores            = 2
    memory           = 3072
    swap             = local.swap_size
    disk_size        = 20
    dns_server       = local.dns_server
    gateway_ipv4     = local.network_gateway
  }

  k3s_agent_count = 2
  k3s_agent_config = {
    node_name        = var.proxmox_node_name
    started          = true
    on_boot          = true
    os_template_path = local.debian_13_lxc_template_path
    os_type          = "debian"
    cores            = 6
    memory           = 10240
    swap             = local.swap_size
    disk_size        = 30
    dns_server       = local.dns_server
    gateway_ipv4     = local.network_gateway
  }

  service_containers = {
    "s3" = {
      node_name        = var.proxmox_node_name
      vm_id            = 140
      start_at_boot    = true
      started          = true
      os_template_path = local.debian_13_lxc_template_path
      os_type          = "debian"
      unprivileged     = true
      nesting          = true
      keyctl           = false
      description      = "S3 private instance"
      cores            = 2
      memory           = 3072
      swap             = local.swap_size
      disk_size        = 15
      dns_server       = local.dns_server
      ipv4_address     = "192.168.2.140/24"
      gateway_ipv4     = local.network_gateway
    },
    "tailscale-exit-node" = {
      node_name        = var.proxmox_node_name
      vm_id            = 143
      start_at_boot    = true
      started          = true
      os_template_path = local.debian_13_lxc_template_path
      os_type          = "debian"
      unprivileged     = true
      nesting          = true
      keyctl           = false
      description      = "Tailscale exit node into ProtonVPN"
      cores            = 2
      memory           = 1024
      swap             = local.swap_size
      disk_size        = 4
      dns_server       = local.dns_server
      ipv4_address     = "192.168.2.143/24"
      gateway_ipv4     = local.network_gateway
    },
    # "wirebos" = {
    #   node_name        = var.proxmox_node_name
    #   vm_id            = 200
    #   start_at_boot    = true
    #   started          = true
    #   os_template_path = local.debian_13_lxc_template_path
    #   os_type          = "debian"
    #   unprivileged     = true
    #   nesting          = true
    #   keyctl           = false
    #   description      = "WireBos"
    #   usb_devices      = ["/dev/ttyUSB0"]
    #   cores            = 4
    #   memory           = 6144
    #   swap             = local.swap_size
    #   disk_size        = 16
    #   dns_server       = local.dns_server
    #   ipv4_address     = "192.168.2.200/24"
    #   gateway_ipv4     = local.network_gateway
    # },
    # "actual-budget" = {
    #   node_name        = var.proxmox_node_name
    #   vm_id            = 103
    #   start_at_boot    = true
    #   started          = true
    #   os_template_path = local.debian_13_lxc_template_path
    #   os_type          = "debian"
    #   unprivileged     = true
    #   nesting          = true
    #   keyctl           = false
    #   description      = "Actual Budget private instance"
    #   cores            = 2
    #   memory           = 2048
    #   swap             = local.swap_size
    #   disk_size        = 4
    #   dns_server       = local.dns_server
    #   ipv4_address     = "192.168.2.103/24"
    #   gateway_ipv4     = local.network_gateway
    # },
    # "karakeep" = {
    #   node_name        = var.proxmox_node_name
    #   vm_id            = 104
    #   start_at_boot    = true
    #   started          = true
    #   os_template_path = local.debian_13_lxc_template_path
    #   os_type          = "debian"
    #   unprivileged     = true
    #   nesting          = true
    #   keyctl           = false
    #   description      = "Karakeep private instance"
    #   cores            = 2
    #   memory           = 2048
    #   swap             = local.swap_size
    #   disk_size        = 4
    #   dns_server       = local.dns_server
    #   ipv4_address     = "192.168.2.104/24"
    #   gateway_ipv4     = local.network_gateway
    # },
    # "ai" = {
    #   node_name        = var.proxmox_node_name
    #   vm_id            = 105
    #   start_at_boot    = true
    #   started          = true
    #   os_template_path = local.debian_13_lxc_template_path
    #   os_type          = "debian"
    #   unprivileged     = true
    #   nesting          = true
    #   keyctl           = false
    #   description      = "LiteLLM and Qdrant private instance"
    #   cores            = 2
    #   memory           = 2048
    #   swap             = local.swap_size
    #   disk_size        = 4
    #   dns_server       = local.dns_server
    #   ipv4_address     = "192.168.2.105/24"
    #   gateway_ipv4     = local.network_gateway
    # }
  }
}

# First K3s Master (Initialize cluster)
resource "proxmox_virtual_environment_vm" "k3s_master_init" {
  node_name = var.proxmox_node_name
  vm_id     = local.k3s_vm_id_start
  started   = local.k3s_master_config.started
  name      = "k3s-master-1"
  on_boot   = local.k3s_master_config.on_boot

  initialization {
    datastore_id = var.diskimages_storage

    dns {
      servers = [local.k3s_master_config.dns_server]
    }

    ip_config {
      ipv4 {
        address = "192.168.2.${local.k3s_vm_id_start}/24"
        gateway = local.network_gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_master[0].id
  }

  cpu {
    cores = local.k3s_master_config.cores
  }

  memory {
    dedicated = local.k3s_master_config.memory
  }

  disk {
    datastore_id = var.diskimages_storage
    import_from  = proxmox_virtual_environment_download_file.debian_13_genericcloud.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = local.k3s_master_config.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  # Prevent Terraform from recreating container on changes
  lifecycle {
    ignore_changes = [
      disk[0],
      initialization[0].user_account,
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
      network_device[0],
    ]
  }
}

# Install K3s on first master (using null_resource to avoid container recreation)
resource "null_resource" "k3s_master_init_setup" {
  depends_on = [proxmox_virtual_environment_vm.k3s_master_init]

  triggers = {
    container_id = proxmox_virtual_environment_vm.k3s_master_init.id
    k3s_version  = var.k3s_version
  }

  connection {
    type  = "ssh"
    user  = "root"
    agent = true
    host  = regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",

      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' INSTALL_K3S_EXEC='server --cluster-init --disable traefik --write-kubeconfig-mode=644 --node-taint CriticalAddonsOnly=true:NoExecute' K3S_TOKEN='${var.k3s_token}' sh -",

      # Wait for k3s service to be active
      "echo 'Waiting for any Node objects to appear...'",
      "for i in {1..60}; do",
      "  if kubectl get nodes --no-headers 2>/dev/null | grep -q .; then",
      "    echo 'Nodes found.'",
      "    break",
      "  fi",
      "sleep 5",
      "done",

      # If no nodes after ~5 minutes, fail with diagnostics
      "if ! kubectl get nodes --no-headers 2>/dev/null | grep -q .; then",
      "  echo 'ERROR: No Node resources found after waiting. Check cluster creation, kubeconfig, and permissions.'",
      "  kubectl cluster-info || true",
      "  exit 1",
      "fi",

      # Wait for node to be Ready
      "echo 'Waiting for node to become Ready...'",
      "kubectl wait --for=condition=Ready node --all --timeout=300s",
      "echo 'Node is Ready'",
    ]
  }
}

#Additional K3s Masters
resource "proxmox_virtual_environment_vm" "k3s_masters" {
  count = local.k3s_master_count - 1

  node_name = var.proxmox_node_name
  vm_id     = local.k3s_vm_id_start + count.index + 1
  started   = local.k3s_master_config.started
  name      = "k3s-master-${count.index + 2}"
  on_boot   = local.k3s_master_config.on_boot

  initialization {
    datastore_id = var.diskimages_storage

    dns {
      servers = [local.k3s_master_config.dns_server]
    }

    ip_config {
      ipv4 {
        address = "192.168.2.${local.k3s_vm_id_start + count.index + 1}/24"
        gateway = local.network_gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_master[count.index + 1].id
  }

  cpu {
    cores = local.k3s_master_config.cores
  }

  memory {
    dedicated = local.k3s_master_config.memory
  }

  disk {
    datastore_id = var.diskimages_storage
    import_from  = proxmox_virtual_environment_download_file.debian_13_genericcloud.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = local.k3s_master_config.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  # Prevent Terraform from recreating container on changes
  lifecycle {
    ignore_changes = [
      disk[0],
      initialization[0].user_account,
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
      network_device[0],
    ]
  }
}

# Install K3s on additional masters
resource "null_resource" "k3s_masters_setup" {
  count = local.k3s_master_count - 1

  depends_on = [
    proxmox_virtual_environment_vm.k3s_masters,
    null_resource.k3s_master_init_setup
  ]

  triggers = {
    container_id = proxmox_virtual_environment_vm.k3s_masters[count.index].id
    k3s_version  = var.k3s_version
  }

  connection {
    type = "ssh"
    user = "root"
    host = regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_masters[count.index].initialization[0].ip_config[0].ipv4[0].address)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' INSTALL_K3S_EXEC='server --server https://${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}:6443 --node-taint CriticalAddonsOnly=true:NoExecute' K3S_TOKEN='${var.k3s_token}' sh -"
    ]

  }
}

# K3s Agent Nodes
resource "proxmox_virtual_environment_vm" "k3s_agents" {
  count = local.k3s_agent_count

  node_name = var.proxmox_node_name
  vm_id     = local.k3s_vm_id_start + local.k3s_master_count + count.index
  started   = local.k3s_master_config.started
  name      = "k3s-agent-${count.index + 1}"
  on_boot   = local.k3s_agent_config.on_boot

  initialization {
    datastore_id = var.diskimages_storage

    dns {
      servers = [local.k3s_agent_config.dns_server]
    }

    ip_config {
      ipv4 {
        address = "192.168.2.${local.k3s_vm_id_start + local.k3s_master_count + count.index}/24"
        gateway = local.network_gateway
      }
    }


    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.meta_data_cloud_config_k3s_agent[count.index].id
  }

  cpu {
    cores = local.k3s_agent_config.cores
  }

  memory {
    dedicated = local.k3s_agent_config.memory
  }

  disk {
    datastore_id = var.diskimages_storage
    import_from  = proxmox_virtual_environment_download_file.debian_13_genericcloud.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = local.k3s_agent_config.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  # Prevent Terraform from recreating container on changes
  lifecycle {
    ignore_changes = [
      disk[0],
      initialization[0].user_account,
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
      network_device[0],
    ]
  }
}

# Install K3s on agents
resource "null_resource" "k3s_agents_setup" {
  count = local.k3s_agent_count

  depends_on = [
    proxmox_virtual_environment_vm.k3s_agents,
    null_resource.k3s_master_init_setup
  ]

  triggers = {
    container_id = proxmox_virtual_environment_vm.k3s_agents[count.index].id
    k3s_version  = var.k3s_version
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' K3S_URL='https://${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}:6443' K3S_TOKEN='${var.k3s_token}' sh -",
      "sleep 10"
    ]

    connection {
      type = "ssh"
      user = "root"
      host = regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_agents[count.index].initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }
}

resource "null_resource" "install_sealed_secrets" {
  depends_on = [
    null_resource.k3s_master_init_setup,
    null_resource.k3s_masters_setup,
    null_resource.k3s_agents_setup
  ]

  triggers = {
    k3s_ready = join(",", [for agent in proxmox_virtual_environment_vm.k3s_agents : agent.id])
  }

  connection {
    type = "ssh"
    user = "root"
    host = regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml",
      "kubectl wait --for=condition=Ready nodes --all --timeout=600s",
      "cat <<EOF | kubectl apply -f -",
      "${data.local_file.sealed-secret-keys.content}",
      "EOF",
      "kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.32.2/controller.yaml",
    ]
  }
}

resource "proxmox_virtual_environment_container" "service" {
  # depends_on = [terraform_data.restore_from_backup]
  for_each = local.service_containers

  node_name     = each.value.node_name
  vm_id         = each.value.vm_id
  start_on_boot = each.value.start_at_boot
  started       = each.value.started
  description   = each.value.description
  unprivileged  = each.value.unprivileged

  initialization {
    hostname = "${var.proxmox_node_name}-${each.key}"

    user_account {
      keys = var.ssh_public_keys
    }

    dns {
      servers = [each.value.dns_server]
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.gateway_ipv4
      }
    }
  }

  dynamic "device_passthrough" {
    for_each = lookup(each.value, "usb_devices", [])

    content {
      path = device_passthrough.value
    }
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
    swap      = each.value.swap
  }

  disk {
    datastore_id = var.diskimages_storage
    size         = each.value.disk_size
  }


  operating_system {
    template_file_id = each.value.os_template_path
    type             = each.value.os_type
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  features {
    nesting = each.value.nesting
    keyctl  = each.value.keyctl
  }
}

resource "proxmox_virtual_environment_download_file" "debian_13_lxc_template" {
  content_type       = "vztmpl"
  datastore_id       = var.diskimages_storage
  node_name          = var.proxmox_node_name
  url                = local.debian_13_lxc_template_url
  checksum           = local.debian_13_lxc_template_sha
  checksum_algorithm = local.debian_13_lxc_template_sha_algorithm
}

resource "proxmox_virtual_environment_download_file" "debian_13_genericcloud" {
  content_type       = "import"
  datastore_id       = var.diskimages_storage
  node_name          = var.proxmox_node_name
  url                = local.debian_13_genericcloud_url
  checksum           = local.debian_13_genericcloud_sha
  checksum_algorithm = local.debian_13_genericcloud_sha_algorithm
  file_name          = local.debian_13_genericcloud_filename
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.diskimages_storage
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "user-data-cloud-config.yaml"
    data      = <<-EOF
    #cloud-config
    manage_etc_hosts: true
    timezone: Europe/Paris

    users:
      - name: root
        lock_passwd: true
        shell: /bin/bash
        ssh_authorized_keys: [${join(",", [for k in var.ssh_public_keys : k])}]
    
    ssh_pwauth: false

    # Ensure PermitRootLogin is yes (key-only) and disable password authentication
    # Different distros may already default to key-only if no password is set.
    write_files:
      - path: /etc/ssh/sshd_config.d/99-cloudinit-root.conf
        permissions: "0644"
        owner: "root:root"
        content: |
          PermitRootLogin prohibit-password
          PasswordAuthentication no
          PubkeyAuthentication yes
          ChallengeResponseAuthentication no
          UsePAM yes

    package_update: true
    package_upgrade: true
    package_reboot_if_required: true
    packages:
      - open-iscsi
      - nfs-common
      - qemu-guest-agent
      - curl
      - neovim
    
    runcmd:
      - curl -fsSL https://tailscale.com/install.sh | sh
      - echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
      - tailscale up --auth-key=${var.tailscale_authkey}
      - systemctl enable --now qemu-guest-agent
      - systemctl enable --now iscsid
      - systemctl reload ssh
      - systemctl reload sshd
      - echo "done" > /tmp/cloud-config.done
    EOF
  }
}

resource "proxmox_virtual_environment_file" "meta_data_cloud_config_k3s_master" {
  count        = local.k3s_master_count
  content_type = "snippets"
  datastore_id = var.diskimages_storage
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "meta-data-cloud-config-k3s-master-${count.index + 1}.yaml"
    data      = <<-EOF
    #cloud-config
    local-hostname: k3s-master-${count.index + 1}
    EOF
  }
}

resource "proxmox_virtual_environment_file" "meta_data_cloud_config_k3s_agent" {
  count        = local.k3s_agent_count
  content_type = "snippets"
  datastore_id = var.diskimages_storage
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "meta-data-cloud-config-k3s-agent-${count.index + 1}.yaml"
    data      = <<-EOF
    #cloud-config
    local-hostname: k3s-agent-${count.index + 1}
    EOF

  }
}

# Outputs
output "k3s_master_ips" {
  value = concat(
    [regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)],
    [for master in proxmox_virtual_environment_vm.k3s_masters : regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", master.initialization[0].ip_config[0].ipv4[0].address)]
  )
  description = "IP addresses of K3s master nodes"
}

output "k3s_agent_ips" {
  value       = [for agent in proxmox_virtual_environment_vm.k3s_agents : agent.initialization[0].ip_config[0].ipv4[0].address]
  description = "IP addresses of K3s agent nodes"
}

output "kubeconfig_command" {
  value       = "scp root@${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config && sed -i 's/127.0.0.1/${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}/g' ~/.kube/k3s-config"
  description = "Command to download and configure kubeconfig"
}

output "cluster_info" {
  value = <<-EOT
    
    ====================================
    K3s Cluster Deployed Successfully!
    ====================================
    
    Masters: ${local.k3s_master_count} nodes
    Agents:  ${local.k3s_agent_count} nodes
    K3s Version: ${var.k3s_version}
    
    Next steps:
    1. Get kubeconfig:
       scp root@${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config && sed -i 's/127.0.0.1/${regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)", proxmox_virtual_environment_vm.k3s_master_init.initialization[0].ip_config[0].ipv4[0].address)[0]}/g' ~/.kube/k3s-config
    
    2. Set KUBECONFIG:
       export KUBECONFIG=~/.kube/k3s-config
    
    3. Verify cluster:
       kubectl get nodes
  EOT
}
