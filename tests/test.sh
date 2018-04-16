#!/bin/bash
#
# Ansible role test shim.
#
# Usage: [OPTIONS] ./tests/test.sh
#   - distro: a supported Docker distro version (default = "centos7")
#   - playbook: a playbook in the tests directory (default = "test.yml")
#   - role_dir: the directory where the role exists (default = $PWD)
#   - cleanup: whether to remove the Docker container (default = true)
#   - container_id: the --name to set for the container (default = timestamp)
#   - test_idempotence: whether to test playbook's idempotence (default = true)
#
# If you place a requirements.yml file in tests/requirements.yml, the
# requirements listed inside that file will be installed via Ansible Galaxy
# prior to running tests.
#
# License: MIT

# Exit on any individual command failure.
set -e

# Pretty colors.
red='\033[0;31m'
green='\033[0;32m'
neutral='\033[0m'

timestamp=$(date +%s)

# Allow environment variables to override defaults.
distro=${distro:-"centos7"}
playbook=${playbook:-"test.yml"}
role_dir=${role_dir:-"$PWD"}
cleanup=${cleanup:-"true"}
container_id=${container_id:-$timestamp}
test_idempotence=${test_idempotence:-"true"}

## Set up vars for Docker setup.
# CentOS 7
if [ $distro = 'centos7' ]; then
  init="/usr/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# CentOS 6
elif [ $distro = 'centos6' ]; then
  init="/sbin/init"
  opts="--privileged"
  image="geerlingguy/docker-$distro-ansible:latest"
# Ubuntu 18.04
elif [ $distro = 'ubuntu1804' ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Ubuntu 16.04
elif [ $distro = 'ubuntu1604' ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Ubuntu 14.04
elif [ $distro = 'ubuntu1404' ]; then
  init="/sbin/init"
  opts="--privileged"
  image="geerlingguy/docker-$distro-ansible:latest"
# Ubuntu 12.04
elif [ $distro = 'ubuntu1204' ]; then
  init="/sbin/init"
  opts="--privileged"
  image="geerlingguy/docker-$distro-ansible:latest"
# Debian 9
elif [ $distro = 'debian9' ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Debian 8
elif [ $distro = 'debian8' ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Fedora 24
elif [ $distro = 'fedora24' ]; then
  init="/usr/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Fedora 27
elif [ $distro = 'fedora27' ]; then
  init="/usr/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="geerlingguy/docker-$distro-ansible:latest"
# Alpine
elif [ $distro = 'alpine3' ]; then
  init="ping localhost"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  image="pad92/ansible-alpine"
fi


# Run the container using the supplied OS.
printf ${green}"Starting Docker container: $image."${neutral}"\n"
docker pull $image
docker run --detach --volume="$role_dir":/etc/ansible/roles/role_under_test:rw --name $container_id $opts $image $init

printf "\n"

# Install requirements if `requirements.yml` is present.
if [ -f "$role_dir/tests/requirements.yml" ]; then
  printf ${green}"Requirements file detected; installing dependencies."${neutral}"\n"
  docker exec --tty $container_id env TERM=xterm ansible-galaxy install -r /etc/ansible/roles/role_under_test/tests/requirements.yml
fi

printf "\n"

# Test Ansible syntax.
printf ${green}"Checking Ansible playbook syntax."${neutral}
docker exec --tty $container_id env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/$playbook --syntax-check

printf "\n"

# Run Ansible playbook.
printf ${green}"Running command: docker exec $container_id env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/$playbook"${neutral}
docker exec $container_id env TERM=xterm env ANSIBLE_FORCE_COLOR=1 ansible-playbook /etc/ansible/roles/role_under_test/tests/$playbook

if [ "$test_idempotence" = true ]; then
  # Run Ansible playbook again (idempotence test).
  printf ${green}"Running playbook again: idempotence test"${neutral}
  idempotence=$(mktemp)
  docker exec $container_id ansible-playbook /etc/ansible/roles/role_under_test/tests/$playbook | tee -a $idempotence
  tail $idempotence \
    | grep -q 'changed=0.*failed=0' \
    && (printf ${green}'Idempotence test: pass'${neutral}"\n") \
    || (printf ${red}'Idempotence test: fail'${neutral}"\n" && exit 1)
fi

# Remove the Docker container (if configured).
if [ "$cleanup" = true ]; then
  printf "Removing Docker container...\n"
  docker rm -f $container_id
fi
