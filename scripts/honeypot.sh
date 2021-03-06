#!/bin/bash

EXT_IFACE=eth0
MEM_LIMIT=128M
SERVICE=22

QUOTA_IN=5242880
QUOTA_OUT=1310720

{
    CNM="honeypot-${REMOTE_HOST}"
    HOSTNAME=$(/bin/hostname)

    # check if the container exists
    if ! /usr/bin/docker inspect "${CNM}" &> /dev/null; then
	# create new container
        CID=$(/usr/bin/docker run --name ${CNM} -h ${HOSTNAME} -e "REMOTE_HOST=${REMOTE_HOST}" -m ${MEM_LIMIT} -d -i honeypot)
	CIP=$(/usr/bin/docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CID})
        PID=$(/usr/bin/docker inspect --format '{{ .State.Pid }}' ${CID})
	
	# drop all inbound and outbound traffic by default
        /usr/bin/nsenter --target ${PID} -n /sbin/iptables -P INPUT DROP
        /usr/bin/nsenter --target ${PID} -n /sbin/iptables -P OUTPUT DROP

	# allow access to the service regardless of the quota
        /usr/bin/nsenter --target ${PID} -n /sbin/iptables -A INPUT -p tcp -m tcp --dport ${SERVICE} -j ACCEPT
        /usr/bin/nsenter --target ${PID} -n /sbin/iptables -A INPUT -m quota --quota ${QUOTA_IN} -j ACCEPT

	# allow related outbound access limited by the quota
        /usr/bin/nsenter --target ${PID} -n /sbin/iptables -A OUTPUT -p tcp --sport ${SERVICE} -m state --state ESTABLISHED,RELATED -m quota --quota ${QUOTA_OUT} -j ACCEPT

	# add iptables redirection rule
	/usr/bin/iptables -t nat -A PREROUTING -i ${EXT_IFACE} -s ${$REMOTE_HOST} ! -p tcp --dport ${SERVICE} -j DNAT --to-destination ${CIP}
	/usr/bin/iptables -t nat -A POSTROUTING -j MASQUERADE
    else
	# start container if exited and grab the cid
        /usr/bin/docker start "${CNM}" &> /dev/null
        CID=$(/usr/bin/docker inspect --format '{{ .Id }}' "${CNM}")
	CIP=$(/usr/bin/docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CID})

	# add iptables redirection rule
	/usr/bin/iptables -t nat -A PREROUTING -i ${EXT_IFACE} -s ${$REMOTE_HOST} ! -p tcp --dport ${SERVICE} -j DNAT --to-destination ${CIP}
	/usr/bin/iptables -t nat -A POSTROUTING -j MASQUERADE
    fi
} &> /dev/null

# forward traffic to the container
exec /usr/bin/socat stdin tcp:${CIP}:22,retry=60