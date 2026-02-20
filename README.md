# ☁️ AWS Hello World — DevOps Assessment

A production-style "Hello World" web application deployed on AWS, demonstrating cloud infrastructure fundamentals including VPC design, EC2, Nginx, and an Application Load Balancer  all provisioned via CloudFormation.

---

## ✅ Submission Checklist

- [x] VPC with 2 public and 2 private subnets created
- [x] 2 EC2 instances running Nginx in private subnets
- [x] Application Load Balancer accessible from internet
- [x] Custom page showing instance ID, AZ, region, and private IP
- [x] Security groups configured (EC2 accepts traffic from ALB only)
- [x] Architecture diagram included
- [x] Documentation with deployment steps
- [x] GitHub repo with all files

---

## 🏗️ Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16  (us-east-1)                         │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────┐      │
│  │  Public Subnet 1a   │  │  Public Subnet 2b   │      │
│  │  10.0.1.0/24        │  │  10.0.2.0/24        │      │
│  │  [NAT Gateway]      │  │  [ALB Node]         │      │
│  └──────────┬──────────┘  └──────────┬──────────┘      │
│             │    ALB spans both ↑     │                  │
│  ┌──────────▼──────────┐  ┌──────────▼──────────┐      │
│  │  Private Subnet 1a  │  │  Private Subnet 2b  │      │
│  │  10.0.3.0/24        │  │  10.0.4.0/24        │      │
│  │  [EC2 + Nginx]      │  │  [EC2 + Nginx]      │      │
│  └─────────────────────┘  └─────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

**Traffic flow:**
`User → IGW → ALB (public subnets) → EC2 Nginx (private subnets)`
`EC2 → NAT Gateway → IGW → Internet` (outbound only, for package installs)

---

## 📁 Repository Structure

```
aws-hello-world/
├── README.md                        ← You are here
├── cloudformation/
│   └── hello-world-infrastructure.yaml  ← Deploy everything with one command
├── configs/
│   ├── index.html                   ← Hello World HTML page
│   └── nginx.conf                   ← Nginx server block config
├── scripts/
│   └── user-data.sh                 ← EC2 bootstrap script
└── screenshots/
    ├── vpc-output.png              ← Add your screenshot here

```

---

## 🚀 Quick Deploy (CloudFormation)

### Prerequisites
- AWS CLI installed and configured (`aws configure`)
- IAM permissions for VPC, EC2, ELB, IAM

### Deploy

```bash
aws cloudformation deploy \
  --template-file cloudformation/hello-world-infrastructure.yaml \
  --stack-name hello-world-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Get the URL

```bash
aws cloudformation describe-stacks \
  --stack-name hello-world-stack \
  --query "Stacks[0].Outputs[?OutputKey=='ALBURL'].OutputValue" \
  --output text
```

> ⏳ Wait **3–5 minutes** after `CREATE_COMPLETE` for EC2 instances to finish bootstrapping Nginx.

### Destroy (avoid ongoing charges)

```bash
aws cloudformation delete-stack --stack-name hello-world-stack
```

---

## 🔒 Security Design

| Component | Inbound Rule | Outbound Rule |
|-----------|-------------|---------------|
| **ALB** (`alb-sg`) | HTTP :80 from `0.0.0.0/0` | HTTP :80 to `ec2-sg` only |
| **EC2** (`ec2-sg`) | HTTP :80 from `alb-sg` only | All traffic (via NAT) |

Key security principles:
- EC2 instances have **no public IP address**
- EC2 instances are **only reachable through the ALB** (enforced via SG reference)
- Outbound internet access for EC2 uses **NAT Gateway** (no inbound path back)
- Shell access via **AWS Systems Manager Session Manager** (no SSH, no bastion)

---

## 📦 AWS Resources Created

| Resource | Name | Details |
|----------|------|---------|
| VPC | `hello-world-vpc` | 10.0.0.0/16 |
| Public Subnet 1 | `hello-world-public-subnet-1a` | 10.0.1.0/24, us-east-1a |
| Public Subnet 2 | `hello-world-public-subnet-2b` | 10.0.2.0/24, us-east-1b |
| Private Subnet 1 | `hello-world-private-subnet-1a` | 10.0.3.0/24, us-east-1a |
| Private Subnet 2 | `hello-world-private-subnet-2b` | 10.0.4.0/24, us-east-1b |
| Internet Gateway | `hello-world-igw` | Attached to VPC |
| NAT Gateway | `hello-world-nat` | In public-subnet-1a |
| Route Table (public) | `hello-world-public-rt` | 0.0.0.0/0 → IGW |
| Route Table (private) | `hello-world-private-rt` | 0.0.0.0/0 → NAT |
| Security Group | `hello-world-alb-sg` | HTTP from internet |
| Security Group | `hello-world-ec2-sg` | HTTP from ALB only |
| IAM Role | `hello-world-ec2-role` | SSM + CloudWatch |
| EC2 Instance 1 | `hello-world-web-server-1a` | t2.micro, private-subnet-1a |
| EC2 Instance 2 | `hello-world-web-server-2b` | t2.micro, private-subnet-2b |
| Load Balancer | `hello-world-alb` | internet-facing, HTTP:80 |
| Target Group | `hello-world-tg` | /health checks, HTTP:80 |


