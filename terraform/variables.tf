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

variable "k3s_api_server_host" {
  description = "Stable k3s API endpoint used for node joins and kubeconfig server"
  type        = string
  default     = "k3s-api.ison-mirfak.ts.net"
}

variable "k3s_kubeconfig_source_host" {
  description = "Direct SSH host used to download /etc/rancher/k3s/k3s.yaml"
  type        = string
  default     = "192.168.2.101"
}

variable "tailscale_authkey" { type = string }
