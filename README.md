GNS3 Umgebung
=============

![](images/gns3.png)

- - - 

Graphical Network Simulator-3 ist ein Netzwerk-Software-Emulator, der erstmals 2008 veröffentlicht wurde. Er ermöglicht die Kombination von virtuellen und realen Geräten, die zur Simulation komplexer Netzwerke verwendet werden.

### Quick Start

Installiert [Git/Bash](https://git-scm.com/downloads), [Multipass](https://multipass.run/) und [Terraform](https://www.terraform.io/).

Git/Bash Kommandozeile (CLI) starten und dieses Repository clonen.

    git clone https://github.com/mc-b/gns3
    cd gns3
    
Terraform Initialisieren und VMs erstellen

    terraform init
    terraform apply
    
Terraform verwendet [Multipass](https://multipass.run/) um die VM zu erstellen.

Nach erfolgreicher Installation werden weitere Informationen für den Zugriff auf die VMs angezeigt.


Nested Virtualization
---------------------

Einige Beispiel brauchen die Möglichkeit VMs zu erstellen. Dazu ist die Nested Virtualization (VM in VM) zu aktivieren.

Bei Hyper-V sind folgende Schritte, in der PowerShell als Administrator, notwendig
* VM stoppen, z.B. mittels Hyper-V Manager oder Multipass 
* Nested Virtualization aktivieren
* VM starten und ggf. IP-Adresse überprüfen.

    multipass stop gns3-60-default
    Set-VMProcessor -VMName gns3-60-default -ExposeVirtualizationExtensions $true
    multipass start gns3-60-default
    
Einschränkungen
---------------

Hyper-V stellt keinen DHCP Server zur Verfügung. Deshalb bekommt die OpenWrt Router keine IP-Adresse zugewiesen. 

Das hat zur Folge, dass hinterliegenden VMs keine Verbindung zum Internet aufbauen können.

Abhilfe: NAT Gateway statt OpenWrt Router verwenden.