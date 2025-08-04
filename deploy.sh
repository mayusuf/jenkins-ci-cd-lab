#!/bin/bash

# Deployment script for Ubuntu EC2
# This script will be executed by Jenkins to deploy the application

set -e  # Exit on any error

# Configuration
APP_NAME="calculator-app"
DEPLOY_DIR="/opt/${APP_NAME}"
BACKUP_DIR="/opt/${APP_NAME}-backup"
LOG_FILE="/var/log/${APP_NAME}/deploy.log"
SERVICE_USER="ubuntu"  # Use ubuntu user instead of root for security

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || {
    # If we can't create the log directory, use a local one
    LOG_FILE="./deploy.log"
    mkdir -p "$(dirname "$LOG_FILE")"
}

log "Starting deployment process for Ubuntu EC2..."

# Check if we're running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    log "Running as root"
elif command -v sudo >/dev/null 2>&1; then
    log "Running with sudo"
    # Try to run with sudo, but handle password prompt gracefully
    if sudo -n true 2>/dev/null; then
        # Can run sudo without password
        exec sudo "$0" "$@"
    else
        error "Sudo requires password. Please configure Jenkins to run sudo without password:"
        error "1. SSH into EC2: ssh -i your-key.pem ubuntu@your-ec2-ip"
        error "2. Run: sudo visudo"
        error "3. Add line: jenkins ALL=(ALL) NOPASSWD: ALL"
        error "4. Save and exit"
        exit 1
    fi
else
    error "This script must be run as root or with sudo"
    exit 1
fi

# Ensure required packages are installed (Ubuntu specific)
log "Checking and installing required packages..."
apt-get update -qq
apt-get install -y python3 python3-pip python3-venv curl systemd-sysv || {
    error "Failed to install required packages"
    exit 1
}

# Stop the application if it's running
log "Stopping existing application..."
if systemctl is-active --quiet "${APP_NAME}" 2>/dev/null; then
    systemctl stop "${APP_NAME}"
    log "Application stopped"
else
    log "Application was not running"
fi

# Create backup of current deployment
if [ -d "$DEPLOY_DIR" ]; then
    log "Creating backup of current deployment..."
    rm -rf "$BACKUP_DIR"
    cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
    log "Backup created at $BACKUP_DIR"
fi

# Create deployment directory
log "Creating deployment directory..."
mkdir -p "$DEPLOY_DIR"

# Copy application files
log "Copying application files..."
cp -r . "$DEPLOY_DIR/" || {
    error "Failed to copy application files"
    exit 1
}

# Set proper permissions for Ubuntu
log "Setting permissions..."
chown -R ${SERVICE_USER}:${SERVICE_USER} "$DEPLOY_DIR"
chmod -R 755 "$DEPLOY_DIR"

# Install Python dependencies
log "Installing Python dependencies..."
cd "$DEPLOY_DIR" || {
    error "Failed to change to deployment directory"
    exit 1
}

# Create virtual environment
python3 -m venv venv || {
    error "Failed to create virtual environment"
    exit 1
}

# Activate virtual environment and install dependencies
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt || {
    error "Failed to install Python dependencies"
    exit 1
}

# Run tests to ensure everything works
log "Running tests..."
python -m pytest tests/ -v || {
    error "Tests failed - deployment aborted"
    exit 1
}

# Create systemd service file (Ubuntu optimized)
log "Creating systemd service..."
cat > "/etc/systemd/system/${APP_NAME}.service" << EOF
[Unit]
Description=Calculator Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=$DEPLOY_DIR
Environment=PATH=$DEPLOY_DIR/venv/bin
Environment=PYTHONPATH=$DEPLOY_DIR
ExecStart=$DEPLOY_DIR/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DEPLOY_DIR

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions for systemd service file
chmod 644 "/etc/systemd/system/${APP_NAME}.service"

# Reload systemd and enable service
log "Enabling and starting service..."
systemctl daemon-reload
systemctl enable "${APP_NAME}"
systemctl start "${APP_NAME}"

# Wait for service to start
sleep 10

# Check if service is running
if systemctl is-active --quiet "${APP_NAME}"; then
    log "Application started successfully"
    
    # Test the application
    log "Testing application..."
    if curl -f http://localhost:8081 > /dev/null 2>&1; then
        log "Application is responding correctly"
    else
        warning "Application might not be responding correctly"
        log "Checking service logs..."
        journalctl -u "${APP_NAME}" --no-pager -n 20
    fi
else
    error "Failed to start application"
    log "Service status:"
    systemctl status "${APP_NAME}" --no-pager
    log "Service logs:"
    journalctl -u "${APP_NAME}" --no-pager -n 20
    exit 1
fi

# Clean up old backups (keep only last 5)
log "Cleaning up old backups..."
cd /opt
ls -dt ${APP_NAME}-backup* 2>/dev/null | tail -n +6 | xargs -r rm -rf

# Final status check
log "Deployment completed successfully!"
log "Application is running on http://localhost:8081"
log "Service status: $(systemctl is-active ${APP_NAME})"
log "Service logs: journalctl -u ${APP_NAME} -f"

# Optional: Send notification
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"Deployment completed successfully!"}' \
#   https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

exit 0 