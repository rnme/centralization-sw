ansible-galaxy role install --role-file=provision/requirements.yml --force
ansible-galaxy collection install --requirements-file=provision/requirements.yml --force
ansible-playbook -i provision/environment/production/hosts provision/install.yml
