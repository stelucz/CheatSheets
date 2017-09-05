*************************************
OpenStack user check for Sensu
*************************************

Sensu check script for checking user's presence and role in OpenStack projects.

Script uses OpenStack CLI client.

Edit environment variables to match your deployment. Edit script parameters *user*, *domain*, *check_role* and *role*.

Script will find projects where user is missing. If at least one project doesn't have specified user then these projects are listed to output. Role check is performed if all projects have user and *check_role* is set to value *1*.

Change log:

* initial commit
