#!/bin/bash
#
#   Erstellt Customer, Order, Catalog Template um LoadBalancing zu zeigen
#

# Default: localhost
[ "${GNS3_SERVER}" == "" ] && { export GNS3_SERVER=localhost; }

###
#   Image holen

if  sudo [ ! -f /opt/gns3/images/QEMU/jammy-server-cloudimg-amd64.img ]
then
    echo "get Ubuntu Cloud-init Image"
    sudo apt-get install -y genisoimage
    sudo wget -O /opt/gns3/images/QEMU/jammy-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
    sudo qemu-img resize /opt/gns3/images/QEMU/jammy-server-cloudimg-amd64.img +30G
    sudo rm -f "/opt/gns3/images/QEMU/jammy-server-cloudimg-amd64.img.md5sum"
fi

### 
# Cloud-init ISO Images und Templates erzeugen

# Drei Nodes pro Type
for INSTANCE in 01 02 03 
do
    for MODUL in catalog customer order
    do
        echo -e "instance-id: ${MODUL}-${INSTANCE}\nlocal-hostname: ${MODUL}-${INSTANCE}" > meta-data
        cat <<EOF >user-data
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/ubuntu
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: 'insecure' 
ssh_pwauth: true
disable_root: false   
packages:
  - nginx
write_files:
 - content: |
    <html>
     <head>
        <title>${MODUL}</title>
     </head>        
     <body>
      <h1>${MODUL} ${INSTANCE}</h1>
     </body>
    </html>
   path: /var/www/html/index.html
   permissions: '0644' 
EOF
        sudo mkisofs -output "/opt/gns3/images/QEMU/webshop-${MODUL}-${INSTANCE}.iso" -volid cidata -joliet -rock {user-data,meta-data}
        sudo rm -f "/opt/gns3/images/QEMU/webshop-${MODUL}-${INSTANCE}.iso.md5sum"
    
        cat <<EOF >template
{
    "cdrom_image": "webshop-${MODUL}-${INSTANCE}.iso",
    "compute_id": "local",
    "default_name_format": "{name}",
    "console_type": "telnet",
    "cpus": 1,
    "ram": 512,
    "symbol": ":/symbols/affinity/circle/blue/vm.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "hda_disk_interface": "scsi",
    "name": "webshop-${MODUL}-${INSTANCE}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "usage": "Webshop ${MODUL} ${INSTANCE}"
}
EOF
        curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"
        
    done             
done

### 
# Reverse Proxy

export MODUL=reverseproxy

echo -e "instance-id: ${MODUL}\nlocal-hostname: ${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/lerngns3/main/scripts/cloud-init-${MODUL}.yaml >user-data

sudo mkisofs -output "/opt/gns3/images/QEMU/webshop-${MODUL}.iso" -volid cidata -joliet -rock {user-data,meta-data}
sudo rm -f "/opt/gns3/images/QEMU/webshop-${MODUL}.iso.md5sum"
    
cat <<EOF >template
{
    "cdrom_image": "webshop-${MODUL}.iso",
    "compute_id": "local",
    "default_name_format": "{name}",
    "console_type": "telnet",
    "cpus": 1,
    "ram": 512,
    "symbol": ":/symbols/affinity/circle/blue/tree.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "hda_disk_interface": "scsi",
    "name": "webshop-${MODUL}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "usage": "Webshop ${MODUL}"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"

### 
# Load Balancer

export MODUL=loadbalancer

echo -e "instance-id: ${MODUL}\nlocal-hostname: ${MODUL}" > meta-data
curl https://raw.githubusercontent.com/mc-b/lerngns3/main/scripts/cloud-init-${MODUL}.yaml >user-data

sudo mkisofs -output "/opt/gns3/images/QEMU/webshop-${MODUL}.iso" -volid cidata -joliet -rock {user-data,meta-data}
sudo rm -f "/opt/gns3/images/QEMU/webshop-${MODUL}.iso.md5sum"
    
cat <<EOF >template
{
    "cdrom_image": "webshop-${MODUL}.iso",
    "compute_id": "local",
    "default_name_format": "{name}",
    "console_type": "telnet",
    "cpus": 1,
    "ram": 512,
    "symbol": ":/symbols/affinity/circle/blue/loadbalancer.svg",    
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "hda_disk_interface": "scsi",
    "name": "webshop-${MODUL}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "template_type": "qemu",
    "usage": "Webshop ${MODUL}"
}
EOF
curl -X POST "http://${GNS3_SERVER}:3080/v2/templates" -d "@template"
