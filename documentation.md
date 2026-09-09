# Complete DevOps Pipeline for Zomato Food Delivery Application

## 📌 Overview

This guide walks you through building a **production-grade DevOps pipeline** for a food delivery application. You will:

- Provision AWS infrastructure (VPC, EKS, EC2) using **Terraform**
- Automate configuration of Jenkins, SonarQube, Docker, kubectl, Helm with **Ansible**
- Build a **Jenkins CI/CD pipeline** with 6 stages: code checkout → SonarQube analysis → OWASP scan → Trivy scan → Docker build & push → deploy to EKS
- Deploy the application on **Amazon EKS** with Kubernetes Deployments, Services, and Horizontal Pod Autoscaler (HPA)
- Monitor the cluster with **Prometheus & Grafana** (deployed via Helm)
- Set up **email notifications** and **GitHub webhooks** for automated triggers
- Configure **Ingress** and **Route53** for custom domain access

By the end, every `git push` will automatically build, test, scan, and deploy your application to a scalable Kubernetes cluster.

---

## 🧰 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| AWS Account | – | Host all resources |
| Terraform | >= 1.9 | Infrastructure as Code |
| AWS CLI | latest | Interact with AWS |
| kubectl | >= 1.31 | Manage Kubernetes |
| eksctl | latest | Create EKS cluster (optional if using Terraform) |
| Ansible | >= 2.16 | Configuration management |
| GitHub account | – | Store source code |
| Domain name (optional) | – | Custom URL via Route53 |

Install these on your **local machine** (or a jump host with internet access).

---

## 📁 Project Structure

```
terraform-eks-foodapp/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
├── modules/
│   ├── vpc/               # VPC, subnets, IGW, NAT, security groups
│   ├── iam/               # IAM roles for EKS, node groups, Jenkins
│   ├── eks/               # EKS cluster + node groups (on-demand)
│   └── jenkins-ec2/       # Jenkins server EC2
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── site.yml
│   └── roles/
│       ├── common/        # basic packages
│       ├── tools/         # Docker, kubectl, helm, trivy, awscli
│       ├── jenkins/       # Jenkins installation + docker group
│       ├── sonarqube/     # SonarQube container
│       └── monitoring/    # (optional) Prometheus+Grafana on EKS
└── k8s/
    ├── deployment.yaml    # Kubernetes Deployment
    ├── service.yaml       # LoadBalancer Service
    ├── hpa.yaml           # Horizontal Pod Autoscaler
    ├── ingress.yaml       # Ingress for Zomato App
    └── ingress-monitoring.yaml  # Ingress for Grafana & Prometheus
```

You can clone the complete repository from:
`https://github.com/harshal019/terraform-eks-foodapp` (example)

---

## 🚀 Step 1: Provision AWS Infrastructure with Terraform

### 1.1 Configure AWS credentials
```bash
aws configure
# Enter your Access Key, Secret Key, region: us-east-2, output: json
```

### 1.2 Clone and prepare Terraform
```bash
git clone https://github.com/harshal019/terraform-eks-foodapp.git
cd terraform-eks-foodapp/terraform
```

### 1.3 Customize variables (`terraform.tfvars`)
```hcl
aws_region      = "us-east-2"
environment     = "dev"
project_name    = "foodapp"
jenkins_instance_type = "t3.medium"
ssh_public_key_path   = "~/.ssh/id_rsa.pub"   # your SSH public key
eks_desired_size = 3
eks_min_size     = 2
eks_max_size     = 5
eks_instance_types = ["t3.medium"]
```

### 1.4 Initialize and apply
```bash/home/harshal/Documents/Devops/Devops-projects/food-delivery-devops-microservices/documentation.md
terraform init
terraform plan
terraform apply -auto-approve
```

**What gets created (15‑20 minutes):**
- VPC with 2 public + 2 private subnets
- Internet Gateway, NAT Gateway
- Security groups for EKS and Jenkins
- IAM roles for EKS cluster, node groups, Jenkins EC2
- EKS cluster (Kubernetes 1.31) with 3 worker nodes
- Jenkins EC2 instance with public IP and Elastic IP

**Important output:**
```bash
jenkins_public_ip = "54.123.45.67"
```
Save this IP – you will need it for the next steps.

