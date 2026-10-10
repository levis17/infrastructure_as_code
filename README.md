# AWS Infrastructure as Code

Terraform provisions a small AWS environment containing a VPC, a public web
server, and a private PostgreSQL database. The root configuration composes the
reusable modules under `modules/`.

## What it creates

- A VPC with public and private subnets across the configured Availability Zones.
- An internet gateway and public routes for the web subnet(s).
- A security group that allows HTTP and HTTPS from the internet and SSH from the
  configured SSH CIDR.
- One Amazon Linux 2023 EC2 instance in a public subnet. User data installs and
  starts Apache; the instance also has Systems Manager and CloudWatch agent
  policies attached.
- A private PostgreSQL 15 RDS instance, encrypted at rest and reachable on port
  5432 only from the web-server security group. Deletion protection is enabled.
- An S3 backend for Terraform state, configured in `backend.tf`.

## Requirements

- Terraform 1.10 or newer. The S3 backend uses `use_lockfile`, which requires
  Terraform 1.10 or newer.
- AWS CLI, configured with credentials for the target AWS account.
- An S3 bucket named `terraform-state-020245980377` in `us-east-1`, created
  before initializing Terraform. The AWS identity must be permitted to access
  this bucket as well as create and manage the resources in the account.

Authenticate with an AWS CLI profile or AWS IAM Identity Center (SSO), for
example:

```powershell
aws sso login --profile your-profile
$env:AWS_PROFILE = "your-profile"
aws sts get-caller-identity
```

The identity check should succeed before running Terraform. Do not put AWS
access keys in Terraform files.

## Configure variables

Create a local `terraform.tfvars` file in this directory (it is ignored by Git)
with values appropriate for your account and network. For example:

```hcl
aws_region           = "us-east-1"
environment          = "dev"
project_name         = "terraform-project"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
instance_type        = "t3.micro"
db_instance_type     = "db.t3.micro"
db_username          = "dbadmin"
allowed_ssh_cidr     = "YOUR_PUBLIC_IP/32"
```

Supply `db_password` separately, for example through the `TF_VAR_db_password`
environment variable. Do not use a placeholder password for a real deployment.
Terraform marks the password as sensitive for display, but it can still be
stored in Terraform state; protect access to the S3 state bucket and local
Terraform files.

**Restrict SSH before applying.** The current default for `allowed_ssh_cidr` is
`0.0.0.0/0`, which allows SSH connections from any IPv4 address. Set it to a
trusted IP address with a `/32` mask (or another narrowly scoped CIDR) in
`terraform.tfvars`.

## Initialize and deploy

Run these commands from this directory:

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

Review the plan before confirming `terraform apply`. The initial
`terraform init` configures the remote S3 backend and downloads the AWS
provider. If the backend bucket does not exist or AWS credentials are invalid
or expired, initialization will fail.

## Outputs

After applying, inspect the exported values with:

```powershell
terraform output
```

The outputs include the VPC ID, subnet IDs, web security group ID, EC2 instance
ID, and the sensitive RDS endpoint. Avoid sharing the endpoint or Terraform
state unless appropriate for your environment.

## Important notes

- AWS resources can incur charges while they exist. Check the AWS pricing for
  EC2, RDS, storage, and data transfer in your selected region.
- The RDS instance has deletion protection enabled and requires a final snapshot.
  A destroy may require disabling deletion protection first; retain or remove the
  final snapshot only after deciding whether the database data must be kept.
- Keep `.tfvars`, Terraform state, plans, and credentials out of source control.
  The local `.gitignore` excludes these files, but verify that secrets have not
  already been committed or exposed elsewhere.
