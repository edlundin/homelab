terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.93.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure

  ssh {
    agent            = false
    agent_forwarding = false
    private_key      = file(pathexpand("~/.ssh/homelab_oisd"))
  }
}

locals {
  managed_ssh_public_keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINSUWgarmqMSeEgVBdoaeRfza29D2QrOFImshC4qTUDnAAAABHNzaDo= edlundin@macbookpro.ison-mirfak.ts.net",
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBJXgxwWv9PjmZABLdidh2gtV3upEJ3baomK6Jr6X3jMCbJXfrdtBS69DlfqjzLz/mtanUFvCo8yuvHwDq5b9Y0cAAAASYmV0YS5yb290c2hlbGwuY29t iphone-17-pro-max",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIILe1CvyHOfvzhCREQnSdf9ChnMm0B6z5nD+bEzhgVkP homelab_oisd",
  ]
  ssh_public_keys = distinct(concat(var.ssh_public_keys, local.managed_ssh_public_keys))

  debian_13_lxc_template_filename      = "debian-13-standard_13.1-2_amd64.tar.zst"
  debian_13_lxc_template_path          = "${var.diskimages_storage}:vztmpl/${local.debian_13_lxc_template_filename}"
  debian_13_lxc_template_sha           = "5aec4ab2ac5c16c7c8ecb87bfeeb10213abe96db6b85e2463585cea492fc861d7c390b3f9c95629bf690b95e9dfe1037207fc69c0912429605f208d5cb2621f8"
  debian_13_lxc_template_sha_algorithm = "sha512"
  debian_13_lxc_template_url           = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  debian_13_genericcloud_filename      = "debian-13-genericcloud-amd64.qcow2"
  debian_13_genericcloud_path          = "${var.diskimages_storage}:vztmpl/${local.debian_13_genericcloud_filename}"
  debian_13_genericcloud_sha           = "0e5edfbe49b0cca779a4a7dc9738f34c92e3ff481ee1f7d5c4e93e180654fe275eb8c96397224c6ca04a2910eaaed27489f431573ebe4cb5412ef257888b2b18"
  debian_13_genericcloud_sha_algorithm = "sha512"
  debian_13_genericcloud_url           = "https://cloud.debian.org/images/cloud/trixie/20260316-2418/debian-13-genericcloud-amd64-20260316-2418.qcow2"

  dns_servers = ["141.253.110.131", "141.145.216.51"]

  swap_size       = 512
  network_gateway = "192.168.2.254"

  # Sarasate runs the only k3s server. Terraform manages its Proxmox peer.
  k3s_server_host = "192.168.2.1"
  k3s_node = {
    vm_id        = 104
    name         = "spinoza"
    ipv4_address = "192.168.2.104/24"
    zone         = "nietzsche"
    cores        = 4
    sockets      = 2
    memory       = 20480
    disk_size    = 200
  }
  k3s_gpu = {
    pci_id = "0000:10:00"
    packages = [
      "gnupg",
      "linux-headers-cloud-amd64",
      "nvidia-kernel-dkms",
      "nvidia-driver",
    ]
    container_toolkit_package = "nvidia-container-toolkit"
    debian_source             = "deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware"
    debian_security_source    = "deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware"
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
      dns_servers      = local.dns_servers
      ipv4_address     = "192.168.2.140/24"
      gateway_ipv4     = local.network_gateway
    },
    # "tailscale-exit-node" = {
    #   node_name        = var.proxmox_node_name
    #   vm_id            = 143
    #   start_at_boot    = true
    #   started          = true
    #   os_template_path = local.debian_13_lxc_template_path
    #   os_type          = "debian"
    #   unprivileged     = true
    #   nesting          = true
    #   keyctl           = false
    #   description      = "Tailscale exit node into ProtonVPN"
    #   cores            = 2
    #   memory           = 1024
    #   swap             = local.swap_size
    #   disk_size        = 4
    #   dns_servers      = local.dns_servers
    #   ipv4_address     = "192.168.2.143/24"
    #   gateway_ipv4     = local.network_gateway
    # },
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
    #   dns_servers      = local.dns_servers
    #   ipv4_address     = "192.168.2.200/24"
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
    #   dns_servers      = local.dns_servers
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
    #   dns_servers      = local.dns_servers
    #   ipv4_address     = "192.168.2.105/24"
    #   gateway_ipv4     = local.network_gateway
    # }
  }
}

