Lern GNS3 
=========

![](images/gns3.png)

- - - 

Graphical Network Simulator-3 ist ein Netzwerk-Software-Emulator, der erstmals 2008 veröffentlicht wurde. Er ermöglicht die Kombination von virtuellen und realen Geräten, die zur Simulation komplexer Netzwerke verwendet werden.

Das Projekt stellt die die Umgebungen von [LernMAAS](https://github.com/mc-b/lernmaas) und weitere, als Templates und [Projekte](projects/), in einer GNS3 Umgebung zur Verfügung.

Dieses Projekt basiert auf den Erfahrungen von [LernKube](https://github.com/mc-b/lernkube), [LernMAAS](https://github.com/mc-b/lernmaas) und [LernCloud](https://github.com/mc-b/lerncloud).

Quick Start
-----------

Installiert [Git/Bash](https://git-scm.com/downloads), [Multipass](https://multipass.run/) und [Terraform](https://www.terraform.io/).

Git/Bash Kommandozeile (CLI) starten und dieses Repository clonen.

    git clone https://github.com/mc-b/gns3
    cd gns3
    
Terraform Initialisieren und VMs erstellen

    terraform init
    terraform apply
    
Terraform verwendet [Multipass](https://multipass.run/) um die VM zu erstellen.

Nach erfolgreicher Installation werden weitere Informationen für den Zugriff auf die VMs angezeigt.

Nach der Installation sollte überprüft werden, ob die Virtualisierung aktiviert ist:    

    sudo virt-host-validate qemu
    
Wenn der erste Eintrag `FAIL` anzeigt ist *Nested Virtualization* zu aktivieren oder die KVM Unterstützung zu deaktivieren. Dazu die Konfigurationsdatei `/opt/gns3/.config/GNS3/2.2/gns3_server.conf` um folgenden Eintrag ergänzen:

    [Qemu]
    enable_kvm = false
    
Als nächstes eines der vorbereiteten [Projekte](projects/) importieren -> File -> Import portable project".    

Templates in [TBZ GNS3 Umgebung](https://gitlab.com/ch-tbz-it/Stud/allgemein/tbzcloud-gns3) integrieren
-------------------------------------------------

Ab Zeile 15 (Ubuntu Image hole) des Installationsscripts [install.sh](scripts/install.sh) bis max. Zeile 52 (ohne Netzwerk) manuell ausführen.

Dafür ist vorher `localhost` durch `192.168.23.1` zu ersetzen:

    for repo in lerngns3 lernmaas
    do
        git clone https://github.com/mc-b/${repo}
        cd ${repo}/scripts
        for script in gns3*.sh
        do
            sed -i -e 's/localhost/192.168.23.1/g' ${script};
            bash -x ${script}
        done
    done   
         
OpenWrt Image holen und weitere Templates `Ubuntu Server`, `webterm` und `chromium` anlegen.

    # OpenWrt Image holen und aufbereiten
    sudo wget -O /opt/gns3/images/QEMU/openwrt-22.03.0-x86-64-generic-ext4-combined.img.gz https://downloads.openwrt.org/releases/22.03.0/targets/x86/64/openwrt-22.03.0-x86-64-generic-ext4-combined.img.gz
    sudo gunzip /opt/gns3/images/QEMU/openwrt-22.03.0-x86-64-generic-ext4-combined.img.gz
    
    # Standard Templates anlegen
    curl -X POST "http://192.168.23.1:3080/v2/templates" -d '{"name": "Ubuntu-22", "compute_id": "local", "qemu_path": "/usr/bin/qemu-system-x86_64", "hda_disk_image": "jammy-server-cloudimg-amd64.img", "symbol": ":/symbols/affinity/circle/gray/vm.svg", "ram": 2048, "template_type": "qemu"}' 
    curl -X POST "http://192.168.23.1:3080/v2/templates" -d '{ "category": "guest", "compute_id": "local", "console_type": "vnc", "image": "gns3/webterm", "name": "webterm", "symbol": ":/symbols/affinity/circle/gray/client.svg", "template_type": "docker" }'
    curl -X POST "http://192.168.23.1:3080/v2/templates" -d '{ "category": "guest", "compute_id": "local", "console_type": "vnc", "image": "jess/chromium", "name": "chromium", "symbol": ":/symbols/affinity/circle/gray/client.svg", "template_type": "docker" }'
    
Die OpenVPN Verbindung, kann über WireGuard verwendet werden. Dazu zuerst Konfiguration von Host im Verzeichnis `/opt/cloudinitinstall/<Hostname>.ovpn` holen und `<connection>` anpassen

    <connection>
    remote <WireGuard IP-Adresse> 1194 tcp4
    </connection>    

Weil das `192.168.23.1` keine Internet Verbindungen zulässt, in den [Projekten](projects/) `Cloud` durch `NAT` Device ersetzen.

Nested Virtualization
---------------------

Einige Beispiel brauchen die Möglichkeit VMs zu erstellen. Dazu ist die Nested Virtualization (VM in VM) zu aktivieren.

Bei Hyper-V sind folgende Schritte, in der PowerShell als Administrator, notwendig
* VM stoppen, z.B. mittels Hyper-V Manager oder Multipass 
* Nested Virtualization aktivieren
* VM starten und ggf. IP-Adresse überprüfen.

Die Befehle sind wie folgt: 

    multipass stop gns3-60-default
    Set-VMProcessor -VMName gns3-60-default -ExposeVirtualizationExtensions $true
    multipass start gns3-60-default
    
Einschränkungen
---------------

Ein Teil der Infrastrukturen (Multipass mit Hyper-V, AWS), erlaubt es nicht das der OpenWrt Router eine IP-Adresse bezieht.

Das hat zur Folge, dass hinterliegenden VMs keine Verbindung zum Internet aufbauen können.

Abhilfe: NAT Gateway statt Cloud und OpenWrt Router verwenden.

Links
-----

* [Multipass Bridge Network](https://multipass.run/docs/create-an-instance#heading--bridging)
* [Bridged networking on Ubuntu Server with systemd-networkd instead network-manager?](https://discourse.ubuntu.com/t/bridged-networking-on-ubuntu-server-with-systemd-networkd-instead-network-manager/30235)
* [Ubuntu 22.04 bridging with netplan doesn't work](https://askubuntu.com/questions/1416713/ubuntu-22-04-bridging-with-netplan-doesnt-work)
* [How to install GNS3-Server on Ubuntu 20.04](https://securitynetworkinglinux.wordpress.com/2021/01/13/how-to-install-gns3-server-on-ubuntu-20-04/)
* [Install GNS3 on a remote server](https://docs.gns3.com/docs/getting-started/installation/remote-server/)
* [Settings profiles](https://docs.gns3.com/docs/using-gns3/advanced/settings-profiles/)
* [GNS3 Server Doku](https://gns3-server.readthedocs.io/en/stable/index.html)
* [TianoCore Bios](https://www.tianocore.org/)
