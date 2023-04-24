#!/bin/bash
#
#   Erstellt eine MAAS Umgebung
#

### 
# MAAS Rack und Region Server

export MODUL=rackserver

echo -e "instance-id: ${MODUL}\nlocal-hostname: ${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/gns3/main/scripts/cloud-init-maas.yaml >user-data

sudo mkisofs -output "/opt/gns3/images/QEMU/maas-${MODUL}.iso" -volid cidata -joliet -rock {user-data,meta-data}
sudo rm -f "/opt/gns3/images/QEMU/maas-${MODUL}.iso.md5sum"
    
cat <<EOF >template
{
    "cdrom_image": "maas-${MODUL}.iso",
    "compute_id": "local",
    "default_name_format": "{name}",
    "console_type": "telnet",
    "cpus": 2,
    "ram": 5120,
    "symbol": ":/symbols/affinity/circle/red/server_cluster.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "name": "maas-${MODUL}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "usage": "MAAS Rack und Region Server"
}
EOF
curl -X POST "http://localhost:3080/v2/templates" -d "@template"

###
# Scratch Server (leere Maschine welche zuerst mittels Netzwerk installiert werden muss)
 
sudo qemu-img create -f qcow2 /opt/gns3/images/QEMU/scratch.qcow2 32G

cat <<EOF >template
{
    "boot_priority": "nc",
    "compute_id": "local",
    "console_type": "vnc",
    "cpus": 1,
    "default_name_format": "{name}-{0}",
    "hda_disk_image": "scratch.qcow2",
    "name": "maas-server",
    "qemu_path": "/usr/bin/qemu-system-x86_64",
    "ram": 4096,
    "symbol": ":/symbols/affinity/circle/red/server.svg",
    "template_type": "qemu",
    "usage": "Scratch Server (leere Maschine welche zuerst mittels Netzwerk installiert werden muss)"
}
EOF
curl -X POST "http://localhost:3080/v2/templates" -d "@template"    
