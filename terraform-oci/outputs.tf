output "control_plane_ip" {
  value = oci_core_instance.k3s_control_plane.public_ip
}

output "worker_x86_ip" {
  value = oci_core_instance.k3s_worker_x86.public_ip
}
