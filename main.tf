###
#   GNS3 Umgebung
#

module "master" {

  #source     = "./terraform-lerncloud-module"
  source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-lernmaas"  
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure" 
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-proxmox"    

  module      = "gns3-${var.host_no}-${terraform.workspace}"
  description = "Graphical Network Simulator-3 - Netzwerk-Software-Emulator,"
  userdata    = "cloud-init-gns3.yaml"

  cores   = 2
  memory  = 16
  storage = 64
  # SSH, GNS3 Web UI
  ports      = [ 22, 3080 ]

  # MAAS Server Access Info
  url = var.url
  key = var.key
  vpn = var.vpn
}