---

## ⚙️ Step 2: Configure Jenkins & Tools with Ansible

Ansible will automatically install all required software on the Jenkins server.

### 2.1 Prepare Ansible inventory
```bash
cd ../ansible
echo "[jenkins_server]" > inventory.ini
echo "54.123.45.67 ansible_user=ubuntu" >> inventory.ini
```

### 2.2 Run the main playbook
```bash
ansible-playbook -i inventory.ini site.yml
```

**What the playbook does:**
- `common`: updates system, installs `curl`, `git`, `python3`
- `tools`: installs `docker`, `kubectl`, `helm`, `awscli`, `trivy`, `eksctl`
- `jenkins`: installs Jenkins, adds `jenkins` user to `docker` group, starts service
- `sonarqube`: runs SonarQube container on port 9000 with auto‑restart

**After completion:**
- Jenkins URL: `http://jenkins_ip:8080`
- SonarQube URL: `http://jenkins_ip:9000` (admin/admin)

### 2.3 One‑time manual fix (IAM propagation for EKS)
Ansible cannot immediately attach EKS permissions because IAM roles take 1‑2 minutes to propagate. Run this once on the Jenkins server:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67
aws eks update-kubeconfig --name eks --region us-east-2
kubectl get nodes   # Should show 3 nodes
exit
```

> **Troubleshooting:** If `kubectl get nodes` returns `Unauthorized`, wait 60 seconds and retry. The IAM role attached to the Jenkins EC2 already has `AmazonEKSClusterPolicy` and `AmazonEKSWorkerNodePolicy`.

---

## 🔧 Step 3: Configure Jenkins UI (Plugins, Tools, Credentials)

### 3.1 Access Jenkins
- Open `http://jenkins_ip:8080`
- Unlock with initial password:
  ```bash
  ssh ubuntu@54.123.45.67 "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  ```
- Install suggested plugins, create admin user

### 3.2 Install required plugins
Go to **Manage Jenkins → Plugins → Available plugins** and install:

| Plugin | Purpose |
|--------|---------|
| Eclipse Temurin Installer | JDK 17 |
| NodeJS Plugin | Node.js 23 |
| SonarQube Scanner | Code analysis |
| Docker Pipeline | Docker build/push steps |
| OWASP Dependency-Check | Vulnerability scanning |
| Kubernetes CLI | kubectl commands |
| Email Extension | Email notifications |
| Pipeline Stage View | Better UI |

Restart Jenkins after installation.

### 3.3 Configure global tools
**Manage Jenkins → Tools**

| Tool | Name | Install automatically | Version |
|------|------|----------------------|---------|
| JDK | `jdk17` | Yes (from Adoptium) | latest 17 |
| NodeJS | `node23` | Yes | NodeJS 23.7.0 |
| SonarQube Scanner | `sonar-scanner` | Yes | latest |
| Dependency-Check | `DP-Check` | Yes | 12.0.2 |

### 3.4 Add SonarQube server
**Manage Jenkins → System → SonarQube servers**
- Name: `sonar-server`
- Server URL: `http://jenkins_ip:9000`
- Add credential: **Secret text** (create token in SonarQube: Administration → Security → Users → Tokens → generate, copy)
- Save

### 3.5 Create credentials
**Manage Jenkins → Credentials → Global → Add Credentials**

| ID | Kind | Value |
|----|------|-------|
| `docker` | Username with password | DockerHub username & password |
| `sonar-token` | Secret text | SonarQube token (from above) |
| `aws-creds` | Username with password | AWS Access Key ID & Secret Key |
| `email-cred` | Username with password | Gmail address & **App Password** |

> **Gmail App Password:** Enable 2‑Factor Authentication on your Google account, then go to Security → App passwords → generate a 16‑character password for "Jenkins". Use that as the password.

### 3.6 Configure email notifications
**Manage Jenkins → System → Extended E-mail Notification**
- SMTP server: `smtp.gmail.com`
- SMTP Port: `465`
- Use SSL: ✅ Yes
- Use SMTP Authentication: ✅ Yes
- Credentials: `email-cred`
- Default Content Type: `HTML`
- Default Triggers: Always, Failure, Success, Unstable

Test the configuration by sending a test email.

---

