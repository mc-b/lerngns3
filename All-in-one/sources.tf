
# Define which provider to use per workspace
locals {
  module_sources = {
    multipass = "git::https://github.com/mc-b/terraform-lerncloud-multipass.git?ref=v2.0.0"
    aws       = "git::https://github.com/mc-b/terraform-lerncloud-aws.git?ref=v2.0.0"
    azure     = "git::https://github.com/mc-b/terraform-lerncloud-azure.git?ref=v2.0.0"
    gcp       = "git::https://github.com/mc-b/terraform-lerncloud-gcp.git?ref=v2.0.0"
    maas      = "git::https://github.com/mc-b/terraform-lerncloud-maas.git?ref=v2.0.0"
    lernmaas  = "git::https://github.com/mc-b/terraform-lerncloud-lernmaas.git?ref=v2.0.0"
    # fallback default
    default = "git::https://github.com/mc-b/terraform-lerncloud-multipass.git?ref=v2.0.0"
  }
}

# Determine source based on workspace
locals {
  selected_source = lookup(local.module_sources, terraform.workspace, local.module_sources["default"])
}