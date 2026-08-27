# End-to-End AWS Deployment – Scalable & Secure Web Application

A production-style, end-to-end cloud infrastructure project built on AWS, provisioned entirely with **Terraform** and deployed via **GitHub Actions CI/CD**. This project demonstrates a real-world 3-tier architecture: a static frontend served through a CDN, a scalable backend running behind a load balancer, and a Multi-AZ managed database — all inside a custom-built, secure VPC.

---

## Architecture Overview

```
                                   ┌─────────────────┐
                                   │   CloudFront     │
                                   │   (CDN)          │
                                   └────────┬─────────┘
                                            │
                                   ┌────────▼─────────┐
                                   │   S3 Bucket       │
                                   │  (Static Frontend) │
                                   └───────────────────┘

                          Internet
                             │
                    ┌────────▼─────────┐
                    │ Internet Gateway  │
                    └────────┬──────────┘
                             │
                 ┌───────────▼────────────┐
                 │   Application Load      │
                 │   Balancer (Public)     │
                 └───────────┬─────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌───────▼────────┐   ┌───────▼────────┐
│  EC2 (AZ-1)     │  │  EC2 (AZ-2)     │  ...  Auto Scaling
│  Private Subnet │  │  Private Subnet │       (min 2 / max 5,
│  Node.js App    │  │  Node.js App    │        70% CPU target)
└───────┬─────────┘  └───────┬─────────┘
        │                    │
        └──────────┬─────────┘
                    │
           ┌────────▼─────────┐
           │   RDS MySQL        │
           │   Multi-AZ          │
           │   Private Subnet    │
           └─────────────────────┘

  NAT Gateway → gives private subnets outbound-only internet access
  Secrets Manager → stores DB credentials (no hardcoded passwords)
  CloudWatch + EventBridge + SNS → alarms & notifications
  CloudTrail → full audit logging of all API activity
```

---

## Tech Stack & AWS Services

| Layer | Service | Purpose |
|---|---|---|
| Identity & Access | **IAM** | Least-privilege roles/policies for EC2 and services |
| Networking | **VPC** | Custom VPC — 2 public + 2 private subnets across 2 AZs |
| Networking | **Internet Gateway / NAT Gateway** | Public internet access / private outbound access |
| Compute | **EC2** | Node.js backend running in private subnets |
| Compute | **Auto Scaling Group** | Min 2 / Max 5 instances, target-tracking scaling at 70% CPU |
| Traffic | **Application Load Balancer** | Routes public traffic to healthy backend instances |
| Database | **RDS (MySQL, Multi-AZ)** | Managed relational database in private subnets |
| Frontend | **S3 (Static Website Hosting)** | Hosts the static frontend |
| Delivery | **CloudFront** | CDN in front of S3 for global content delivery |
| Monitoring | **CloudWatch + EventBridge + SNS** | Metric alarms routed via events to email notifications |
| Auditing | **CloudTrail** | Multi-region audit trail of all account activity |
| Secrets | **Secrets Manager** | Securely stores and rotates DB credentials |
| IaC | **Terraform** | 100% infrastructure as code, fully reproducible |
| CI/CD | **GitHub Actions + AWS SSM** | Automated deploys to S3 (frontend) and EC2 (backend) without SSH |

---

## Repository Structure

This project is split across two repositories by design — infrastructure and application code are decoupled, matching real-world DevOps practice:

```
aws-terraform-project/     → Infrastructure as Code (this repo)
├── providers.tf
├── iam.tf
├── vpc.tf
├── ec2.tf
├── alb.tf
├── asg.tf
├── rds.tf
├── s3.tf
├── cloudfront.tf
├── cloudwatch.tf
├── cloudtrail.tf
├── secrets.tf
└── outputs.tf

app-deployment-proj/       → Application code (separate repo)
├── frontend/
│   ├── index.html
│   └── error.html
├── backend/
│   ├── server.js
│   └── package.json
└── .github/workflows/
    └── deploy.yml
```

---

## Security Highlights

- No hardcoded credentials — RDS password generated randomly and stored in **Secrets Manager**
- Backend and database live entirely in **private subnets** — no direct internet exposure
- Security groups follow least-privilege: ALB only accepts port 80 from the internet, EC2 only accepts traffic from the ALB, RDS only accepts traffic from EC2
- IAM roles scoped to specific resource ARNs rather than wildcard permissions
- All account activity logged via **CloudTrail** for auditability
- Deployment to private EC2 instances handled via **AWS Systems Manager (SSM)** — no SSH keys or open port 22 required for CI/CD

---

## CI/CD Pipeline

GitHub Actions handles two deployment jobs on every push to `main`:

1. **Frontend deploy** — syncs the `frontend/` folder directly to the S3 bucket
2. **Backend deploy** — uses `aws ssm send-command` to remotely pull the latest code and restart the Node.js app (via PM2) on the EC2 instances inside the Auto Scaling Group, with zero direct SSH access

---

## How to Deploy This Infrastructure

```bash
git clone <this-repo-url>
cd aws-terraform-project

# Configure AWS credentials
aws configure

terraform init
terraform plan
terraform apply
```

> ⚠️ **Cost note:** This architecture uses a NAT Gateway and Multi-AZ RDS, neither of which are covered by the AWS Free Tier. Run `terraform destroy` when you're done testing to avoid ongoing charges.

---

## Notable Challenge Solved

While provisioning EC2 instances via a Launch Template, Node.js installation repeatedly failed with `GLIBC_2.28 not found` errors — Amazon Linux 2's default glibc version (2.26) is incompatible with newer Node.js builds distributed via NodeSource. Root-caused by inspecting `/var/log/cloud-init-output.log` on the instance, then resolved by switching to a Node.js version whose prebuilt binary is compatible with Amazon Linux 2's glibc version, avoiding the dependency mismatch entirely.

---

## Author

**Palash Dangat**
Fresher DevOps & Cloud Engineer
