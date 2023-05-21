KVM Umgebung mit WebVirtCloud
=============================

![](../images/kvm-webvirtcloud.png)

- - -

Die Umgebung besteht aus einer VM mit WebVirtCloud und drei KVM-Hosts.

WebVirtCloud stellt ein Web GUI zur Verfügung, mittels diesem auf den KMV-Hosts VMs erstellt werden können.

WebVirtCloud
------------

WebVirtCloud besitzt eine Weboberfläche welche mittels `http://<ip vm>` erreichbar ist.

Anmelden mit User und Password `admin`.

Dannach als erstes -> Admin -> Profile -> Name, Mail setzen und Password ändern! Wird das Password nicht geändert, können undefinierte Fehler auftreten.

**Compute (KVM-Host) einbinden**

![](../images/kvm-add-compute.png)

- - -

Dazu ist der SSH-Key vom User `www-data` von der `webvirtcloud` VM auf die jeweiligen `KVM-Hosts` zu kopieren.

    sudo -u www-data ssh-copy-id virsh@kvm-host
    
Password: `insecure`. Evtl. Warning können ignoriert werden.

Dannach über die Weboberfläche -> Compute -> SSH die KVM-Host einbinden. Mit den anderen Protokollen konnte keine Verbindung hergestellt werden.    

### Erste VM erstellen


![](../images/kvm-add-instance.png)

- - -

Instance (VM) durch drücken von '+' erstellen.

![](../images/kvm-instance-disk.png)

- - -

Nach dem Erstellen Disk `ubuntu-server-22.img` zuweisen und CD-ROM `cloud-init-template.iso` mounten.

![](../images/kvm-instance-network.png)

- - -

Soll die VM im Netzwerk von Router sichtbar sind ist als Network Interface `br0` einzustellen.

### Weitere VMs erstellen

Weitere Images können entweder
* mittels der Installations CD-ROM der entsprechenden Betriebsysteme erstellt werden
* von bestehenden Images, z.B. `jammy-server-cloudimg-amd64.img` Image abgeleitet werden.

Dazu ist der Tab `Template` statt `Custom` zu verwenden.

Das `jammy-server-cloudimg-amd64.img` Image braucht noch ein Cloud-init CD-ROM, siehe unten. Ansonsten ist kein Login möglich.

Dieses kann, nach der Erstellung der VM, unter `Settings` -> `Disks` gemountet werden.

KVM-Hosts
---------

Alle VMs anzeigen

    virsh list --all
    
Auf die Console der VM wechseln, beenden mittels `Ctrl+AltGR+]`

    virsh console <vm-name>    
    
VM stoppen und entfernen

    virsh destroy <vm-name>
    virsh undefine <vm-name>
    
### Weitere VMs erstellen

Weitere Images können entweder mittels den normalen Installation CD-ROM der entsprechnenden Betriebsysteme erstellt werden, oder mittels Cloud-init.

Bei Cloud-init ist zuerst ein neuer Disk, abgeleitet von `jammy-server-cloudimg-amd64.img`, zu erstellen:

    sudo qemu-img create -b /vmdisks/jammy-server-cloudimg-amd64.img -f qcow2 -F qcow2 /vmdisks/ubuntu-server-22.04.img 30G
    
Dann ein CD-ROM Image mit den Meta Informationen (`meta-data`) und dem Cloud-init Script (`user-data`).

    echo -e "instance-id: my-server\nlocal-hostname: my-server" > meta-data
    cat <<EOF >user-data
    #cloud-config
    password: insecure
    chpasswd: { expire: False }
    ssh_pwauth: true
    disable_root: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    EOF
    sudo genisoimage -output /vmdisks/my-cloud-init.iso -V cidata -r -J user-data meta-data 

Und zum Schluss kann die VM gestartet werden

    virt-install --name=my-vm --ram=2048 --vcpus=1 --import --disk path=/vmdisks/my-ubuntu-server-22.04.img,format=qcow2 \
                 --disk path=/vmdisks/my-cloud-init.iso,device=cdrom --os-variant=ubuntu22.04 --network bridge=br0,model=virtio \
                 --graphics vnc,listen=0.0.0.0 --noautoconsole 

