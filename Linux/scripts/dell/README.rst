*************************************
Scripts for Dell servers
*************************************


change-password.sh
####################

Script will access iDrac of server and change root (user id 2) password in loop by *idracadm7* utility. Servers have to be in continuous block of IP addresses.

Usage::

 change-password.sh <username> <password> <subnet-prefix> <start-host> <end-host> <new-password>
    <username>        - username for remote login
    <password>        - user's password
    <subnet-prefix>   - subnet prefix - continuous block of servers
    <start-host>      - last octet number of first server
    <end-host>        - last octet number of last server
    <new-password>    - new password of root user

example::

 change-password.sh root mydankpass 192.168.0. 10 15 newpass

Script will loop following command *idracadm7 -r <subnet-prefix>$I -u <username> -p <password> set iDRAC.Users.2.Password "<new-password>"*. In used example following commands would be executed::

 idracadm7 -r 192.168.0.10 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
 idracadm7 -r 192.168.0.11 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
 idracadm7 -r 192.168.0.12 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
 idracadm7 -r 192.168.0.13 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
 idracadm7 -r 192.168.0.14 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
 idracadm7 -r 192.168.0.15 -u root -p mydankpass set iDRAC.Users.2.Password "newpass"
