# 🍔 Online Food Ordering & Delivery Application  
## 🚀 End-to-End DevSecOps Implementation on AWS EKS

![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Cluster-blue)
![CI/CD](https://img.shields.io/badge/CI/CD-Jenkins-red)
![Security](https://img.shields.io/badge/DevSecOps-Integrated-success)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-yellow)

---

# 📌 Project Overview

This project demonstrates a **production-grade DevSecOps implementation** of an Online Food Ordering & Delivery Application deployed on AWS.

The system includes:

- CI/CD automation using Jenkins
- Security scanning using SonarQube, OWASP & Trivy
- Docker containerization
- Kubernetes deployment on Amazon EKS
- Horizontal Pod Autoscaling (HPA)
- Monitoring using Prometheus & Grafana
- Custom Domain mapping using Route 53

This project showcases automation, scalability, security, and monitoring in a real-world cloud environment.

---

# 🔗 Source Code Repository

Application Repository:  
https://github.com/harshal019/food-delivery-devops-microservices.git

---

# 🎯 Project Objectives

- Automate build & deployment
- Implement secure CI pipeline
- Deploy to Kubernetes (EKS)
- Separate Staging & Production pipelines
- Enable Horizontal Pod Autoscaling
- Monitor application health
- Configure email notifications
- Enable rollback capability

---

# 🏗️ High-Level Architecture



---

# 🛠️ Tools & Services Used

| Category | Tool |
|----------|------|
| Source Control | GitHub |
| CI/CD | Jenkins |
| Code Quality | SonarQube |
| Dependency Scan | OWASP Dependency-Check |
| Container Scan | Trivy |
| Containerization | Docker |
| Cloud | AWS |
| Kubernetes | Amazon EKS |
| Monitoring | Prometheus |
| Dashboards | Grafana |
| DNS | Route 53 |
| Registry | DockerHub |
| Load Balancer | AWS ALB |

---

# ☁️ Infrastructure Setup

## EC2 (CI Server)

- Ubuntu 24.04
- Instance type: t2.large
- 29 GB storage
- Open Ports:
  - 8080 (Jenkins)
  - 9000 (SonarQube)
  - 3000 (Application)
  - 9090 (Prometheus)
  - 30000–32767 (NodePort)

---

# 🔐 IAM Setup

- Created IAM User for EKS
- Attached required policies:
  - AmazonEC2FullAccess
  - AmazonEKSClusterPolicy
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AWSCloudFormationFullAccess
  - IAMFullAccess
- Generated Access Keys for CLI usage

---

# 🚀 EKS Cluster Setup

## 📌 Create Cluster

```bash
eksctl create cluster --name=zomato-cluster \
--region=us-east-2 \
--zones=us-east-2a,us-east-2b \
--version=1.30 \
--without-nodegroup

```

## Create Managed Node 

```bash
eksctl create nodegroup \
--cluster=zomato-cluster \
--region=us-east-2 \
--name=nodes \
--node-type=t3.medium \
--nodes=3 \
--nodes-min=2 \
--nodes-max=4 \
--node-volume-size=20 \
--managed


## Update kubeconfig

```bash
aws eks update-kubeconfig --name zomato-cluster --region us-east-2



# CI Pipeline – Staging

## Stages Implemented

1.Clean Workspace

2.Git Checkout

3.SonarQube Analysis

4.Quality Gate Validation

5.Install Dependencies

6.OWASP Dependency Scan

7.Trivy File Scan

8.Docker Build

9.Docker Image Scan

10.Push Image to DockerHub

11.Run Container (Testing)

✔ Security integrated
✔ Quality validation
✔ Email notification configured


#🚀 CD Pipeline – Production

## Flow

Staging Success
→ Production Pipeline
→ Configure kubeconfig
→ Apply Kubernetes Manifests
→ Verify Deployment
→ Application Live

# 📦 Kubernetes Configuration

- deployment.yml – Defines replicas & container configuration

- service.yml – Exposes application via LoadBalancer

- hpa.yml – Enables auto scaling based on CPU usage

Check Resources:

```bash
kubectl get pods
kubectl get svc
kubectl get hpa


# 📈 Horizontal Pod Autoscaler (HPA)

Minimum Pods: 2

Maximum Pods: 4

CPU-based scaling enabled

# 📊 Monitoring & Observability

Monitoring Stack:

Prometheus (Port 9090)

Node Exporter

Grafana (Port 3000)


# Dashboards Imported

Node Exporter Dashboard (ID: 1860)

Jenkins Monitoring Dashboard (ID: 9964)

Grafana Default Login:

Username: admin
Password: admin


# 🌐 Custom Domain Setup

AWS Application Load Balancer

Route 53 Hosted Zone

A Record (Alias) mapping to ALB

Example:

http://zomato.harshalgharat.site/


# 🔔 Email Notifications

Configured using:

Gmail App Password

Extended Email Plugin

HTML Email Template

Security scan reports attached

Triggers:

Always

Success

Failure

# 🔐 Security Implementation
Layer	Tool
Code Quality	SonarQube
Dependency Security	OWASP
Container Security	Trivy
IAM Control	AWS IAM
Auto Scaling	HPA

🏆 Skills Demonstrated

DevOps Automation

Kubernetes Administration

CI/CD Pipeline Design

AWS Cloud Infrastructure

Monitoring & Observability

DevSecOps Implementation

Production Deployment

# 👨‍💻 Author

## Harshal
DevOps Engineer | Cloud Enthusiast | CI/CD Practitioner


---