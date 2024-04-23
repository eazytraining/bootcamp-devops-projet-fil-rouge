#!/bin/bash
yum -y update
yum -y install epel-release

# install ansible
yum -y install ansible

# retrieve ansible code
yum -y install git
git clone https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
ansible-galaxy install -r roles/requirements.yml
ansible-playbook install_docker.yml
sudo usermod -aG docker vagrant
cd ../jenkins
/usr/local/bin/docker-compose up -d
sudo echo -e "192.168.99.11 odoo \n192.168.99.10 jenkins\n192.168.99.12 icwebapp\n192.168.99.12 pgadmin" >> /etc/hosts
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo "login : user and password : bitnami"

