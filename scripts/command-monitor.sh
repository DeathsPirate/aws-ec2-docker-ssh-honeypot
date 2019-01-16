#!/bin/bash

sysdig -A --unbuffered -pc -c stdin -c spy_users "10 disable_color" "container.name!=host" | tee -a /var/log/commands.log 2>&1
