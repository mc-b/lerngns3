Metal as a Service
------------------

![](../images/maas.png)

- - -

Metal as a Service Umgebung basierend auf [MAAS.io](https://maas.io).

Siehe auch Projekt [LernMAAS](https://github.com/mc-b/lernmaas).

Port (Range) forward
--------------------

MAAS.io braucht ein paar spezielle Einträge im HTTP-Header:

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
    
    sudo systemctl restart nginx
    
Die IP-Adresse `192.168.123.8` sollte fix sein, wenn der Rack Server korrekt installiert wurde.        