# The only Proxmox k3s node; Sarasate's server is managed outside Terraform.
resource "proxmox_virtual_environment_vm" "k3s_node" {
  node_name = var.proxmox_node_name
  vm_id     = local.k3s_node.vm_id
  name      = local.k3s_node.name
  started   = true
  on_boot   = true

  initialization {
    datastore_id = var.diskimages_storage

    dns {
      servers = local.dns_servers
    }

    ip_config {
      ipv4 {
        address = local.k3s_node.ipv4_address
        gateway = local.network_gateway
      }
    }

    meta_data_file_id = proxmox_virtual_environment_file.k3s_node_meta_data.id
    user_data_file_id = proxmox_virtual_environment_file.k3s_node_user_data.id
  }

  cpu {
    cores   = local.k3s_node.cores
    sockets = local.k3s_node.sockets
    type    = "host"
  }

  memory {
    dedicated = local.k3s_node.memory
    floating  = 0
  }

  disk {
    datastore_id = var.diskimages_storage
    import_from  = proxmox_virtual_environment_download_file.debian_13_genericcloud.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = local.k3s_node.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  # GPU support is added to the node, not tied to a separate VM role.
  hostpci {
    device = "hostpci0"
    id     = local.k3s_gpu.pci_id
    pcie   = false
    rombar = true
  }

  lifecycle {
    ignore_changes = [
      disk[0],
      initialization[0].user_account,
      # Changing cloud-init after first boot must not replace the running node.
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
      network_device[0],
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
      keys = local.ssh_public_keys
    }

    dns {
      servers = each.value.dns_servers
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

  lifecycle {
    ignore_changes = [
      initialization[0].user_account,
    ]
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

resource "proxmox_virtual_environment_file" "k3s_node_user_data" {
  content_type = "snippets"
  datastore_id = var.diskimages_storage
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "nvidia-user-data-cloud-config.yaml"
    data      = <<-EOF
    #cloud-config
    manage_etc_hosts: true
    timezone: Europe/Paris

    users:
      - name: root
        hashed_passwd: ${var.root_password_hash}
        lock_passwd: false
        shell: /bin/bash
        ssh_authorized_keys: ${jsonencode(local.ssh_public_keys)}

    ssh_pwauth: false

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
      - path: /etc/rancher/k3s/resolv.conf
        permissions: "0644"
        content: |
          nameserver ${local.dns_servers[0]}
          nameserver ${local.dns_servers[1]}
          options timeout:2 attempts:2
      - path: /etc/rancher/k3s/config.yaml
        permissions: "0644"
        content: |
          resolv-conf: /etc/rancher/k3s/resolv.conf
          node-name: ${local.k3s_node.name}
          node-label:
            - topology.kubernetes.io/zone=${local.k3s_node.zone}

    package_update: true
    package_upgrade: true
    package_reboot_if_required: true

    apt:
      sources:
        debian:
          source: "${local.k3s_gpu.debian_source}"
          filename: "debian-non-free.list"
        debian-security:
          source: "${local.k3s_gpu.debian_security_source}"
          filename: "debian-security-non-free.list"

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
      - apt-get update
      - DEBIAN_FRONTEND=noninteractive apt-get install -y ${join(" ", local.k3s_gpu.packages)}
      - |
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y ${local.k3s_gpu.container_toolkit_package}
      - |
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' K3S_URL='https://${local.k3s_server_host}:6443' K3S_TOKEN='${var.k3s_token}' sh -
      - systemctl enable --now qemu-guest-agent
      - systemctl enable --now iscsid
      - systemctl reload ssh
      - systemctl reload sshd
      - echo "done" > /tmp/cloud-config.done
    EOF
  }
}

resource "proxmox_virtual_environment_file" "k3s_node_meta_data" {
  content_type = "snippets"
  datastore_id = var.diskimages_storage
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "meta-data-cloud-config-k3s-agent-2.yaml"
    data      = <<-EOF
    #cloud-config
    local-hostname: ${local.k3s_node.name}
    EOF
  }
}

output "k3s_nodes" {
  value = {
    sarasate = local.k3s_server_host
    spinoza  = split("/", proxmox_virtual_environment_vm.k3s_node.initialization[0].ip_config[0].ipv4[0].address)[0]
  }
  description = "Addresses of the external k3s server and Terraform-managed GPU node"
}

output "cluster_info" {
  value = <<-EOT
    Server: sarasate (${local.k3s_server_host}), managed outside Terraform
    Proxmox node: ${local.k3s_node.name} (VM ${local.k3s_node.vm_id})
    GPU: ${local.k3s_gpu.pci_id}
  EOT
}