## 🌐 Step 4: Create GitHub & SonarQube Webhooks

### 4.1 GitHub webhook (triggers CI pipeline on push)
1. Go to your GitHub repository → **Settings → Webhooks → Add webhook**
2. Payload URL: `http://jenkins_ip:8080/github-webhook/`
3. Content type: `application/json`
4. Events: **Just the push event**
5. Click **Add webhook**

### 4.2 SonarQube webhook (sends quality gate result to Jenkins)
1. Open SonarQube: `http://jenkins_ip:9000` (admin/admin)
2. Go to **Administration → Configuration → Webhooks**
3. Name: `Jenkins`
4. URL: `http://54.123.45.67:8080/sonarqube-webhook/`
5. No secret → **Create**

---

## 🔁 Step 5: Create CI Pipeline (Staging)

Create a new Pipeline job in Jenkins named `zomato-staging`.

### Jenkinsfile (CI)
```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node23'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('Clean Workspace') { steps { cleanWs() } }
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/food-delivery-app.git'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=zomato \
                        -Dsonar.projectKey=zomato
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
            }
        }
        stage('Install Dependencies') {
            steps {
                dir('app') { sh 'npm install' }
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./app --out .', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('Trivy File Scan') {
            steps { sh 'trivy fs . > trivy.txt' }
        }
        stage('Build Docker Image') {
            steps { sh 'docker build -t zomato -f docker/Dockerfile .' }
        }
        stage('Trivy Image Scan') {
            steps { sh 'trivy image zomato > trivy-image.txt || true' }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag zomato yourdockerhub/zomato-app:latest
                        docker push yourdockerhub/zomato-app:latest
                        docker logout
                    '''
                }
            }
        }
        stage('Trigger CD') {
            steps { build job: 'zomato-cd', wait: false }
        }
    }
    post {
        always {
            emailext(
                subject: "${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build URL: ${env.BUILD_URL}",
                to: 'your-email@gmail.com'
            )
        }
    }
}
```

**Important:** Replace `your-org`, `yourdockerhub`, and email address.

---

## ☸️ Step 6: Kubernetes Manifests

Create a folder `k8s/` in your GitHub repository with the following files.

### `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zomato-app
  namespace: zomato
spec:
  replicas: 3
  selector:
    matchLabels:
      app: zomato-app
  template:
    metadata:
      labels:
        app: zomato-app
    spec:
      containers:
      - name: zomato
        image: yourdockerhub/zomato-app:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### `service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: zomato-svc
  namespace: zomato
spec:
  type: LoadBalancer
  selector:
    app: zomato-app
  ports:
  - port: 80
    targetPort: 3000
```

### `hpa.yaml`
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: zomato-hpa
  namespace: zomato
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: zomato-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### `ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zomato-ingress
  namespace: zomato
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  ingressClassName: alb
  rules:
    - host: zomato.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: zomato-svc
                port:
                  number: 80
```

### `ingress-monitoring.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: grafana.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
    - host: prometheus.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
