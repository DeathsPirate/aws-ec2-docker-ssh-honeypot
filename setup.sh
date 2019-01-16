#!/bin/bash

banner()
{
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}

banner "Updating sources to include Sysdig"

curl -s https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public | apt-key add -  
curl -s -o /etc/apt/sources.list.d/draios.list https://s3.amazonaws.com/download.draios.com/stable/deb/draios.list  

banner "Updating Apt repo and getting packages"

apt-get update -y && apt-get upgrade -y
apt-get install -y linux-headers-$(uname -r) \
                   python3-pip \
                   lua5.2 \
                   liblua5.2-dev \
                   lua-cjson \
                   luarocks \
                   docker.io \
                   xinetd \
                   socat \
                   sysdig \
                   build-essential \
                   awscli

banner "Installing Python modules"
pip3 install -r ./requirements.txt

banner "Copying chisels to sysdig"
cp ./chisels/spy_logs.lua /usr/share/sysdig/chisels/spy_logs.lua
cp ./chisels/stdin.lua /usr/share/sysdig/chisels/stdin.lua
cp ./chisels/spy_users.lua /usr/share/sysdig/chisels/spy_users.lua

banner "Copying honeypot scripts"
cp ./scripts/honeypot.sh /usr/bin/honeypot
chmod 500 /usr/bin/honeypot
cp ./scripts/xinetd_honeypot /etc/xinetd.d/honeypot
cp ./scripts/honey-clean.sh /usr/local/bin/honey-clean.sh
chmod 500 /usr/local/bin/honey-clean.sh

banner "Setting Docker User Namespaces up"
cp ./scripts/daemon.json /etc/docker/daemon.json
echo -e "DOCKER_OPTS=\"--config-file=/etc/docker/daemon.json\"" | tee -a /etc/default/docker 
grep -q dockremap /etc/subuid || echo "dockremap:123000:65536" >> /etc/subuid
grep -q dockremap /etc/subgid || echo "dockremap:123000:65536" >> /etc/subgid
systemctl restart docker

banner "Building Docker Container ..."
docker build -t honeypot .

banner "Changing SSH Port to 2222"
sed -ri 's/^Port\s+.*/Port 2222/' /etc/ssh/sshd_config
service ssh restart

banner "Adding honeypot to xinetd"
grep -q honeypot /etc/services || echo "honeypot 22/tcp" >> /etc/services
service xinetd restart

banner "Install lua cjson"
luarocks install lua-cjson 2.1.0-1


banner "Configure monitoring as a service"
cp ./scripts/monitor.py /usr/local/bin/monitor.py
chmod 500 /usr/local/bin/monitor.py
cp ./scripts/failed-monitor.sh /usr/local/bin/failed-monitor.sh
chmod 500 /usr/local/bin/failed-monitor.sh
cp ./scripts/command-monitor.sh /usr/local/bin/command-monitor.sh
chmod 500 /usr/local/bin/command-monitor.sh
cp ./services/hp-monitor.service /etc/systemd/system/hp-monitor.service
chmod 664 /etc/systemd/system/hp-monitor.service
cp ./services/exec-commands-monitor.service /etc/systemd/system/exec-commands-monitor.service
chmod 664 /etc/systemd/system/exec-commands-monitor.service
cp ./services/failed-ssh-monitor.service /etc/systemd/system/failed-ssh-monitor.service
chmod 664 /etc/systemd/system/failed-ssh-monitor.service
touch /var/log/monitor.log
systemctl daemon-reload
systemctl enable hp-monitor.service
systemctl enable failed-ssh-monitor.service
systemctl enable exec-commands-monitor.service
systemctl start hp-monitor.service
systemctl start failed-ssh-monitor.service
systemctl start exec-commands-monitor.service

banner "Please check/configure AWS CLI"
aws configure

