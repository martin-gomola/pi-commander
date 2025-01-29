variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_public_key_path" {}
variable "ssh_private_key_path" {}
variable "private_key_path" {}
variable "fingerprint" {}
variable "vcn_cidr" {}
variable "subnet_cidr" {}
variable "ubuntu_x86_image_ocid" {
  type = map(string)
}
variable "ubuntu_arm_image_ocid" {
  type = map(string)
}
variable "control_plane_ip" {}
variable "k3s_worker_x86_ip" {}
