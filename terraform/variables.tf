variable "proxmox_endpoint" { type = string }
variable "proxmox_node_name" { type = string }
variable "proxmox_username" { type = string }
variable "proxmox_password" { type = string }
variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "diskimages_storage" {
  description = "Storage name for LXC rootfs"
  type        = string
}

variable "k3s_token" { type = string }
variable "k3s_version" {
  type    = string
  default = "v1.34.1+k3s1"
}

variable "tailscale_authkey" { type = string }
