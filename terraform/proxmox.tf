resource "proxmox_virtual_environment_download_file" "talos" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  file_name               = "talos-${var.talos_version}-nocloud-amd64.iso"
  url                     = "https://factory.talos.dev/image/${var.talos_disk_image_schematic_id}/${var.talos_version}/nocloud-amd64.raw.zst"
  decompression_algorithm = "zst"

  overwrite = true
}

resource "proxmox_virtual_environment_vm" "controller" {
  count           = var.controller_count
  name            = "talos-${var.cluster_name}-${local.controller_nodes[count.index].name}"
  node_name       = var.proxmox_pve_node_name
  tags            = sort(["terraform", "talos", "control-plane", var.cluster_name])
  vm_id           = var.cluster_node_network_first_controller_hostnum + count.index
  on_boot         = true
  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = 4
  }
  memory {
    dedicated = 6 * 1024
  }
  vga {
    type = "qxl"
  }
  network_device {
    bridge  = "vmbr0"
    vlan_id = var.cluster_node_network_vlan_id
  }
  tpm_state {
    version = "v2.0"
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = 64
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_download_file.talos.id
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${local.controller_nodes[count.index].address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    dns {
      servers = [var.cluster_node_network_gateway]
    }
  }
}

resource "proxmox_virtual_environment_vm" "worker" {
  count           = var.worker_count
  name            = "talos-${var.cluster_name}-${local.worker_nodes[count.index].name}"
  node_name       = var.proxmox_pve_node_name
  tags            = sort(["terraform", "talos", "worker", var.cluster_name])
  vm_id           = var.cluster_node_network_first_worker_hostnum + count.index
  on_boot         = true
  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = 4
  }
  memory {
    dedicated = 8 * 1024
  }
  vga {
    type = "qxl"
  }
  network_device {
    bridge  = "vmbr0"
    vlan_id = var.cluster_node_network_vlan_id
  }
  tpm_state {
    version = "v2.0"
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = 128
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_download_file.talos.id
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${local.worker_nodes[count.index].address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    dns {
      servers = [var.cluster_node_network_gateway]
    }
  }
}