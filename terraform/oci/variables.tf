variable "oci_config_profile" {
  description = "Profile in ~/.oci/config used for API-key authentication"
  type        = string
  default     = "DEFAULT"
}

variable "region" {
  type    = string
  default = "eu-paris-1"
}

# OCIDs are not secrets, but they are tenancy-specific: keep them in a local
# terraform.tfvars (git-ignored), not in the repository.
variable "compartment_id" {
  description = "Compartment of the VCN, the VMs and the load balancer"
  type        = string
}

variable "vcn_id" {
  description = "VCN edlvcn"
  type        = string
}

variable "subnet_id" {
  description = "Subnet 10.0.1.0/24 holding peirce, soteria and the load balancer"
  type        = string
}

variable "reserved_public_ip_id" {
  description = "Reserved public IP 88.96.55.143 attached to the load balancer"
  type        = string
}

variable "nlb_id" {
  description = "Existing load balancer, for the one-time import in imports.tf"
  type        = string
}

variable "nsg_rule_id" {
  description = "Existing nsg-dns-nlb TCP 443 rule, for the one-time import in imports.tf"
  type        = string
}

variable "nsg_id" {
  description = "Existing nsg-dns-nlb, for the one-time import in imports.tf"
  type        = string
}

variable "nlb_display_name" {
  type    = string
  default = "nlb-doh"
}

variable "backend_set_name" {
  type    = string
  default = "doh"
}

variable "listener_name" {
  type    = string
  default = "doh"
}
