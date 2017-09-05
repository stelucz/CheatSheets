*************************************
OpenStack user check for Sensu
*************************************

Sensu check script for checking user's presence and role in OpenStack projects.

Script uses OpenStack CLI client.

Edit environment variables to match your deployment. Script parameters *user*, *domain*, *check_role*, *role* and ignored projects.

Script will find projects where user is missing. If at least one project doesn't have specified user then these projects are listed to output. Role check is performed if all projects have user and *check_role* is set to value *1*.

Change log:

* 5. 9. 2017 added argument support for user, domain, role, role check and ignored projects
* 5. 9. 2017 initial commit
