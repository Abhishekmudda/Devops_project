Project: Student Management (Infrastructure + App)
===============================================

Short description
-----------------
- This repository contains a small Flask student-management web application and IaC/automation to deploy it to AWS (Terraform, Ansible, Jenkins). It includes Kubernetes manifests for running on EKS and CI pipelines that build and push a Docker image to ECR and run Terraform.

Repository layout (high level)
-----------------------------
- `App/` - Flask application source, Dockerfile, and templates.
- `Terraform/` - Terraform code to provision VPC, subnets, EKS cluster, EC2 bastion, IAM and related resources.
- `Ansible/` - Ansible playbooks to install tools on hosts, deploy manifests to the cluster, and build/push Docker images to ECR.
- `K8s/` - Kubernetes manifests (namespace, deployment, service, ingress) used to deploy the Flask app on EKS.
- `jenkins/` - Jenkins pipeline files (Jenkinsfile) for CI jobs: ECR build and Terraform operations.

- ![Folder structure](./Images/project%20structure%20(vscode).png)

Steps to set up Jenkins
----------------------------------
- Create EC2 instance [ubuntu, t2.medium, 16GiB EBS Volume, security group (port 22,443,80,8080 allow)] and name it has jenkins server
- SSH to jenkins server and install Jenkins 
```poweshell 
sudo apt update && sudo apt upgrade -y

sudo apt install openjdk-17-jdk -y

java -version

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null


sudo apt update
sudo apt install jenkins -y

sudo systemctl start jenkins
sudo systemctl enable jenkins

sudo systemctl status jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
- copy the password to the UI and create a user.
- Install Plugins.
- Go to manage plugins add 2 more plugins (AWS credentials, pipeline: stage view),
- Go to credentials add AWS credentials and ssh key for Bastion Host.
- create a pipeline project and copy paste jenkins pipeline script.
- Then Build the pipeline with parameters.

Build with parameters view
--------------------------------------------------------------------
![parameters view](./Images/Build%20with%20parameters%20view.png)
- There are two options 
- one click deployment
- Deploy step by step
- If choose is full_deploy == apply then it deploys entire application in one click
- If choose is to deploy step by step then order matters 
- creation order is important pull the repository, push to ECR, create infra, configure using ansible, create K8s resources. During destroying follow destroy K8s resources, remove configuration, destroy infra.

Pipeline Image
-----------------------------------------------------------------------
![Pipeline Image](./Images/pipeline_image.png) 
- First Install necessary packages, Then build image and push into ECR.
- Create Infrastructure and deploy application.
- Access it through DNS of ALB.

Files of interest 
---------------------------------
- `App/` — app source, templates, Dockerfile, requirements
- `Terraform/` — core infra code and modules under `modules/`
- `Ansible/` — playbooks for install, ECR push and k8s deployment
- `K8s/` — Kubernetes manifests
- `jenkins/` — reusable CI pipeline definitions

**NOTE: If want to change any AWS resource configuration change in terraform.tfvars file**


**Architecture of the Student Management App**
![Architecture](./Images/Architecture.png)