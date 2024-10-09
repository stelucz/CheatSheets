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

Jumping, tunneling
##################

ssh port forwarding::

 ssh -L 8080:localhost:80 user@host

ssh port forwarding with jump host::
 ssh -J jump -L <local-port>:<dst-ip>:<dst-port> <dst-host>

Socks proxy::

 ssh -g -N -D 3128 user@host

Set system to use socks proxy for http/s::

 export http_proxy="socks5://localhost:3128"
 export https_proxy="socks5://localhost:3128"

Set git http/s to use socks proxy::

 git config --global http.proxy socks5://localhost:3128
 git config --global https.proxy socks5://localhost:3128

Set git ssh to use socks proxy, create `.ssh/config` host::

 Host <git repository url/server>
 HostName <git repository url/server>
 User git
 ProxyCommand nc -v -x 127.0.0.1:3128 %h %p

This will forward all git ssh operations for defined hostname through socks proxy.

ssh config to utilize host as jump::

 Host jump
 HostName jump.example.com
 User user
 ForwardAgent yes

 Host target
 HostName target.example.com
 User user
 ForwardAgent yes
 ProxyJump jump

sshuttle::

 # sshuttle -r <host> <subnet> -x <excluded_subnet>
 sshuttle -r host 0/0 -x 10.0.0.0/8 -x 192.168.0.0/16 -x 172.16.0.0/18
 # kill sshuttle when in daemon mode
 kill -9 $(cat sshuttle.pid) && rm sshuttle.pid


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

Status of IPA service::

 ipactl status

KVM, qemu, virsh
#################

Spin virtual machine on KVM::

 virt-install --name=<vm_name> -r 8192 --disk path=<path_to_the_first_volume>,format=qcow2 --disk path=<path_to_the_second_volume>,format=qcow2 --os-type linux --os-variant rhel7.0 --network bridge=<bridge_name> --network bridge=<bridge_name> --network bridge=<bridge_name> --autostart --graphics spice --import --vcpus 4

Convert volume::

 qemu-img convert -f qcow2 -O raw <src_volume>.qcow2 <dst_volume>.raw    # -f input format, -O output format

Resize volume::

 qemu-img resize <volume_name> +10G

Ceph
#####

Cluster status::

 ceph -s
 ceph -w
 ceph health detail

Tree of OSDs::

 ceph osd tree

Stopping without rebalancing::

 # before maintenance
 ceph osd set noout
 # after maintenance
 ceph osd unset noout

Stop and start osd daemon::

 /etc/init.d/ceph stop osd.<osd-id>
 /etc/init.d/ceph start osd.<osd-id>

Slowdown recovery::

 ceph tell osd.* injectargs '--osd-max-backfills 1'
 ceph tell osd.* injectargs '--osd-recovery-max-active 1'
 ceph tell osd.* injectargs '--osd-recovery-op-priority 1'

RabbitMQ
########

Status::

  rabbitmqctl status

Cluster status::

  rabbitmqctl cluster_status

Rejoin cluster process if node left it (crash,redeploy etc)::

  # At some active node in cluster
  rabbitmqctl forget_cluster_node rabbit@<notincluster_node_name>
  # At node which should be added to cluster
  rabbitmqctl stop_app
  rabbitmqctl join_cluster rabbit@<active_node_name>

Other
#####

Kernel patching::

 patching:
 apt-get update
 apt-get install linux-image-<version>
 apt-get install linux-image-extra-<version>
 apt-get install linux-headers-<version>

 reboot

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

VirtualBox serial port in Windows::

 # in Settings, tab serial ports:
 # enable serial port, select host pipe, unselect connect to existing pipe
 # Port/File path: \\.\pipe\COM1
 # OK
