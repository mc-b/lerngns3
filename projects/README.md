GNS3 Projekte
=============

* [Router Bridge-Modus](router-bridget.md)
* [Router WireGuard](router-wireguard.md)
* [WebShop mit Reverse Proxy](webshop-reverseproxy.md)
* [WebShop mit LoadBalancer](webshop-loadbalancer.md)
* [Kubernetes Cluster](microk8s-cluster.md)
* [MAAS Metal as a Service](maas.md)
* [Docker und Kubernetes (DUK)](duk.md)
* [DevOps Engineering Practices & Tools (CDI)](cdi.md)

Allgemeines
-----------

![](../images/router.png)

- - -

Alle Projekte beinhalten einen [OpenWrt Router](https://openwrt.org/) und eine einfach Chrome Browser Oberfläche.

Beim Router ist Ethernet0 der LAN link (Netzwerk 192.168.123.0/24), Ethernet1 der WAN link (DHCP-Client).

Routing
-------

Um das Routing zu vereinfachen hat der Router immer die gleiche MAC Adresse: "0c:96:5c:0f:00:00".

**Windows (als Administrator)** - 

    route add 192.168.123.0 mask 255.255.255.0 192.168.1.31
    
**Linux**

    ip route add 192.168.123.0/24 via 192.168.1.31 dev br0

Die IP-Adresse `192.168.1.31` ist durch die IP des Router zu ersetzen.

Port (Range) forward
--------------------

Geht am einfachsten mittels nginx. 

Einzelner Port, hier MAAS.io und OpenWrt, weiterleiten.

    cat <<EOF | sudo tee /etc/nginx/sites-enabled/maas
    server {
        listen 5240 default_server;
        location / {
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";          
            proxy_pass http://192.168.123.8:5240/;
        }
    }
    EOF
    
    cat <<EOF | sudo tee /etc/nginx/sites-enabled/openwrt
    server {
        listen 8080 default_server;
        location / {
            proxy_pass http://192.168.123.1:80/;
        }
    }
    EOF
    
    sudo systemctl restart nginx
        
Mehrere Ports weiterleiten, z.B. für Kubernetes        

    cat <<EOF | sudo tee /etc/nginx/sites-enabled/microk8s
    # Kubernetes Port Mapping
    server {
            listen 32000-32100 default_server;
            location / {
                    proxy_pass http://192.168.123.169:$server_port;
            }
    }
    # Kubernetes Dashboard
    server {
            listen 8443 default_server;
            location / {
                    proxy_redirect      off;
                    proxy_set_header    X-Real-IP $remote_addr;
                    proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header    Host $http_host;
                    proxy_pass https://192.168.123.169:8443/;
            }
    }
    EOF
    
    sudo systemctl restart nginx
    
Die IP Adresse `192.168.123.169` ist durch die IP des Kubernetes Master auszuwechseln.

In Microk8s Master wechseln und zum Testen Container starten

    kubectl run hello-world --image registry.gitlab.com/mc-b/misegr/hello-world --restart=Never 
    kubectl expose pod/hello-world --type="LoadBalancer" --port 80
    kubectl get all

### Links    

* [Nginx LB Doku](https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/)
* [What Is Nginx Load Balancing?](https://cloudinfrastructureservices.co.uk/nginx-load-balancing/)
* [Nginx Proxy a large port range to equivalent port on a different ip address](https://serverfault.com/questions/279262/nginx-proxy-a-large-port-range-to-equivalent-port-on-a-different-ip-address)
