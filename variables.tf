# Define the common tags for all resources
locals {
  common_tags = {
    Environment = "dev"
    orchestrator = "terraform"
  }
}

variable "env"{
description = "Environment"

}
variable "region" {
  description = "Region of location"
  
}

variable "prefix" {
  description = "Resources naming prefix"
}
variable "vms_count" {
  description = "How much VMs are needed"
}

variable "dnsforpubip" {
  description = "Which cloud region should be used"
 }

variable "username" {
  description = "Username for ssh description"
}
variable "password" {
  description = "Password for ssh description"
  
}

variable "vnet" {
  description = "Virtual network"
  
}
variable "vsubnet" {
  description = "Lan subnet"
  
}