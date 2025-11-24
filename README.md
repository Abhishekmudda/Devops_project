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
- `not_imp/` - Ignored notes/unused templates (excluded from instructions below).

Quick architecture overview
---------------------------
- Terraform creates the network (VPC, public/private subnets), an EKS cluster (private subnets), an EC2 bastion (public subnet), and outputs needed IDs.
- Docker image is built from `App/` and pushed to ECR (Ansible playbooks + Jenkins pipelines automate this).
- Kubernetes manifests in `K8s/` deploy the image (Deployment -> Service -> Ingress) using an ALB ingress.

Prerequisites (local workstation / CI)
------------------------------------
- Git
- Docker (for building images locally or in CI)
- Python 3.11 (for local dev) and pip
- AWS CLI v2 configured with credentials that have permissions to create the required resources
- Terraform >= 1.5.0 (the repo config requires >= 1.5.0)
- Ansible (for playbooks) or use the bundled Ansible Docker image used by Jenkins
- kubectl (for working with the EKS cluster)

Environment variables and AWS credentials
----------------------------------------
- The pipelines and playbooks expect AWS credentials to be available. You can export them locally:

```powershell
$env:AWS_ACCESS_KEY_ID = "<your-access-key>"
$env:AWS_SECRET_ACCESS_KEY = "<your-secret-key>"
$env:AWS_DEFAULT_REGION = "us-east-1"
```

Or configure them with `aws configure` or store them in `~/.aws/credentials`.

Application (App/) — local development
-------------------------------------
1. Create a Python virtual environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r App\requirements.txt
```

2. Run locally (uses SQLite by default):

```powershell
cd App
set FLASK_APP=app.py
flask run
# The app will listen on 0.0.0.0:5000 (Dockerfile uses the same)
```

3. Useful CLI command (declared in `app.py`):

```powershell
flask db-init   # creates DB tables
```

Container image (Docker)
------------------------
- The `App/Dockerfile` builds a Python 3.11 image, installs `requirements.txt`, exposes port 5000 and runs `flask run`.
- To build locally:

```powershell
docker build -t student-mgmt:latest -f App\Dockerfile .
docker run -p 5000:5000 student-mgmt:latest
```

Pushing image to ECR (Ansible & Jenkins)
----------------------------------------
- `Ansible/deploy_to_ecr.yml` automates ECR login, Docker build, tag and push. Jenkins pipelines call this playbook or execute similar commands.
- Jenkins examples (`jenkins/jenkinsfile` and `jenkins/jenkinsfile_ecr`) show how CI will:
	- install Docker/Ansible/AWS CLI in the agent
	- clone the repository
	- run the Ansible playbook `deploy_to_ecr.yml`

Terraform (Terraform/)
-----------------------
Important files and behavior:
- `main.tf` — Terraform configuration, S3 backend configured (bucket: `abhishek-112233-bucket`, key: `eks/terraform.tfstate`), required providers (aws ~>5.0, tls, local).
- `variables.tf` — variables used by the Terraform code (region, vpc_cidr, subnets, cluster_name, eks_version, etc.).
- `terraform.tfvars` — an example variable values file (region=us-east-1, VPC CIDRs, cluster_name, etc.).
- `EKS.tf`, `EC2.tf`, `vpc.tf`, subnet modules — resources for EKS cluster, node group, bastion EC2, VPC and subnets.

Typical Terraform workflow (from the `Terraform/` directory):

```powershell
cd Terraform
terraform init
terraform validate
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

Notes & tips for Terraform
- Ensure AWS credentials are available to the environment where you run Terraform (or configured in the CI credentials binding used in Jenkins).
- Backend S3 bucket name and region are configured in `main.tf`. If you change the backend, re-run `terraform init`.
- The EKS cluster launched uses the `private_subnet` IDs from the module outputs.

Ansible (Ansible/)
-------------------
- `Install.yml` — installs utilities (aws cli, kubectl, eksctl) and places AWS credentials for the `ubuntu` user on any remote hosts it targets.
- `create_resources.yml` — copies K8s manifests to the bastion and runs `kubectl apply` for namespace, deployment, service, ingress. It also waits for ALB DNS to appear and prints the DNS.
- `deploy_to_ecr.yml` — logs into ECR, builds Docker image from `App/`, tags, and pushes to the ECR repository.

How to run Ansible playbooks (example local run for ECR push):

```powershell
cd Ansible
# Example (uses environment AWS vars or credentials file):
ansible-playbook deploy_to_ecr.yml --extra-vars "aws_region=us-east-1 ecr_repo=student-management account_id=<account-id>"
```

Kubernetes manifests (K8s/)
---------------------------
- `namespace.yaml` — creates `student-app` namespace.
- `deployment.yaml` — Deployment for the Flask app, image currently set to `abhimudda/student-management-website:v1` (update to your ECR image tag after pushing).
- `service.yaml` — ClusterIP service exposing port 80 -> container 5000.
- `ingress.yaml` — ALB ingress configuration (annotated for AWS ALB Ingress Controller).

To apply manifests from the bastion host (example flow used by the playbook):

```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

Jenkins pipelines (jenkins/)
---------------------------
- `jenkinsfile_ecr` and `jenkinsfile` show two pipeline examples for building/pushing the Docker image and for Terraform operations respectively.
- The Jenkinsfiles expect credentials and region to be supplied via parameters or Jenkins credentials bindings (`aws-cred`).

Useful variables and defaults (from `terraform.tfvars`)
-----------------------------------------------------
- `region = "us-east-1"`
- `vpc_cidr = "10.0.0.0/16"`
- `public_subnet_cidr = ["10.0.1.0/24"]`
- `private_subnet_cidr = ["10.0.2.0/24", "10.0.3.0/24"]`
- `cluster_name = "student-cluster"`

Security & IAM notes
---------------------
- Terraform creates IAM roles and policies for EKS and bastion EC2; review `IAM.tf` and `EC2.tf` before applying in production.
- The Ansible playbooks copy AWS credentials into `/home/ubuntu/.aws/credentials` on remote hosts for convenience — consider using more secure approaches (IAM instance profiles or SSM Parameter Store) in production.

Costs and cleanup
-----------------
- This project creates AWS resources that can incur costs (VPC, NAT/EIP, EKS cluster, EC2 instance). Use `terraform destroy` to remove resources when done:

```powershell
cd Terraform
terraform destroy -auto-approve
```

Files of interest (quick pointers)
---------------------------------
- `App/` — app source, templates, Dockerfile, requirements
- `Terraform/` — core infra code and modules under `modules/`
- `Ansible/` — playbooks for install, ECR push and k8s deployment
- `K8s/` — Kubernetes manifests
- `jenkins/` — reusable CI pipeline definitions

Next steps I can help with
--------------------------
- Patch Terraform to use multi-AZ NAT gateways and route private subnets accordingly.
- Update `deployment.yaml` image to point to the ECR repository produced by the Ansible workflow.
- Add a GitHub Actions or local Makefile to simplify dev/test flows.
- Run `terraform validate` or linter checks (I can run these if you want).

Contact
-------
If you want me to generate an opinionated `Makefile`, add a minimal `deploy` script, or patch Terraform to be multi-AZ ready, tell me which changes to apply and I will update the repo.


