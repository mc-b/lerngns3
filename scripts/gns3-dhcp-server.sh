#!/bin/bash
#
#   Installiert einen DHCP Server in einem eigene Subnetz auf br0.
#

trap '' 1 3 9

DEBIAN_FRONTEND=noninteractive sudo apt-get install -y isc-dhcp-server bridge-utils
sudo brctl addbr br0

cat <<EOF | sudo tee /etc/netplan/60-bridge-br0.yaml
# network: {config: disabled}
network:
    ethernets:
        br0:
            dhcp4: false
            dhcp6: false
            addresses:
            - 192.168.23.1/24
            match:
              driver: bridge
            mtu: 1500
    version: 2
EOF

echo "Disable iptables for bridge"
# sysctl -w net.bridge.bridge-nf-call-iptables=0
# This is not really working
cat <<EOFCTL | sudo tee /etc/sysctl.d/10-no-bridge-nf-call.conf
# So that Client To Client Communication works
net.bridge.bridge-nf-call-iptables=0

EOFCTL

echo "...fix ufw too"

cat <<EOFUFW | sudo tee -a /etc/ufw/sysctl.conf

net/bridge/bridge-nf-call-ip6tables = 0
net/bridge/bridge-nf-call-iptables = 0
net/bridge/bridge-nf-call-arptables = 0

EOFUFW

echo "...add it to sysctl.conf"

cat <<EOFSYS | sudo tee -a /etc/sysctl.conf
# So that Client To Client Communication works
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0

EOFSYS

echo "...add service to reload sysctl after boot"

# This actually works
cat <<EOFCTL | sudo tee /opt/sysctl-reload.service
[Unit]
Description=sysctl reload
Requires=multi-user.target
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/sysctl -p

[Install]
WantedBy=multi-user.target

EOFCTL

### DHCP Server

cat <<EOFDHCP | sudo tee /etc/dhcp/dhcpd.conf
option domain-name "$(hostname).local";

default-lease-time 600;
max-lease-time 7200;

subnet 192.168.23.0 netmask 255.255.255.0 {
 range 192.168.23.129 192.168.23.200;
 option domain-name-servers 8.8.8.8;
 option domain-name "$(hostname).local";
}
EOFDHCP

sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="br0"/g' /etc/default/isc-dhcp-server
sudo systemctl restart isc-dhcp-server

