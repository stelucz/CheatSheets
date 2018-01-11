***********************************
OpenStack cheatsheet and ops guide
***********************************

Post creation script / customization script
###########################################

There are two ways how to customize instance at launch. The first one is to use *cloud-config* script. Following example script will change default user's password and run bash command::

 #cloud-config
 password: pass
 chpasswd: { expire: False }
 ssh_pwauth: True
 runcmd:
  - dhclient -6 ens3

The second way is to supply bash script. Example script will change password of user *ubuntu*, bring IPv6 at interfaces and add IPv6 default route::
  #!/bin/bash
  echo "ubuntu:ubuntu"|chpasswd
  dhclient -6


Logs
####

Locations::

 /var/log/nova
 /var/log/neutron
 /var/log/keystone
 /var/log/heat
 /var/log/cinder
 /var/log/glance

structure of logged request::

 req-<req-id> <user-id> <project-id>

 # example
 :2017-08-14 08:34:50.490 2344 INFO nova.api.openstack.wsgi [req-d33428f2-1b32-4a6f-8ebc-6516ac2adfdb b13d607582e4472a894221d2de070c36 2300a45880554db5bfeb13675d724d2b - default default] HTTP exception thrown: Flavor t1-basic-1-1 could not be found.

Images - Glance
###############

Upload image::

  glance image-create --name Ubuntu-server-16.04 --disk-format raw --container-format bare --visibility shared --file Ubuntu-server-16.04.raw --progress
  # or
  openstack image create --file ubuntu.raw ubuntu
  # default values: container-format raw; disk-format raw; private;

Image sharing across projects::

  glance member-create <image_id_to_share> <dest_project_id>
  glance member-update <image_id_to_share> <dest_project_id> accepted

Nova
####

List status of nova services::

  nova service-list

Disabling service::

  nova service-disable --reason "Reason text" <hostname> <service_binary>

List of nova hypervisors::

  nova hypervisor-list

Migrating / Evacuating instances
*********************************

An evacuation of an instance is done (and indeed only allowed) if the compute host that the instance is running on is marked as down. That means the failure has already happened.

Live migration is what it sounds like, and what most people think of when they hear the term: moving the instance from one host to another without the instance noticing (or needing to be powered off).

Description of evacuation and migration taken from `danplanet <http://www.danplanet.com/blog/2016/03/03/evacuate-in-nova-one-command-to-confuse-us-all/>`_.

Before migrating instances, check if no instance is undergoing resize procedure or waiting in *RESIZE_VERIFY* state.

A little downtime (aprox. 1s) is present while live migration is undergoing.

List instances at hypervisor::

  nova hypervisor-servers <hypervisor_name>

Live migration of running VMs (a bit confusing command name)::

  nova host-evacuate-live <hypervisor_name>
  # description from CLI: Live migrate all instances of the specified

Migration of shutdown VMs::

  nova host-servers-migrate <hypervisor_name>
  # description from CLI: Cold migrate all instances off the specified

Evacuation of single instance from hypervisor::

  nova evacuate <instance_id_or_name>

Evacuation of hypervisor::

  nova host-evacuate <hypervisor_name>

Keep in mind, that evacuation is for already "broken" hypervisor. Otherwise command will fail.
