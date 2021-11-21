# Flask App with NGINX as reverse proxy server and secured database server provisioning using Ansible-playbook.

### Requirement

- Create three plain ubuntu18 instances in an AWS custom VPC (public VPC is fine)
- Configure one as frontend nginx which have an elastic IP attached
- Configure one as flask app with all required packages installed
- Configure one as MySQL instance
- Nginx should be reverse proxying the flask app
- Create a GitHub free account, create a public repository, and push the Ansible, terraform code to the same repository and share the repository URL (Secrets such as AWS Access credentials should not be pushed).
- Follow all the terraform and AWS best practices

### Features

Here I have used an ansible playbook file to trigger all tasks to create the above required infrastructure. Initially the playbook will run the terraform code to build the entire infrastructure to build servers and then the ansible will do the rest of the configurations.

### Pre-requesites;
- Ansible
- Terraform

Also I have created a fresh keypair using 'ssh-keygen' command and stored as 'tfkey' in project/terraform/. The "access_key" and "secret_key" are added as variables under project/terraform/variables.tf.

Finally, To deploy the project,

```sh
ansible-playbook main.yml
```
