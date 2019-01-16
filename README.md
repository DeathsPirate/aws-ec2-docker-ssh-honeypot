#Docker based High Interaction Honeypot


INSTALL
=======

# Environment Setup

## 1. Create a new EC2 instance

   I have fully tested this on Ubuntu 16.04 so I recommend using that as your EC2 instance.
   You will want to have a security group set up to allow port 22 and 2222 from your IP.
   After the honeypot is setup you can open port 22 to 0.0.0.0/0 to start capturing data.

## 2. Connect to EC2 instance and download this repo

   `sudo su -`
   `git clone https://github.com/DeathsPirate/aws-ec2-docker-ssh-honeypot.git`
   `cd cd aws-ec2-docker-ssh-honeypot/`

## 3. Run the setup script to install all scripts and services

   `./setup.sh`

## 4. Enter the API key and secret for the AWS account to run the honeypot under

   You should create a dedicated user to run the honeypot under. Then add that user to a dedicated group that has policy permissions to write to s3 and cloudwatch logs.  For more information on this see the accompanying blog post.

## 5. Check that the system is working.

   `ssh root@{ec2 instance IP or domain name}` default password is `password` but try a couple of wrong passwords first!
   Once you SSH in run a few commands then exit.
   SSH back into the box through the real SSH port (2222) 
   You should see there are entries in `/var/log/failed_attempts.log`, `/var/log/commands.log`, `/var/log/docker_start.log`
   If you don't check that the following services are running and haven't failed.
   `service exec-commands-monitor status`
   `service failed-ssh-monitor status`
   `service hp-monitor status`
   
# Usage

`ssh root@{ec2 instance IP or domain name}` default password is "password"

Type some command there, and logout.

