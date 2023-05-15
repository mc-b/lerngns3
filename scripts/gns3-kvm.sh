#!/bin/bash
#
#   Umgebungen rund um KVM und Tools
#

# Default: localhost
[ "${GNS3_SERVER}" == "" ] && { export GNS3_SERVER=localhost; }

### 
# WebVirtCloud - einfaches UI fuer KVM

export MODUL=webvirtcloud

echo -e "instance-id: kvm-${MODUL}\nlocal-hostname: kvm-${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/lerngns3/main/scripts/cloud-init-webvirtcloud.yaml >user-data

sudo mkisofs -output "/opt/gns3/images/QEMU/kvm-${MODUL}.iso" -volid cidata -joliet -rock {user-data,meta-data}
sudo rm -f "/opt/gns3/images/QEMU/kvm-${MODUL}.iso.md5sum"
    
cat <<EOF >template
{
    "cdrom_image": "kvm-${MODUL}.iso",
    "compute_id": "local",
    "default_name_format": "{name}-{0}",
    "console_type": "telnet",
    "cpus": 1,
    "ram": 2048,
    "symbol": ":/symbols/affinity/circle/green/client.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "name": "kvm-${MODUL}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "options": "--cpu host",
    "usage": "KVM Host"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"

### 
# einfache KVM Umgebung

export MODUL=host

echo -e "instance-id: kvm-${MODUL}\nlocal-hostname: kvm-${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/lerngns3/main/scripts/cloud-init-kvm.yaml >user-data

sudo mkisofs -output "/opt/gns3/images/QEMU/kvm-${MODUL}.iso" -volid cidata -joliet -rock {user-data,meta-data}
sudo rm -f "/opt/gns3/images/QEMU/kvm-${MODUL}.iso.md5sum"
    
cat <<EOF >template
{
    "cdrom_image": "kvm-${MODUL}.iso",
    "compute_id": "local",
    "default_name_format": "{name}-{0}",
    "console_type": "telnet",
    "cpus": 4,
    "ram": 8192,
    "symbol": ":/symbols/affinity/circle/green/server.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "name": "kvm-${MODUL}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "options": "--cpu host",
    "usage": "KVM Host"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"