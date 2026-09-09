# 🍔 Online Food Ordering & Delivery Application  
## Production-Grade DevSecOps Pipeline on AWS EKS

![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![Ansible](https://img.shields.io/badge/Ansible-Automation-EE0000?logo=ansible)
![Jenkins](https://img.shields.io/badge/Jenkins-CI/CD-D24939?logo=jenkins)
![SonarQube](https://img.shields.io/badge/SonarQube-Code%20Quality-4E9BCD?logo=sonarqube)
![Trivy](https://img.shields.io/badge/Trivy-Security-1904DA?logo=trivy)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana)
![Docker](https://img.shields.io/badge/Docker-Container-2496ED?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-HPA-326CE5?logo=kubernetes)

---

## 📌 Project Overview

A complete DevSecOps pipeline for a food delivery application, built from scratch. The entire infrastructure is defined as code using **Terraform** (VPC, EKS, EC2, IAM) and configured using **Ansible** (Jenkins, Docker, kubectl, Helm, SonarQube). The CI/CD pipeline runs on **Jenkins** with integrated security scanning (SonarQube, OWASP, Trivy) and deploys the containerized application to **Amazon EKS** with **Horizontal Pod Autoscaling (HPA)**. Monitoring is implemented using **Prometheus** and **Grafana**.

**Every `git push` triggers an automated build → security scan → deployment to Kubernetes.**

---

## ⭐ Key Features

| Feature | Description |
|---------|-------------|
| **Infrastructure as Code** | AWS resources provisioned with Terraform |
| **Configuration Management** | Jenkins & tools automated with Ansible |
| **Separate CI/CD Pipelines** | CI builds & scans, CD deploys to EKS |
| **DevSecOps** | SonarQube (code quality) + OWASP (dependencies) + Trivy (container) |
| **Container Orchestration** | EKS cluster with 3 worker nodes (t3.medium) |
| **Auto Scaling** | HPA scales pods from 2 to 5 based on CPU (70% threshold) |
| **Monitoring** | Prometheus metrics + Grafana dashboards |
| **Email Notifications** | Build success/failure alerts with Gmail SMTP |
| **Custom Domain** | Route 53 mapping to ALB |

---

## 🏗️ Architecture Flow

```
GitHub Push
    ↓
Jenkins CI (6 Stages): Checkout → SonarQube → OWASP+Trivy → Docker Build → Image Scan → Push
    ↓
Jenkins CD (3 Stages): Deploy to EKS → Verify → Email Notification
    ↓
EKS Cluster: 3 Pods (zomato-app) + HPA (2-5 replicas, 70% CPU)
    ↓
Monitoring: Prometheus + Grafana (Node Exporter)
    ↓
User Access: Custom Domain via Route 53 → ALB → zomato-svc
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Infrastructure** | Terraform, AWS (VPC, EC2, EKS, Route53, ALB) |
| **Configuration** | Ansible |
| **CI/CD** | Jenkins (Separate CI + CD pipelines), GitHub Webhooks |
| **Code Quality** | SonarQube |
| **Security Scanning** | OWASP Dependency Check, Trivy |
| **Containerization** | Docker, DockerHub |
| **Orchestration** | Kubernetes, Amazon EKS |
| **Auto Scaling** | Horizontal Pod Autoscaler (HPA) |
| **Monitoring** | Prometheus, Grafana, Node Exporter |
| **Notifications** | Email (Gmail SMTP) |

---

## 📁 Project Structure

```
terraform-eks-foodapp/
├── terraform/
│   ├── main.tf                    # Root Terraform configuration
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── versions.tf                # Provider & backend config
│   └── modules/
│       ├── vpc/                   # VPC, subnets, IGW, NAT, SGs
│       ├── iam/                   # IAM roles for EKS & Jenkins
│       ├── eks/                   # EKS cluster + node groups
│       └── jenkins-ec2/           # Jenkins EC2 instance
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── site.yml                   # Main playbook
│   └── roles/
│       ├── common/                # Basic packages
│       ├── tools/                 # Docker, kubectl, helm, trivy
│       ├── jenkins/               # Jenkins installation
│       └── sonarqube/             # SonarQube container
│
└── k8s/
    ├── deployment.yaml            # Kubernetes Deployment
    ├── service.yaml               # LoadBalancer Service
    ├── hpa.yaml                   # Horizontal Pod Autoscaler
    ├── ingress.yaml               # Ingress for Zomato App
    └── ingress-monitoring.yaml    # Ingress for Grafana & Prometheus
```

---

## 🚀 Deployment Steps

### Prerequisites

```bash
aws --version
terraform --version
kubectl version --client
helm version
ansible --version
```

---

### Step 1: Provision Infrastructure with Terraform

```bash
cd terraform-eks-foodapp/terraform
terraform init
terraform plan
terraform apply -auto-approve   # ~15-20 minutes
```

**Terraform provisions:**
- VPC with public/private subnets, IGW, and NAT Gateway
- EKS cluster (Kubernetes 1.31)
- 3 worker nodes (t3.medium, on-demand)
- Jenkins EC2 with Elastic IP
- IAM roles and security groups

**Output:**
```bash
jenkins_public_ip = "54.123.45.67"
```

---

### Step 2: Configure Jenkins with Ansible

```bash
cd ../ansible
cat > inventory.ini << EOF
[jenkins_server]
54.123.45.67 ansible_user=ubuntu
EOF

ansible-playbook -i inventory.ini site.yml
```

**Ansible installs:**
- Docker, kubectl, Helm, AWS CLI, Trivy, eksctl
- Jenkins server
- SonarQube container (port 9000)

---

### Step 3: Configure AWS CLI & EKS Access

```bash
ssh -i ~/.ssh/jenkins-key.pem ubuntu@54.123.45.67

aws configure
# Access Key, Secret Key, region: us-east-2

aws eks update-kubeconfig --name eks --region us-east-2
kubectl get nodes   # Should show 3 nodes
```

---

### Step 4: Deploy Monitoring (Prometheus + Grafana)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.service.type=LoadBalancer

kubectl get svc -n monitoring prometheus-grafana -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
kubectl --namespace monitoring get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

**Grafana:** `http://<EXTERNAL-IP>` | **Username:** `admin` | **Password:** (from command)

---

### Step 5: Configure Jenkins

#### 5.1 Access Jenkins
- URL: `http://54.123.45.67:8080`
- Initial password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
- Install suggested plugins, create admin user

#### 5.2 Required Plugins
`Eclipse Temurin Installer`, `NodeJS`, `SonarQube Scanner`, `Docker Pipeline`, `OWASP Dependency-Check`, `Kubernetes CLI`, `Email Extension`, `Pipeline Stage View`

#### 5.3 Global Tools Configuration
**Manage Jenkins → Tools**
| Tool | Name | Install |
|------|------|---------|
| JDK | `jdk17` | Automatically |
| NodeJS | `node23` | Automatically |
| SonarQube Scanner | `sonar-scanner` | Automatically |
| Dependency-Check | `DP-Check` | Automatically |

#### 5.4 Credentials
**Manage Jenkins → Credentials → Global**

| ID | Type | Purpose |
|----|------|---------|
| `docker` | Username+Password | DockerHub credentials |
| `sonar-token` | Secret Text | SonarQube token |
| `aws-creds` | Username+Password | AWS Access/Secret Key |
| `email-cred` | Username+Password | Gmail + App Password |

#### 5.5 SonarQube Configuration
**Manage Jenkins → System → SonarQube servers**
- Name: `sonar-server`
- URL: `http://<jenkins-ip>:9000`
- Credential: `sonar-token`

#### 5.6 Email Configuration
**Manage Jenkins → System → Extended E-mail Notification**
- SMTP: `smtp.gmail.com:465` (SSL)
- Credential: `email-cred`

#### 5.7 Pipeline Jobs
- Create `zomato-ci` (CI pipeline)
- Create `zomato-cd` (CD pipeline)

#### 5.8 Webhooks
- **GitHub:** `http://<jenkins-ip>:8080/github-webhook/`
- **SonarQube:** `http://<jenkins-ip>:8080/sonarqube-webhook/`

---

### Step 6: Deploy Application

Push code to GitHub → Jenkins triggers pipeline → Application deploys to EKS.

```bash
kubectl get svc -n zomato zomato-svc
# Access: http://<EXTERNAL-IP>
```

---

### Step 7: Ingress & Route53 (One-Time)

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks \
  --set serviceAccount.create=true \
  --set region=us-east-2

# Apply Ingress
kubectl apply -f ingress.yaml
kubectl apply -f ingress-monitoring.yaml

# Get ALB URL
kubectl get ingress -n zomato -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}"
```

1. AWS Console → Route 53 → Hosted Zone
2. Create A Record → Alias → Paste ALB URL

**Access:** `http://zomato.yourdomain.com`

---

### Step 8: Clean Up

```bash
kubectl delete namespace zomato monitoring
cd terraform
terraform destroy -auto-approve
```

---

## 🔄 CI/CD Pipeline Stages

### CI Pipeline (6 Stages)

| # | Stage | Tool | Purpose |
|---|-------|------|---------|
| 1 | Code Checkout | Git | Pull latest code |
| 2 | Static Code Analysis | SonarQube | Code quality & bug detection |
| 3 | Security Scanning | OWASP + Trivy | Dependency & filesystem vulnerability scan |
| 4 | Docker Build | Docker | Create container image |
| 5 | Image Security Scan | Trivy | Scan container for CVEs |
| 6 | Push to Registry | DockerHub | Store image & trigger CD |

### CD Pipeline (3 Stages)

| # | Stage | Purpose |
|---|-------|---------|
| 1 | Deploy to EKS | `kubectl apply -f` deployment, service, hpa |
| 2 | Verify Deployment | `kubectl rollout status` |
| 3 | Email Notification | Success/Failure alert |

---

## 📸 Screenshots

| # | Component | Screenshot |
|---|-----------|------------|
| 1 | Terraform Apply | ![Terraform](images/terraform-apply.png) |
| 2 | Ansible Run | ![Ansible](images/ansible-run.png) |
| 3 | Jenkins Pipeline | ![Jenkins](images/jenkins-pipeline.png) |
| 4 | SonarQube Quality Gate | ![SonarQube](images/sonarqube-gate.png) |
| 5 | DockerHub Repository | ![DockerHub](images/dockerhub.png) |
| 6 | Kubernetes Pods | ![Pods](images/kubectl-pods.png) |
| 7 | LoadBalancer Service | ![Service](images/kubectl-svc.png) |
| 8 | HPA Auto-Scaling | ![HPA](images/hpa.png) |
| 9 | Application Live | ![App](images/app-live.png) |
| 10 | Prometheus Targets | ![Prometheus](images/prometheus-targets.png) |
| 11 | Grafana Dashboard | ![Grafana](images/grafana-dashboard.png) |
| 12 | Email Notification | ![Email](images/email-notification.png) |

---

## 📊 Monitoring

### Prometheus Targets
- Prometheus (self)
- Node Exporter (cluster nodes)
- Kubernetes API server
- CoreDNS
- kubelet

### Grafana Dashboards
| Dashboard ID | Name | Purpose |
|--------------|------|---------|
| 1860 | Node Exporter Full | Node CPU, memory, disk, network |
| 9964 | Jenkins Performance | Build times, job health |

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| `kubectl get nodes` returns Unauthorized | Wait 60s for IAM role propagation |
| OWASP scan takes >1 hour | Add NVD API key: `--nvdApiKey YOUR_KEY` |
| SonarQube container stops | `docker run -d --name sonar --restart always -p 9000:9000 sonarqube:lts-community` |
| EKS LoadBalancer stuck deleting | Delete Kubernetes namespaces before `terraform destroy` |
| Jenkins cannot access Docker | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |

---

## 🚀 Future Scope

- [ ] GitOps with ArgoCD
- [ ] SSL/TLS with AWS ACM + Ingress Controller
- [ ] Centralized logging with ELK Stack
- [ ] Blue-Green deployment strategy
- [ ] Terraform remote state in S3 with DynamoDB locking
- [ ] Alertmanager integration with Slack

---

## 🏆 Skills Demonstrated

| Skill | Implementation |
|-------|----------------|
| **Infrastructure as Code** | Terraform for VPC, EKS, EC2, IAM |
| **Configuration Management** | Ansible for Jenkins, Docker, SonarQube |
| **CI/CD Pipeline Design** | Jenkins with GitHub webhook trigger |
| **Kubernetes Administration** | EKS with HPA, Ingress, LoadBalancer |
| **DevSecOps** | SonarQube + OWASP + Trivy integration |
| **Monitoring & Observability** | Prometheus + Grafana with custom dashboards |
| **AWS Services** | EC2, EKS, VPC, Route53, ALB, IAM |
| **Docker Containerization** | Dockerfile, image building, DockerHub |

---

## 📫 Connect

**Harshal Gharat**  
DevOps Engineer | Kubernetes | AWS | DevSecOps

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin)](https://www.linkedin.com/in/harshalgharat01/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?logo=github)](https://github.com/harshal019)

---

**⭐ If this project helped you, please give it a star on GitHub!**