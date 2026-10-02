variable "proxmox_endpoint" { type = string }
variable "proxmox_node_name" { type = string }
variable "proxmox_username" { type = string }
variable "proxmox_password" {
  type      = string
  sensitive = true
}
variable "root_password_hash" {
  description = "Hashed root password for console access"
  type        = string
  sensitive   = true
}
variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "diskimages_storage" {
  description = "Proxmox datastore for VM disks, cloud-init snippets, and LXC rootfs"
  type        = string
}

variable "k3s_token" {
  type      = string
  sensitive = true
}
variable "k3s_version" {
  type    = string
  default = "v1.36.1+k3s1"
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}
