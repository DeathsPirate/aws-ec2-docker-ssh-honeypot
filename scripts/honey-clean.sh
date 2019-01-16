#!/bin/bash

CID=$1
EXT_IFACE=eth0
SERVICE=22

CIP=$(/usr/bin/docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CID})
REMOTE_HOST=$(/usr/bin/docker inspect --format '{{ .Name }}' ${CID} | cut -f2 -d-)
for x in $(ps aux | grep "container.name=${CID}" | awk '{print $2}'); do 
    kill -9 $x &> /dev/null ; 
done

/sbin/iptables -t nat -D PREROUTING -i ${EXT_IFACE} -s ${REMOTE_HOST} ! -p tcp --dport ${SERVICE} -j DNAT --to-destination ${CIP} &> /dev/null