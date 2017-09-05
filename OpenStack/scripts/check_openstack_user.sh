#!/bin/bash
#
# export environment variables
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=http://:35357/v3
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=
export OS_TENANT_NAME=
export OS_USERNAME=
export OS_PASSWORD=
export OS_REGION_NAME=
export OS_INTERFACE=internal
export OS_CACERT=""

#source keystonercv3

user=''
domain='default'
# do role check on all projects? 1 - true, 0 - false
check_role=1
role='admin'
# array if project ids to ignore during check (e.g. admin project, heat user project)
ignored_projects=( 9c0e038b5bd5480ab8e3ad013ac4e2e0 ec1965ade7434221b21415525a2bcc45 )
# get all projects
all_projects=($(openstack project list --domain $domain | awk 'NR>=3{print $2}'))
# get projects with user in defined domain
users_projects=($(openstack project list --user $user --domain $domain| awk 'NR>=3{print $2}'))
# get projects missing user
projects_missing_user=($(echo ${all_projects[@]} ${users_projects[@]} | tr ' ' '\n' | sort | uniq -u))
# filter out ignored projects
filtered_projects=($(echo ${projects_missing_user[@]} ${ignored_projects[@]} | tr ' ' '\n' | sort | uniq -u))
# filter out "not valid" ignored projects (e.g. wrong/not existing project ID)
filtered_projects=($(echo ${filtered_projects[@]} ${projects_missing_user[@]} | tr ' ' '\n' | sort | uniq -D | uniq))

# if diff of all projects and user's projects matches, then user is present in all projects
if [[ ${#filtered_projects[@]} == 0 ]]; then
  if [[ $check_role > 0 ]]; then
    projects_with_role=($(openstack role assignment list --user $user --role $role | awk 'NR>=3{print $7}'))
    # find projects missing role
    projects_missing_role=($(echo ${all_projects[@]} ${projects_with_role[@]} | tr ' ' '\n' | sort | uniq -u))
    # filter out projects which should be ignored
    projects_missing_role=($(echo ${projects_missing_role[@]} ${ignored_projects[@]} | tr ' ' '\n' | sort | uniq -u))
    # filter out "not valid" ignored projects (e.g. wrong/not existing project ID)
    projects_missing_role=($(echo ${projects_missing_role[@]} ${all_projects[@]} | tr ' ' '\n' | sort | uniq -D | uniq))

    if [[ ${#projects_missing_role[@]} > 0 ]]; then
      for (( i = 0; i < ${#projects_missing_role[@]}; i++ )); do
        project_id=${projects_missing_role[i]}
        # get name for project ID
        project_name=($(openstack project show $project_id | awk 'NR==9{print $4}'))
        # concat project name and project ID.
        projects="$projects $project_name - $project_id;\n"
      done
      echo -e "CRIT: following projects don't have user $user with role $role :$projects"
      exit 2
    else
      echo "All projects have user: $user with role $role"
      exit 0
    fi
  else
    echo "All projects have user: $user"
    exit 0
  fi
# if diff is higher than zero, then user is missing
elif [[ ${#filtered_projects[@]} > 0 ]]; then
  for (( i = 0; i < ${#filtered_projects[@]}; i++ )); do
    project_id=${filtered_projects[i]}
    # get name for project ID
    project_name=($(openstack project show $project_id | awk 'NR==9{print $4}'))
    # concat project name and project id.
    projects="$projects $project_name - $project_id;\n"
  done
  # exit with CRIT status
  echo -e "CRIT: following projects don't have user $user :$projects"
  exit 2
fi

# unset environment variables
unset OS_IDENTITY_API_VERSION OS_AUTH_URL OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME OS_PROJECT_NAME OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_INTERFACE OS_CACERT
