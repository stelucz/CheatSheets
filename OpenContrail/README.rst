*************************************
OpenContrail cheatsheet and ops guide
*************************************

Set of my personal notes about OpenContrail operations

General
################

Check Contrail status::

 contrail-status

 # example output from control node
 # == Contrail Control ==
 # supervisor-control:           active
 # contrail-control              active
 # contrail-control-nodemgr      active
 # contrail-dns                  active
 # contrail-named                active
 #
 # == Contrail Config ==
 # supervisor-config:            active
 # contrail-api:0                active
 # contrail-config-nodemgr       active
 # contrail-device-manager       backup
 # contrail-discovery:0          active
 # contrail-schema               backup
 # contrail-svc-monitor          backup
 #
 # == Contrail Database ==
 # contrail-database:            inactive (disabled on boot)
 #
 # == Contrail Supervisor Database ==
 # supervisor-database:          active
 # contrail-database             active
 # contrail-database-nodemgr     active
 # kafka                         active
 #
 # example output from compute node (vRouter)
 # == Contrail vRouter ==
 # supervisor-vrouter:           active
 # contrail-vrouter-agent        active
 # contrail-vrouter-nodemgr      active


To search through net namespaces use following script::

  #!/bin/bash

  exit_usage() {
          echo "Usage: $0 <address>"
          exit 1
  }

  [ -z $1 ] && exit_usage

  WC=$(ip netns | wc -l)
  for ((i=1;i<$WC+1;i++))
  do
          NAMESPACE=$(ip netns | sed -n "$i"p)
          if [ `ip netns exec $NAMESPACE ip a | grep $1 | wc -l` -gt 0 ]
          then
                  echo $NAMESPACE
          fi
  done

Issues, Alarms, Debugging
########################################

Process(es) reporting as non-functional
**********************************************

General
---------

Contrail GUI reports *Process(es) reporting as non-functional* alarm for node.

1. Run *contrail-status* command

  #. if it reports *initializing (NTP state unsynchronized.)* then check NTP services
  #. run *service ntp status*, *ntpq -pn* and check ntp stauts. Fix any problems and let NTP to synchronize

2. restart contrail processes

  #. if they run as service - *service <contrail-service-name> restart*
  #. if they run under supervisord - *service supervisor<service-name> restart*

Database nodemgr
-----------------

*contrail-status* reports::

  == Contrail Supervisor Database ==
 supervisor-database:          active
 contrail-database             active
 contrail-database-nodemgr     initializing (Disk space for analytics db not retrievable.)
 kafka                         active

Restart or kill *nodemgr* database::

 ps aux | grep nodemgr
 root      1211  0.0  0.0 244532 31048 ?        Sl   Jul20   8:45 python /usr/bin/contrail-nodemgr --nodetype=contrail-control
 root      1215  0.1  0.1 245068 33108 ?        Sl   Jul20  51:55 python /usr/bin/contrail-nodemgr --nodetype=contrail-database
 root      2770  0.0  0.0 170800 31088 ?        Sl   Jul20  11:11 python /usr/bin/contrail-nodemgr --nodetype=contrail-config
 root     25577  0.0  0.0  11880  2084 pts/0    S+   08:22   0:00 grep --color=auto nodemgr

 kill 1215

Check Cassandra status
------------------------

::

 nodetool status
 Datacenter: datacenter1
 =======================
 Status=Up/Down
 |/ State=Normal/Leaving/Joining/Moving
 --  Address        Load       Tokens  Owns (effective)  Host ID                               Rack
 UN  192.168.48.17  16.89 MB   256     100.0%            b1706e3f-3999-4818-84c1-b3a1cf727fec  rack1
 UN  192.168.48.16  17.67 MB   256     100.0%            05853b7f-0275-40bf-9b91-8ac80ce179b0  rack1
 UN  192.168.48.18  1.44 MB    256     100.0%            74d51819-2615-4654-ad10-03ffdfad3b09  rack1



OpenContrail SNAT failing
*******************************

If SNAT is failing try to do folowing things:
#. Remove and again add *Gateway* at virtual Router
#. *svc-monitor* service is responsible for SNAT, LBAAS and service instances. If you have issue with this. Go on node where is contrail-svc-monitor active and restart it.

contrail-logs
*******************

