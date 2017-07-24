********************
Linux cheatsheet
********************

Text, text files
################

String inline replace::

 sed -i.bak 's/hello/bonjour/' greetings.txt

Network
#######

Ping with timestamp::

 ping -i 0.5 -W 0.75 www.google.cz | while read pong; do echo "$(date +%Y-%m-%d--%H:%M:%S:%N): $pong"; done
 # -i lower than 0.2 can set only super user

iptables::

 iptables -vLn -t nat     # v - verbose, L - list, n - numeric otuput, t - table selector (filter, nat, mangle, raw, security)

Disk space, usage, folders and files
####################

Check space at disk::

 df -h

Sort folders and files by size::

 du -h <path_to_folder> | sort -h

Find ten biggest files::

 find . -type f -print0 | xargs -0 du | sort -n | tail -10 | cut -f2 | xargs -I{} du -sh {}

Check if file is opened by some process::

 lsof +D <path_to_file>

Check disk's io::

 iostat -kt 1

Services
##############

Enabling service (autostart, start on boot, ...)
************************************************

The three most common init systems:
 * System V is the older init system:
  * Debian 6 and earlier
  * Ubuntu 9.04 and earlier
  * CentOS 5 and earlier
 * Upstart:
  * Ubuntu 9.10 to Ubuntu 14.10, including Ubuntu 14.04
  * CentOS 6
 * Systemd:
  * Debian 7 and Debian 8
  * Ubuntu 15.04 and newer
  * CentOS 7

System V
===================

Init script of service has to be located at */etc/init.d/*

Command to set autostart::

 update-rc.d <service_name> enable  # Debian based distros
 chkconfig <service_name> enable    # RHEL based distros

Autostart after crash::

 # add respawn line in /etc/inittab
 <id>:2345:respawn:/bin/sh /path/to/application/startup

 #example
 #ms:2345:respawn:/bin/sh /usr/bin/mysqld_safe
 #id - ms
 #2345 - run levels

Upstart
=======

Init script of service has to be located at */etc/init/<service_name>.conf*. Script should contain line *start on run level [2345]* and line *respawn* to enable respawn after crash. Be sure that there is no override file *<service-name>.overrride*.

Start and stop service::

 initctl stop service
 initctl start service

Systemd
=======

Systemd Init script of service has to be located at */etc/systemd/system/multi-user.target.wants/<service_name>.service*. Script should contain line *Restart=always* in *[Service]* section.

Command to set autostart::

 systemctl enable <service_name>.service
 systemctl daemon-reload
 systemctl restart <service_name>.service

VirtualEnv + Python PIP
#######################

::

 sudo apt install python-setuptools python-dev build-essential libffi-dev libssl-dev
 sudo easy_install pip
 sudo pip install virtualenv
 mkdir ~/.virtualenvs
 virtualenv ~/.virtualenvs/<env_name>                   # Create VirtualEnv
 source ~/.virtualenvs/<nazev-env>/bin/activate         # Switch to VirtualEnv
 pip install <package_to_install>                       # working in VirtualEnv
 source ~/.virtualenvs/<nazev-env>/bin/deactivate       # Switch from VirtualEnv

FreeIPA - IDM
##############

Unlock locked user account::

 ipa user-unlock <username>

Set user's password::

 ipa user-mod <username> --password

Add new user::

 ipa user-add --first=<first> --last=<last>  --displayname="<display_name>" --email=<e-mail> --random <login>

Add user to group::

 ipa group-add-member --users=<login> <group_name>

Delete user::

 ipa userdel <login>

Other
#####

Random string generator (e.g. password)::

  < /dev/urandom tr -dc [:alnum:] | head -c12

BYOBU / TMUX swap windows - change window position::

 swap-window -s 3 -t 1      # Window 3 swaped to window 1

Guestfish - data manipulation in qcow2 volume::

 guestfish --rw -a volume_name.qcow2
 ><fs> run
 ><fs> list-filesystems
 /dev/sda1: xfs
 ><fs> mount /dev/sda1 /
 ><fs> vi /etc/shadow
 ><fs> quit

Hash password into passwd format::

 openssl passwd -1 password

Spin virtual machine on KVM::

 virt-install --name=<vm_name> -r 8192 --disk path=<path_to_the_first_volume>,format=qcow2 --disk path=<path_to_the_second_volume>,format=qcow2 --os-type linux --os-variant rhel7.0 --network bridge=<bridge_name> --network bridge=<bridge_name> --network bridge=<bridge_name> --autostart --graphics spice --import --vcpus 4