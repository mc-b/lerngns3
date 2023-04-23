WebShop mit LoadBalancer
========================

![](../images/webshop-loadbalancer.png)

- - -

3 x 3 VMs `customer-01 - 03`, `order-01 - 03`, `catalog-01 - 03` welche mittels der 4. VM `loadbalancer` angesprochen werden können.

Als Load Balancer kommt ein [nginx](http://nginx.org) Webserver zum Einsatz.

Die wichtigsten Einträge in der [nginx](http://nginx.org) Konfiguration sind:

    # Server Gruppen
    upstream customer {
            server customer-01;
            server customer-02;
            server customer-03;
    }  
    
    server {
        ...
        
        location /customer {
                proxy_pass      http://customer/;
        }  
    }
    
Die Einträge für `order` und `catalog` sind ähnlich.    