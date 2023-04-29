#!/bin/bash
#
#   Holt in der TBZ vorbereitete Images und stellt diese als Templates ab
#   Es braucht einen MAAS Rackserver mit einem WebServer und den Images unter http://<Rack Server>/gns3cloudinit
#

export SERVER_IP=$(sudo cat /var/lib/cloud/instance/datasource | cut -d: -f3 | cut -d/ -f3)

RC=$(curl -w "%{http_code}" -o /dev/null -s --max-time 3 -H Metadata:true --noproxy "*" "http://${SERVER_IP}/gns3cloudinit/gns3config/gns3_controller.conf")
if [ "$RC" == "200" ]
then
    # Images holen
    #curl -sfL http://${SERVER_IP}/gns3cloudinit/gns3config/images.tar.gz | sudo tar xzvf - -C /opt/gns3/
    sudo chown -R gns3:gns3 /opt/gns3/images/
    
    # Images als Templates eintragen
    COUNT=$(curl ${SERVER_IP}/gns3cloudinit/gns3config/gns3_controller.conf | jq -r '.templates | length')
    
    counter=0
    until [ $counter -gt ${COUNT} ]
    do
      curl -sfL ${SERVER_IP}/gns3cloudinit/gns3config/gns3_controller.conf | jq --arg i ${counter} -r '.templates[$i|tonumber]' >/tmp/$$
      curl -X POST "http://localhost:3080/v2/templates" -d @/tmp/$$
      ((counter++))
    done
fi    
   