Statt dem Eintrag `--network bridge=br0` kann, dass automatisch erstellte KVM Network `virbr0`, umkonfiguriert werden. Dazu ist `virbr0`  zu löschen und dann als [host bridge](https://libvirt.org/formatnetwork.html#using-an-existing-host-bridge) wieder zu erstellen:

    sudo virsh net-destroy default
    sudo virsh net-undefine default
    cat <<EOF >/tmp/$$
    <network>
      <name>default</name>
      <forward mode="bridge"/>
      <bridge name="br0"/>
    </network>
    EOF
    sudo virsh net-define /tmp/$$
    sudo virsh net-start default
    sudo virsh net-autostart default 
    
Dann verwenden die VMs, auf den KVM-Hosts, automatisch das Netzwerk vom Router, statt ein internes KVM-Host Netzwerk.

Kontrollieren mittels

    virsh net-list --all
    virsh net-dumpxml default
    
Siehe auch Script [kvm.sh](https://raw.githubusercontent.com/mc-b/lerncloud/main/services/kvm.sh).

### Weitere Netzwerke einrichten

Manchmal kann es von Vorteil sein, nicht alle VMs im gleichen Netzwerk zu erstellen. Dazu bietet `virsh` verschiedene [Optionen](https://libvirt.org/formatnetwork.html).

Ein interessante Variante ist `Routed network config`. Dabei werden die VMs in ein separates Netzwerk (Tab `Settings` -> `Network`) verschoben und sind dann mittels [Routing](README.md#routing) erreichbar.

**Netzwerk ohne DHCP Server**, z.B. wenn dies von einer VM mit DHCP-Server bereitgestellt wird.

    cat <<EOF >maas.xml
    <network connections='1'>
    <name>maas</name>
    <domain name="maas.mc-b.ch"/>
    <dns>
      <forwarder addr="208.67.222.222"/>
      <forwarder addr="208.67.220.22"/>
    </dns>  
      <forward mode='route'/>
      <bridge name='virbr4' stp='on' delay='0'/>
      <ip address='192.168.124.1' netmask='255.255.255.0'>
      </ip>
    </network>
    EOF
    
    virsh net-define maas.xml
    virsh net-autostart maas
    virsh net-start maas
    
    # Masquerade vom internen Netz nach aussen, ansonsten kommen die VMs nicht ins Internet.
    sudo iptables -t nat -A POSTROUTING -s 192.168.124.0/24 -j MASQUERADE
    
Wird eine neue VM erstellt ist als Netzwerk `maas` anzugeben.    
    
**Weiteres Netzwerk mit DHCP**
    
    cat <<EOF >example.xml
    <network connections='1'>
    <name>example</name>
    <domain name="example.mc-b.ch"/>
    <dns>
      <forwarder addr="208.67.222.222"/>
      <forwarder addr="208.67.220.22"/>
    </dns>  
      <forward mode='route'/>
      <bridge name='virbr5' stp='on' delay='0'/>
      <ip address='192.168.125.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.125.20' end='192.168.125.120'/>
        </dhcp>
      </ip>
    </network>
    EOF
    
    virsh net-define example.xml
    virsh net-autostart example
    virsh net-start example    
    
    # Masquerade vom internen Netz nach aussen, ansonsten kommen die VMs nicht ins Internet.
    sudo iptables -t nat -A POSTROUTING -s 192.168.125.0/24 -j MASQUERADE  
    
Wird eine neue VM erstellt ist als Netzwerk `example` anzugeben.    

**IP-Rules Persistieren**

    sudo apt-get install -y iptables-persistent
    
    cat <<EOF | sudo tee /etc/iptables/rules.v4
    *nat
    -A POSTROUTING -s 192.168.124.0/24 -j MASQUERADE
    -A POSTROUTING -s 192.168.125.0/24 -j MASQUERADE
    COMMIT
    EOF 

### Import Templates von [TBZ GNS3 Umgebung](https://gitlab.com/ch-tbz-it/Stud/allgemein/tbzcloud-gns3)   

Dazu müssen die Templates z.B. auf einem Rackserver verfügbar sein.

Verzeichnis vom Rackserver mounten

    sudo -i
    mkdir -p /vmdisks/templates
    mount -t nfs <rackserver>:/data/templates /vmdisks/templates
    
CD-ROM Images verlinken

    for file in templates/gns3/images/QEMU/*.iso
    do 
        echo $file
        b=$(basename $file)
        ln -s $file $b
    done


Installierte VMs RW-Disk erzeugen

    for file in templates/gns3/images/QEMU/*.img 
    do
        echo $file
        b=$(basename ${file})
        qemu-img create -b ${file} -f qcow2 -F qcow2 ${b}.img 30G
    done
    
VMWare Disks müssen kopiert werden

    for file in templates/gns3/images/QEMU/*.vmdk 
    do
        echo $file
        cp $file .
    done   
    
  
Troubleshooting
---------------

VM bootet nicht.

* evtl. wurde der Download des Ubuntu-Images nicht sauber abgeschlossen. 
* Image frisch downloaden: 

Links
-----

* [GitHub](https://github.com/retspen/webvirtcloud)
* [Install WebVirtCloud KVM Web Dashboard on Ubuntu 20.04](https://techviewleo.com/install-webvirtcloud-kvm-web-dashboard-on-ubuntu/)
* [Default Password Issue](https://github.com/retspen/webvirtcloud/issues/2)    
* [Network XML format](https://libvirt.org/formatnetwork.html)
* [How to use bridged networking with libvirt and KVM](https://linuxconfig-org.translate.goog/how-to-use-bridged-networking-with-libvirt-and-kvm?_x_tr_sl=en&_x_tr_tl=de&_x_tr_hl=de&_x_tr_pto=sc)
* [Create and Configure Bridge Networking For KVM in Linux](https://computingforgeeks.com/how-to-create-and-configure-bridge-networking-for-kvm-in-linux/)
* [KVM Virtual Networking Concepts](https://kb.novaordis.com/index.php/KVM_Virtual_Networking_Concepts)
* [Creating a VM using Libvirt, Cloud Image and Cloud-Init](https://sumit-ghosh.com/posts/create-vm-using-libvirt-cloud-images-cloud-init/)
* [iptables](https://www.linux-community.de/ausgaben/linuxuser/2013/02/iptables-grundlagen-fuer-desktop-nutzer/2/)
