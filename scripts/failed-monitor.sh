#!/bin/bash

sysdig -A --unbuffered -pc -c spy_logs "container.name!=host" | tee -a /var/log/failed_attempts.log 2>&1
