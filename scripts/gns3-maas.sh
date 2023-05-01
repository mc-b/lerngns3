#!/bin/bash
#
#   Erstellt eine MAAS Umgebung
#

# Default: localhost
[ "${GNS3_SERVER}" == "" ] && { export GNS3_SERVER=localhost; }

### 
# MAAS Rack und Region Server

export MODUL=rackserver

echo -e "instance-id: ${MODUL}\nlocal-hostname: ${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/lerngns3/main/scripts/cloud-init-maas.yaml >user-data

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
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"

###
# Scratch Server (leere Maschine welche zuerst mittels Netzwerk installiert werden muss) mit Nested virtualization
 
sudo qemu-img create -f qcow2 /opt/gns3/images/QEMU/scratch.qcow2 32G

cat <<EOF >template
{
    "boot_priority": "nc",
    "compute_id": "local",
    "console_type": "vnc",
    "cpus": 4,
    "default_name_format": "{name}-{0}",
    "hda_disk_image": "scratch.qcow2",
    "name": "maas-server",
    "qemu_path": "/usr/bin/qemu-system-x86_64",
    "ram": 8192,
    "symbol": ":/symbols/affinity/circle/red/server.svg",
    "template_type": "qemu",
    "options": "--cpu host",
    "usage": "Scratch Server (leere Maschine welche zuerst mittels Netzwerk installiert werden muss). Mit aktivierter Nested virtualization (VM in VM)"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"    

###
# Scratch VM (leere Maschine welche zuerst mittels Netzwerk installiert werden muss)
 
cat <<EOF >template
{
    "boot_priority": "nc",
    "compute_id": "local",
    "console_type": "vnc",
    "cpus": 1,
    "default_name_format": "{name}-{0}",
    "hda_disk_image": "scratch.qcow2",
    "name": "maas-vm",
    "qemu_path": "/usr/bin/qemu-system-x86_64",
    "ram": 2048,
    "symbol": ":/symbols/affinity/circle/red/vm.svg",
    "template_type": "qemu",
    "usage": "Scratch VM (leere VM welche zuerst mittels Netzwerk installiert werden muss). Ideal um Cloud-init mit MAAS zu demonstrieren"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"  
