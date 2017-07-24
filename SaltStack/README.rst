********************
SaltStack cheatsheet
********************

SaltStack jobs
##############
`Job management at SaltStack.com <https://docs.saltstack.com/en/latest/topics/jobs/>`_

Basic commands::

 salt-run jobs.active                 # get list of active jobs
 salt-run jobs.list_jobs              # get list of historic jobs
 salt-run jobs.lookup_jid <job_id>    # get details of this specific job

SaltStack key management
########################
`Key management by salt-key command at SaltStack.com <https://docs.saltstack.com/en/latest/ref/cli/salt-key.html>`_

Salt minion keys can be in one of the following states:

* **unaccepted**: key is waiting to be accepted.
* **accepted**: key was accepted and the minion can communicate with the Salt master.
* **rejected**: key was rejected using the salt-key command. In this state the minion does not receive any communication from the Salt master.
* **denied**: key was rejected automatically by the Salt master. This occurs when a minion has a duplicate ID, or when a minion was rebuilt or had new keys generated and the previous key was not deleted from the Salt master. In this state the minion does not receive any communication from the Salt master.

To change the state of a minion key, use **-d** to delete the key and then accept or reject the key.

Commands::

 salt-key -l 	          # List the public keys
 salt-key -L 	          # List all public keys
 salt-key -a 'minion'   # Accept minion1 public key
 salt-key -A            # Accept ALL public keys
 salt-key -d 'minion'   # Delete minion1 public key
 salt-key -D            # Delete ALL public keys
 salt-key -r            # Reject a public key
 salt-key -R            # Reject ALL public keys
 salt-key -p            # Print the specified public key
 salt-key -P            # Print all public keys

Targeting minions
#################
`Targeting minions at SaltStack.com <https://docs.saltstack.com/en/latest/topics/targeting/index.html>`_

Targeting minions is specifying which minions should run a command or execute a state by matching against hostnames, or system information, or defined groups, or even combinations thereof::

 salt * test.ping                                       # Match all minions
 salt -G 'os:Fedora' test.ping                          # Match minions with grain os:Fedora
 salt -C 'G@os:Debian and webser* or E@db.*' test.ping  # Match with grain (@G) and regex (@E)
 salt 'web[1-4]' test.ping                              # Match the web1 throught web4 servers
 salt -E 'web1-(prod|dev)' test.ping                    # Match web1 server for both prod and dev based on a regexp
 salt -L 'web1, db[1-2]'                                # Match based on a list

Grains
#################
`Grains at SaltStack.com <https://docs.saltstack.com/en/latest/topics/grains/>`_

Salt comes with an interface to derive information about the underlying system. This is called the grains interface, because it presents salt with grains of information. Grains are collected for the operating system, domain name, IP address, kernel, OS type, memory, and many other system properties.

Commands::

 salt '*' grains.ls
 salt '*' grains.items
 salt '*' grains.item os

Pillars
#################
`Pillars at SaltStack.com <https://docs.saltstack.com/en/getstarted/config/pillar.html>`_

Commands::

 salt 'minion' pillar.get pillar          # Get pillar
 salt 'minion' pillar.item pillar         # Print pillar items
 salt 'minion' pillar.ls                  # Show available main keys
 salt '*' pillar.items                    # Show available pillar data
 salt '*' pillar.get pkg:apache           # Show pkg:apache pillar
 salt '*' pillar.file_exists foo/bar.sls  # Return true if pillar file exist
 salt '*' saltutil.refresh_pillar         # Reload pillars


Actions at minions
##################

Get available roles/states at minion::

 salt 'minion' state.show_top

Running states at minion::

 salt 'minion' state.sls linux                # Run linux state at minion
 salt 'minion' state.sls linux,freeipa        # Run more states at minion
 salt 'minion' state.highstate                # Run highstate (all states) at minion
 salt 'minion' state.sls linux test=true      # Dry run linux state at minion (no changes)
 salt 'minion' state.sls linux --output-diff  # Run linux state at minion and show only changes
 salt 'minion' state.sls linux -l debug       # Run linux state at minion with debug output
 salt-call state.sls linux                    # Run linux state from minion (localy)

Running commands and scripts at minion::

 salt 'minion' cmd.run 'tail /var/log/syslog'       # Run tail command
 salt 'minion' cmd.script '/home/user/script.sh'    # Run script.sh

System administration::

 salt 'minion' system.reboot          # Reboot system
 salt 'minion' status.uptime          # Show uptime
 salt 'minion' status.diskusage       # Show disc usage
 salt 'minion' status.all_status      # Show all stats (a lot)

Services administration::

 salt 'minion' service.get_all                    # Get list of available services
 salt 'minion' service.status <service_name>      # Get service status
 salt 'minion' service.available <service_name>   # Return true if service is available
 salt 'minion' service.enable <service_name>      # Enable service at boot
 salt 'minion' service.start <service_name>       # Start service
 salt 'minion' service.restart <service_name>     # Restart service
 salt 'minion' service.stop <service_name>        # Stop service
 salt 'minion' service.disable <service_name>     # Disable service at boot

Network administration::

 salt 'minion' network.arp                        # Get the ARP table
 salt 'minion' network.ip_addrs                   # Get IPs of your minion
 salt 'minion' network.ping <hostname>            # Ping a host from your minion
 salt 'minion' network.traceroute <hostname>      # Traceroute a host from your minion
 salt 'minion' network.default_route              # Get default route
 salt 'minion' network.routes                     # Get list of all routes
 salt 'minion' network..get_route <destination>   # Get route for destination

Other commands::

 salt 'minion' mine.update                        # Update minion's cached data (pillars, grains, ...) at master
