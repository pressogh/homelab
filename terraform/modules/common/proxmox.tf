resource "proxmox_download_file" "talos" {
  for_each = { for node in var.proxmox_pve_nodes : node.name => node }

  content_type = "iso"
  datastore_id = "local"
  node_name    = each.value.name

  file_name               = "talos-${var.talos_version}-nocloud-amd64.iso"
  url                     = "https://factory.talos.dev/image/${var.talos_disk_image_schematic_id}/${var.talos_version}/nocloud-amd64.raw.zst"
  decompression_algorithm = "zst"

  # With a decompressed image, the datastore file size (.iso) never matches the
  # upstream Content-Length (.raw.zst), so overwrite=true would re-detect a size
  # change on every plan and force replacement of the file and its dependent VMs.
  # Disable the size check; the version-pinned file_name still triggers a fresh
  # download when var.talos_version changes.
  overwrite = false
}

resource "proxmox_virtual_environment_vm" "controller" {
  for_each = local.controller_nodes

  name            = "talos-${var.cluster_name}-${each.key}"
  node_name       = each.value.node
  tags            = sort(["terraform", "talos", "control-plane", var.cluster_name])
  vm_id           = each.value.vm_id
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
    file_id      = proxmox_download_file.talos[each.value.node].id
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    dns {
      servers = [var.cluster_node_network_gateway]
    }
  }
}

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = local.worker_nodes

  name            = "talos-${var.cluster_name}-${each.key}"
  node_name       = each.value.node
  tags            = sort(["terraform", "talos", "worker", var.cluster_name])
  vm_id           = each.value.vm_id
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
    dedicated = each.value.memory
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
    size         = 256
    file_format  = "raw"
    file_id      = proxmox_download_file.talos[each.value.node].id
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    dns {
      servers = [var.cluster_node_network_gateway]
    }
  }
}