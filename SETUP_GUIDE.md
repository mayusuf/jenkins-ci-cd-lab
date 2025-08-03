# Jenkins CI/CD Pipeline Setup Guide

This guide will help you set up a complete CI/CD pipeline using Jenkins on EC2 to fetch code from GitHub, test it, and deploy it.

## 📋 Prerequisites

### 1. EC2 Instance Setup
- **OS**: Ubuntu 20.04 LTS or Amazon Linux 2
- **Instance Type**: t2.medium or larger (recommended)
- **Security Group**: Open ports 22 (SSH), 8080 (Jenkins), 80 (HTTP), 443 (HTTPS)

### 2. Required Software on EC2
- Java 11 or higher
- Python 3.8+
- Git
- Docker (optional, for containerized deployment)

## 🚀 Step-by-Step Setup

### Step 1: Install Jenkins on EC2

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java
sudo apt install openjdk-11-jdk -y

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2: Configure Jenkins

1. **Access Jenkins**: Open `http://your-ec2-public-ip:8080`
2. **Install Suggested Plugins**:
   - Pipeline
   - Git Integration
   - GitHub Integration
   - Blue Ocean
   - HTML Publisher
   - JUnit
   - Coverage Report

3. **Create Admin User**:
   - Username: `admin`
   - Password: `your-secure-password`

### Step 3: Configure GitHub Integration

1. **In Jenkins**:
   - Go to `Manage Jenkins` → `Configure System`
   - Add GitHub server
   - Add GitHub credentials (Personal Access Token)

2. **Create GitHub Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` and `admin:repo_hook` permissions

### Step 4: Create Jenkins Pipeline Job

1. **Create New Item**:
   - Click "New Item"
   - Name: `calculator-pipeline`
   - Type: `Pipeline`
   - Click OK

2. **Configure Pipeline**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/mayusuf/jenkins-ci-cd-lab.git`
   - **Credentials**: Add your GitHub credentials
   - **Branch Specifier**: `*/main` or `*/master`
   - **Script Path**: `Jenkinsfile`

3. **Build Triggers**:
   - ✅ Poll SCM (every 5 minutes)
   - ✅ GitHub hook trigger for GITScm polling

### Step 5: Push Code to GitHub

```bash
# Create GitHub repository
# Then push your code:

git remote add origin https://github.com/mayusuf/jenkins-ci-cd-lab.git
git branch -M main
git push -u origin main
```

### Step 6: Configure Webhook (Optional)

1. **In GitHub Repository**:
   - Go to Settings → Webhooks
   - Add webhook: `http://your-jenkins-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Events: `Just the push event`

## 🔧 Pipeline Stages

The pipeline includes the following stages:

1. **Checkout**: Fetches code from GitHub
2. **Setup Virtual Environment**: Creates Python virtual environment
3. **Lint**: Runs code linting with flake8
4. **Test**: Runs unit tests with coverage
5. **Build Package**: Creates distributable package
6. **Security Scan**: Runs security vulnerability scan
7. **Deploy**: Deploys to EC2 (only on main branch)

## 🚀 Deployment Configuration

### Option 1: Direct EC2 Deployment

The `deploy.sh` script will:
- Stop existing application
- Create backup
- Copy new files
- Install dependencies
- Run tests
- Create systemd service
- Start application

### Option 2: Docker Deployment

```dockerfile
# Dockerfile (optional)
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8080

CMD ["python", "app.py"]
```

## 📊 Monitoring and Notifications

### 1. Jenkins Dashboard
- Build history
- Test results
- Coverage reports
- Build artifacts

### 2. Application Monitoring
- Health check: `http://your-ec2-ip:8080/health`
- Application: `http://your-ec2-ip:8080`

### 3. Notifications (Optional)
- Email notifications
- Slack integration
- Teams integration

## 🔍 Troubleshooting

### Common Issues:

1. **Jenkins can't access GitHub**:
   - Check credentials
   - Verify network connectivity
   - Check security groups

2. **Build fails**:
   - Check Jenkins logs
   - Verify Python dependencies
   - Check file permissions

3. **Deployment fails**:
   - Check EC2 instance status
   - Verify SSH access
   - Check systemd service logs

### Useful Commands:

```bash
# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check application status
sudo systemctl status calculator-app

# View application logs
sudo journalctl -u calculator-app -f

# Test application
curl http://localhost:8080/health
```

## 📈 Advanced Features

### 1. Blue Ocean Pipeline
- Visual pipeline editor
- Better build visualization
- Interactive pipeline creation

### 2. Parallel Testing
```groovy
stage('Test') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'python -m pytest tests/unit/'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'python -m pytest tests/integration/'
            }
        }
    }
}
```

### 3. Environment-Specific Deployments
```groovy
stage('Deploy to Staging') {
    when {
        branch 'develop'
    }
    steps {
        // Deploy to staging
    }
}

stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        // Deploy to production
    }
}
```

## 🎯 Next Steps

1. **Set up monitoring** (Prometheus, Grafana)
2. **Add security scanning** (SonarQube, OWASP ZAP)
3. **Implement rollback strategy**
4. **Add performance testing**
5. **Set up backup and disaster recovery**

## 📞 Support

For issues or questions:
1. Check Jenkins logs
2. Review pipeline configuration
3. Verify GitHub webhook settings
4. Test deployment script manually

---

**Happy CI/CD! 🚀** 