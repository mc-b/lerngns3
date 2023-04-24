Kubernetes Cluster
==================

![](../images/microk8s-cluster.png)

- - - 

Kubernetes Cluster basierend auf [microk8s](https://microk8s.io).

Port (Range) forward
--------------------

    cat <<EOF | sudo tee /etc/nginx/sites-enabled/microk8s
    server {
            listen 31250-31350 default_server;
            location / {
                    resolver    10.0.46.248;
                    proxy_pass  http://microk8s-01-master:\$server_port;
            }
    }
    server {
            listen 32000-32200 default_server;
            location / {
                    resolver    10.0.46.248;
                    proxy_pass  http://microk8s-01-master:\$server_port;
            }
    }
    server {
            listen 8443 default_server;
            location / {
                    resolver    10.0.46.248;
                    proxy_pass  https://microk8s-01-master:\$server_port;
            }
    }
    EOF
    
    sudo systemctl restart nginx

