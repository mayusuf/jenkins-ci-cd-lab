#!/bin/bash

# Deployment script for EC2
# This script will be executed by Jenkins to deploy the application

set -e  # Exit on any error

# Configuration
APP_NAME="calculator-app"
DEPLOY_DIR="/opt/${APP_NAME}"
BACKUP_DIR="/opt/${APP_NAME}-backup"
LOG_FILE="/var/log/${APP_NAME}/deploy.log"

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
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting deployment process..."

# Check if we're running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    log "Running as root"
elif command -v sudo >/dev/null 2>&1; then
    log "Running with sudo"
    # Re-run the script with sudo
    exec sudo "$0" "$@"
else
    error "This script must be run as root or with sudo"
    exit 1
fi

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

# Set proper permissions
log "Setting permissions..."
chown -R root:root "$DEPLOY_DIR"
chmod -R 755 "$DEPLOY_DIR"

# Install Python dependencies
log "Installing Python dependencies..."
cd "$DEPLOY_DIR" || {
    error "Failed to change to deployment directory"
    exit 1
}
python3 -m venv venv || {
    error "Failed to create virtual environment"
    exit 1
}
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

# Create systemd service file
log "Creating systemd service..."
cat > "/etc/systemd/system/${APP_NAME}.service" << EOF
[Unit]
Description=Calculator Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_DIR
Environment=PATH=$DEPLOY_DIR/venv/bin
ExecStart=$DEPLOY_DIR/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
log "Enabling and starting service..."
systemctl daemon-reload
systemctl enable "${APP_NAME}"
systemctl start "${APP_NAME}"

# Wait for service to start
sleep 5

# Check if service is running
if systemctl is-active --quiet "${APP_NAME}"; then
    log "Application started successfully"
    
    # Test the application
    log "Testing application..."
    if curl -f http://localhost:8081 > /dev/null 2>&1; then
        log "Application is responding correctly"
    else
        warning "Application might not be responding correctly"
    fi
else
    error "Failed to start application"
    systemctl status "${APP_NAME}"
    exit 1
fi

# Clean up old backups (keep only last 5)
log "Cleaning up old backups..."
cd /opt
ls -dt ${APP_NAME}-backup* | tail -n +6 | xargs -r rm -rf

log "Deployment completed successfully!"
log "Application is running on http://localhost:8081"
log "Service status: $(systemctl is-active ${APP_NAME})"

# Optional: Send notification
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"Deployment completed successfully!"}' \
#   https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

exit 0 