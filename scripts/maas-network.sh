#!/bin/bash
#
#   Fixe IP Adrese fuer maas-Rackserver Template

cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        ens3:
            addresses:
            - 192.168.123.8/24
            dhcp4: false
            dhcp6: false
            gateway4: 192.168.123.1
            nameservers:
                search:
                - 208.67.222.222
                - 208.67.220.22
    version: 2
EOF

sudo netplan generate
sudo netplan apply 