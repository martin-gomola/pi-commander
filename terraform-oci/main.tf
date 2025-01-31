provider "oci" {
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  region               = var.region
  private_key_path     = var.private_key_path
  fingerprint          = var.fingerprint
}

resource "oci_core_instance" "k3s_control_plane" {
  compartment_id      = var.compartment_ocid
  availability_domain = "AD-1"
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "k3s-control-plane"
  source_details {
    source_type = "image"
    source_id   = var.ubuntu_x86_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-config-control-plane.yaml"))
  }
}

resource "oci_core_instance" "k3s_worker_x86" {
  compartment_id      = var.compartment_ocid
  availability_domain = "AD-1"
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "k3s-worker-x86"
  source_details {
    source_type = "image"
    source_id   = var.ubuntu_x86_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-config-worker.yaml"))
  }
}
