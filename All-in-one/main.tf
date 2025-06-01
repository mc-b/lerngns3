# 45x Development VMs
module "vms" {
  source = local.selected_source

  machines = {
    for i in range(1, 46) : 
    format("gns3-%02d-m145", i+1) => {
      hostname = format("gns3-%02d-m145", i+1)
      userdata = templatefile("${path.root}/cloud-init-m145.yaml", {})
    }
  }

  description = "GNS3/M145"
  memory      = 8
  cores       = 4
  storage     = 64

  ports = [22, 80, 3080]

  url = var.url
  key = var.key
  vpn = var.vpn
}
