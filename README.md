Docker based high interaction honeypot


INSTALL
=======

# Environment Setup


## 1. Change your ssh port from 22 to 2222(or other), and restart sshd

   vi /etc/ssh/sshd_config
  
   Port 2222
  
   restart sshd

## 2. Run the setup script to install prerequisites

   sudo ./setup.sh

## 3. Add honeypot port 22 to services

   vi /etc/services
   
   honeypot        22/tcp

## 6. Restart xinetd
   restart xinetd

# Usage

`$ ssh root@[IP/Domain Name]` default password is "password"

Type some command there, and logout.