CLI command to get logs::

 contrail-logs

List of accepted values for *--category* parameter::

 DEFAULT
 XMPP
 BGP
 BGP_CONFIG
 BGP_PEER
 IFMAP
 IFMAP_AGENT
 IFMAP_PEER
 IFMAP_STATE_MACHINE
 IFMAP_XMPP
 TCP
 ROUTING_INSTANCE
 VROUTER
 DISCOVERY
 DNSAGENT
 DISCOVERYCLIENT
 UDP

List of accepted values for *--level* parameter::

 INVALID
 SYS_EMERG
 SYS_ALERT
 SYS_CRIT
 SYS_ERR
 SYS_WARN
 SYS_NOTICE
 SYS_INFO
 SYS_DEBUG

contrail-api-cli
****************

Check subnets for missing keys::

  contrail-api-cli --host=<contrail_api> fix-subnets --check
  contrail-api-cli --host=<contrail_api> fix-subnets <subnet-id> --dry-run
  contrail-api-cli --host=<contrail_api> fix-subnets <subnet-id>
  # or
  contrail-api-cli --host=<contrail_api> fix-subnets

Find orphaned projects::

  contrail-api-cli --host=<contrail_api> find-orphaned-projects

start interactive shell::

  contrail-api-cli --host=<contrail_api> shell


Debugging traffic - vRouter commands
*************************************

`Juniper documentation on vRouter CLI <https://www.juniper.net/documentation/en_US/contrail3.1/topics/task/configuration/vrouter-cli-utilities-vnc.html>`_ Juniper's Contrail implementation differs a little bit.

"Guide" assumes use of OpenContrail with OpenStack.
Following steps can be done to troubleshoot traffic or make yourself familiar with how traffic is handled by vRouter module.


Check security group configuration and flow list
------------------------------------------------
Security group is set of rules allowing traffic. Implicit deny is used. => no rule == deny all. Even if the sec group is empty (deny all) VM can (should be able to) access metadata server!!! and there is no problem with provisioning.

Check flow list if traffic is denied by Security Group (SG) or Network Policy::

 flow -l | grep -A 1 <src-ip_or_dst-ip>

Sample output::

 flow -l | grep -A 1  31.155.64.21

 Index              Source:Port           Destination:Port      Proto(V)
 -----------------------------------------------------------------------
 377692            31.155.64.21:53249         31.155.64.2:80       6 (57)
 (K(nh):104, Action:D(Policy), S(nh):104,  Statistics:4/296 UdpSrcPort 64614)

 # Action:F=Forward, D=Drop N=NAT(S=SNAT, D=DNAT, Ps=SPAT, Pd=DPAT, L=Link Local Port)
 # Other:K(nh)=Key_Nexthop, S(nh)=RPF_Nexthop

In this case traffic is denied by Network Policy *Action:D(Policy)*. Output can contain *SG* instead of *Policy* -> traffic is denied by Security Group.
Soulution: Fix Policy/Security Group configuration.

Check nova and neutron logs
---------------------------

Check logs at OpenStack control nodes::

 grep -E -R -i "trace|error" /var/log/nova/ /var/log/neutron/

Check neutron port - can report binding_failed etc::

 neutron port-show <port_id>

Obtain VM details
-----------------

At OpenStack control node run::

 openstack server list --all-projects | grep -i <vm-name>
 nova show <vm-id> # or openstack server show <vm-id>
 # OS-EXT-SRV-ATTR:host attribute describes where (at which hypervisor) VM is hosted
 # OS-EXT-SRV-ATTR:instance_name

Obtain VM's tap interfaces
--------------------------

Get tap interfaces from configuration *.xml* file on host (compute where VM is hosted got from `Obtain VM details`_). Configuration file contains only interfaces which have been attached while provisioning. Interface attached later, after provisioning can be found in Contrail GUI eg. by IP address.

Search for name of tap interfaces (depends on deployment)::

 grep -i tap /var/lib/nova/instances/<instance_id>/libvirt.xml
 grep -i tap /etc/libvirt/qemu/<OS-EXT-SRV-ATTR:instance_name>.xml

Instance id or instance name is part of output in step `Obtain VM details`_.

Get name of virtual host interface and physical interface
---------------------------------------------------------

