#!/bin/bash

if [ "$#" -ne 6 ]
then
  echo "Usage: "
  echo "change-password.sh <username> <password> <subnet-prefix> <start-host> <end-host> <new-password>"
  echo "    <username>        - username for remote login"
  echo "    <password>        - user's password"
  echo "    <subnet-prefix>   - subnet prefix - continuous block of servers"
  echo "    <start-host>      - last octet number of first server"
  echo "    <end-host>        - last octet number of last server"
  echo "    <new-password>    - new password of root user"
  echo "Example: "
  echo "    change-password.sh root mydankpass 192.168.0. 10 15 newpass"
  echo "Executed command by script: "
  echo "    idracadm7 -r <subnet-prefix><host> -u <username> -p <password> set iDRAC.Users.2.Password \"<new-password>\""
  exit 1
fi

if [ -n ${1+x} ] && [ -n ${2+x} ] && [ -n ${3+x} ] && [ -n ${4+x} ] && [ -n ${5+x} ] && [ -n ${6+x} ]; then
  for I in $(seq $4 $5); do
     echo "idracadm7 -r ${3}${I} -u ${1} -p ${2} set iDRAC.Users.2.Password \"${6}\""
     idracadm7 -r $3$I -u $1 -p $2 set iDRAC.Users.2.Password "$6"
  done

fi