```

---

## 🚢 Step 7: Create CD Pipeline (Production)

Create a second Pipeline job named `zomato-prod`.

### Jenkinsfile (CD)
```groovy
pipeline {
    agent any
    environment {
        EKS_CLUSTER_NAME = 'eks'
        AWS_REGION = 'us-east-2'
        NAMESPACE = 'zomato'
    }
    stages {
        stage('Clean') { steps { cleanWs() } }
        stage('Git Checkout') {
            steps { git branch: 'main', url: 'https://github.com/your-org/food-delivery-app.git' }
        }
        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
                        kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                    '''
                    dir('k8s') {
                        sh '''
                            kubectl apply -f deployment.yaml -n $NAMESPACE
                            kubectl apply -f service.yaml -n $NAMESPACE
                            kubectl apply -f hpa.yaml -n $NAMESPACE
                        '''
                    }
                }
            }
        }
        stage('Verify') {
            steps {
                sh '''
                    kubectl rollout status deployment/zomato-app -n $NAMESPACE --timeout=5m
                    kubectl get pods -n $NAMESPACE
                    kubectl get svc -n $NAMESPACE
                '''
            }
        }
    }
    post {
        always {
            emailext(
                subject: "CD ${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Deployment URL: ${env.BUILD_URL}",
                to: 'your-email@gmail.com'
            )
        }
    }
}
```

---

## 📊 Step 8: Monitoring with Prometheus & Grafana

Run this **once** on the Jenkins server (SSH):

```bash
ssh ubuntu@54.123.45.67
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer

# Get Grafana LoadBalancer URL
kubectl get svc -n monitoring prometheus-grafana
```

Access Grafana at `http://<EXTERNAL-IP>` (username `admin`, password `admin123`).

The stack includes default alerts for:
- Pod restarts
- High CPU/memory usage
- Node failures

---

## 🌐 Step 9: Ingress & Route53 (One-Time Setup)

### 9.1 Install AWS Load Balancer Controller
```bash
ssh ubuntu@54.123.45.67

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks \
  --set serviceAccount.create=true \
  --set region=us-east-2
```

### 9.2 Apply Ingress Resources
```bash
kubectl apply -f ingress.yaml
kubectl apply -f ingress-monitoring.yaml

# Verify ingress
kubectl get ingress -n zomato
kubectl get ingress -n monitoring
```

### 9.3 Configure Route53 (Manual)
```bash
# Get ALB URL
kubectl get ingress -n zomato -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}" ; echo
```

1. Go to AWS Console → Route 53 → Your Hosted Zone
2. Create **A Record** → **Alias**
3. Alias target: Paste the ALB URL

**Now access your services via custom domain:**
- `http://zomato.yourdomain.com`
- `http://grafana.yourdomain.com`
- `http://prometheus.yourdomain.com`

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| `kubectl get nodes` returns Unauthorized | Wait 60s for IAM role propagation |
| OWASP scan takes >1 hour | Add NVD API key: `--nvdApiKey YOUR_KEY` |
| SonarQube container stops | `docker run -d --name sonar --restart always -p 9000:9000 sonarqube:lts-community` |
| EKS LoadBalancer stuck deleting | Delete Kubernetes namespaces before `terraform destroy` |
| Jenkins cannot access Docker | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |
| GitHub webhook not triggering | Check Jenkins URL is publicly accessible |
| Ingress not routing traffic | Verify AWS Load Balancer Controller is installed correctly |

---

## 🧹 Step 10: Clean Up Resources

To avoid ongoing charges, destroy everything when not in use.

```bash
# Delete Kubernetes resources
kubectl delete namespace zomato monitoring

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve
```

---

## ✅ Final Checklist

| Task | Status |
|------|--------|
| Terraform apply successful | ☐ |
| Ansible playbook runs without errors | ☐ |
| Jenkins accessible at `http://<ip>:8080` | ☐ |
| SonarQube accessible at `http://<ip>:9000` | ☐ |
| Jenkins plugins and tools configured | ☐ |
| GitHub webhook added | ☐ |
| SonarQube webhook added | ☐ |
| CI pipeline (staging) runs and builds Docker image | ☐ |
| CD pipeline (production) deploys to EKS | ☐ |
| Application accessible via LoadBalancer URL | ☐ |
| Prometheus+Grafana deployed and accessible | ☐ |
| Email notifications received | ☐ |
| AWS Load Balancer Controller installed | ☐ |
| Ingress resources applied | ☐ |
| Route53 custom domain configured | ☐ |

---

## 📸 Screenshots (Optional)

Create `images/` folder in your repository and add:

| # | Screenshot | What It Proves |
|---|------------|----------------|
| 1 | Terraform Apply | Infrastructure as Code |
| 2 | Ansible Run | Configuration automation |
| 3 | Jenkins Pipeline | CI/CD working |
| 4 | SonarQube Gate | Code quality checks |
| 5 | DockerHub | Image pushed |
| 6 | Running Pods | Kubernetes deployment |
| 7 | LoadBalancer Service | External access |
| 8 | HPA | Auto-scaling |
| 9 | Application Live | App works |
| 10 | Prometheus Targets | Monitoring active |
| 11 | Grafana Dashboard | Metrics visualization |
| 12 | Email Notification | Alerts configured |
| 13 | Route53 Record | Custom domain mapped |

---

## 📝 License

This project is for educational purposes. All code and configurations are open for learning.

---

**⭐ If you found this project helpful, please give it a star on GitHub!**