Inspect vRouter configuration at compute node::

 grep -EiR -A5 "virtual-host-interface|physical_interface" /etc/contrail/contrail-vrouter-agent.conf

 # sample output:
 # name of virtual host interface
 name=vhost0

 physical_interface=bond0.1010

=> virtual-host-interface -> *vhost0*,  physical_interface -> *bond0.1010*

Verify XMPP messages
--------------------

Verify that XMPP messages are exchanged between vRouter and Contrail Controller, vhost0 is *virtual-host-interface* got from `Get name of virtual host interface and physical interface`_

Get index of interface::

 tcpdump -D | grep -i vhost0

Check if there is xmpp traffic at interface::

 tcpdump -nei 6 port xmpp-server

Verify that VM's traffic is leaving host via physical interface
---------------------------------------------------------------

Verify that traffic is leaving host, bond0.1010 is *physical_interface* got from `Get name of virtual host interface and physical interface`_

Get index of interface::

  tcpdump -D | grep -i bond0.1010

Check if traffic is leaving host via physical interface::

 # proto 47 == MPLSoGRE, 192.168.2.3 - source IP of traffic
 tcpdump -nei 4 proto 47 | grep <src_or_dst_ip>

If two instances are hosted at same compute node than traffic is routed localy (doesn't leave host via interface).

Find VRF to which interface belongs
-----------------------------------

Get tap inteface details::

 vif --list | grep -A 4 <tap_interface_name>

 # sample output
 vif0/18     OS: tap0dc4d428-59
 Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:0
 Vrf:62 Flags:PL3L2D MTU:9160 Ref:6
 RX packets:65599000  bytes:7292082458 errors:0
 TX packets:69352017  bytes:11711902945 errors:0

=> *Vrf:62*

Tap interface name is got from step `Obtain VM's tap interfaces`_.

Listen on interface to see if traffic is leaving or reaching interface::

 tcpdump -nei <tap_interface_name>

Show route table for specific VRF
---------------------------------

Show route table::

 rt --dump <vrf_id> | less

 # sample output
 Vrouter inet4 routing table 0/62/unicast
 Flags: L=Label Valid, P=Proxy ARP, T=Trap ARP, F=Flood ARP
 Destination           PPL        Flags        Label         Nexthop    Stitched MAC(Index)
 0.0.0.0/8               0                       -              0        -
 ...
 192.168.10.0/32        24           TF          -              1        -
 192.168.10.1/32        32           PT          -              7        -
 192.168.10.2/32        32           PT          -              7        -
 192.168.10.3/32        32            P          -            506        2:d:c4:d4:28:59(163708)
 192.168.10.4/32        32           LP         86            295        2:db:57:9:ad:a3(180580)
 192.168.10.5/32        32            P          -            297        2:e:80:1c:e8:9e(177972)
 192.168.10.6/32        24           TF          -              1        -
 192.168.10.7/32        24           TF          -              1        -
 ...

=> 192.168.10.3 and 192.168.10.5 are hosted on same compute (no label for destinations). 192.168.10.4 is spawned at another hypervisor.

VRF id is got from step `Find VRF to which interface belongs`_.

Get next-hop
------------

Command::

 nh --get <next_hop_id>

 # sample output for next-hop vif interface
 Id:260        Type:Encap     Fmly: AF_INET  Flags:Valid, Policy,   Rid:0  Ref_cnt:4 Vrf:29
               EncapFmly:0806 Oif:39 Len:14 Data:02 28 b3 58 ca 20 00 00 5e 00 01 00 08 00
 # sample output for next-hop vRouter, physical GW...
 Id:32         Type:Tunnel    Fmly: AF_INET  Flags:Valid, MPLSoGRE,   Rid:0  Ref_cnt:659 Vrf:0
               Oif:0 Len:14 Flags Valid, MPLSoGRE,  Data:06 26 84 82 56 f4 fa 02 25 ec e7 1a 08 00
               Vrf:0  Sip:192.168.24.8  Dip:192.168.24.5

=> Oif:39 -> vif id - *vif0/<id>*
=> *Dip:192.168.24.5* - tunnel end point (destination compute or physical gateway)

Next hop id is got from `Show route table for specific VRF`_.

Next-hop (destination) check
----------------------------

At destination compute got from `Get next-hop`_ check mpls label mapping to next-hop.
Get next-hop for specific label::

 mpls --get <label_id>

 # sample output
 MPLS Input Label Map
 Label    NextHop
 -------------------
   86       232

=> next-hop *232*

Label id is got from `Show route table for specific VRF`_.

Check next-hop for label::

 nh --get <next_hop_id>

 # sample output
 Id:508        Type:Encap     Fmly: AF_INET  Flags:Valid, Policy,   Rid:0  Ref_cnt:4 Vrf:28
               EncapFmly:0806 Oif:69 Len:14 Data:02 85 02 6e cc a7 00 00 5e 00 01 00 08 00

=> *VRF 28, Oif 69* (interface)

Now we can tcpdump interface, check route table... (repeat steps above).

Get vrf statistics - discards, receives, etc
--------------------------------------------
vrfstats --get <vrf-id>



Exploring Flow list - examples
*************************************

Command to grep flow for specific vrf and IP address::

  flow -l | grep "(<VRF_ID>" -A2 | grep -A2 -B1 <IP_address>

Example 1 - traffic dropped by SG (no rules specified - empty SG). Traffic originating in VM::

  root@h-1-n16-c-009:~# flow -l | grep "(27" -A2 | grep -A2 -B1 192.168.31.8
     608584<=>1190252      192.168.31.8:46333                                  6 (27)
                           216.58.209.142:80
  (Gen: 21, K(nh):291, Action:D(SG), Flags:, TCP:S, QOS:-1, S(nh):291,  Stats:2/148,  SPort 52811 TTL 0)
  --
     673300<=>1532492      192.168.31.8:58044                                 17 (27)
                           192.168.31.2:53
  (Gen: 23, K(nh):291, Action:F, Flags:, QOS:-1, S(nh):291,  Stats:1/68,  SPort 51010 TTL 0)
  --
     693720<=>1186884      192.168.31.8:53352                                 17 (27)
                           192.168.31.2:53
  (Gen: 46, K(nh):291, Action:F, Flags:, QOS:-1, S(nh):291,  Stats:2/140,  SPort 51676 TTL 0)
  --
    1186884<=>693720       192.168.31.2:53                                    17 (27)
                           192.168.31.8:53352
  (Gen: 7, K(nh):291, Action:F, Flags:, QOS:-1, S(nh):8,  Stats:0/0,  SPort 62115 TTL 0)
  --
    1190252<=>608584       216.58.209.142:80                                   6 (27)
                           192.168.31.8:46333
  (Gen: 7, K(nh):291, Action:D(Unknown), Flags:, TCP:Sr, QOS:-1, S(nh):28,  Stats:0/0,  SPort 65029 TTL 0)
  --
    1331892<=>1831652      46.255.231.48:3421                                  1 (27)
                           192.168.31.8:0
  (Gen: 18, K(nh):291, Action:D(Unknown), Flags:, QOS:-1, S(nh):28,  Stats:0/0,  SPort 49350 TTL 0)
  --
    1532492<=>673300       192.168.31.2:53                                    17 (27)
                           192.168.31.8:58044
  (Gen: 14, K(nh):291, Action:F, Flags:, QOS:-1, S(nh):8,  Stats:0/0,  SPort 53334 TTL 0)
  --
    1831652<=>1331892      192.168.31.8:3421                                   1 (27)
                           46.255.231.48:0
  (Gen: 10, K(nh):291, Action:D(SG), Flags:, QOS:-1, S(nh):291,  Stats:2/196,  SPort 53250 TTL 0)

Traffic to vRouter services (DHCP, DNS) isn't intercepted by Security Group rules.

Example 2 - traffic dropped by SG. Traffic originating outside VM::

    914220<=>1126436      192.168.31.8:80                                     6 (27)
                          192.168.31.4:55292
  (Gen: 20, K(nh):291, Action:D(Unknown), Flags:, TCP:Sr, QOS:-1, S(nh):291,  Stats:0/0,  SPort 55163 TTL 0)
  --
    1126436<=>914220      192.168.31.4:55292                                  6 (27)
                          192.168.31.8:80
  (Gen: 12, K(nh):291, Action:D(SG), Flags:, TCP:S, QOS:-1, S(nh):28,  Stats:5/370,  SPort 54642 TTL 0)

If traffic flow is droped, then returning flow record has *Unknown* drop reason.
