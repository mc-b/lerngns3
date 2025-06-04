GNS3 Umgebung - All-in-one
==========================

GNS3 Umgebung auf einer einzelnen Maschine, z.B. HP DL380 Gen9 mit 2 x Intel Xeon, 56 Cores, 512 KB RAM, 4 TB SSD.

Installation
------------

Zuerst muss [OpenTofu](https://opentofu.org/) (nicht terraform!) installiert werden.

Anschliessend mittels Umgebungsvariablen die MAAS Umgebung bestimmen, z.B.

    export TF_VAR_url=http://10.1.1.8:5240/MAAS
    export TF_VAR_vpn=<WireGuard VPN oder default für keines`
    export TF_VAR_key=<MAAS API Key>
    

Dieses Repository clonen und ein Workspace `maas` erstellen (legt die Cloud Umgebung fest)

    git clone https://github.com/mc-b/lerngns3
    cd lerngns3/All-in-one
    
    tofu new workspace maas
    tofu init
    tofu plan
    
Kontrollieren der Ausgabe und ggf. die Anzahl VMs in [main.tf](main.tf) anpassen.

    tofu apply --auto-approve
    
Wenn die VMs nicht mehr gebraucht werden

    tofu destroy     
    