#!/bin/bash
# ==============================================================================
# Script Name: install-jenkins.sh
# Description: Installs Java 17, Jenkins, Docker, and Node.js 18 on Ubuntu 22.04/24.04.
# Usage: chmod +x install-jenkins.sh && ./install-jenkins.sh
# ==============================================================================

set -e

# Clean up any potential failed key files and old configs *before* updating packages
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc /usr/share/keyrings/jenkins-keyring.gpg /etc/apt/sources.list.d/jenkins.list

echo "=== [1/5] Updating System Packages ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== [2/5] Installing Java 17 (Required by Jenkins) ==="
sudo apt-get install -y openjdk-17-jdk gnupg curl wget ca-certificates apt-transport-https

echo "=== [3/5] Installing Jenkins ==="

# Download key, de-armor it to binary format, and register repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
echo "Jenkins installed and running on port 8080."

echo "=== [4/5] Installing Docker ==="
# Add Docker GPG key and repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu and jenkins users to docker group so they can run docker command without sudo
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# Restart Jenkins to apply the group permission changes
sudo systemctl restart jenkins
echo "Docker installed. Jenkins user added to docker group."

echo "=== [5/5] Installing Node.js 18 & npm ==="
# Install Node.js 18 from NodeSource
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=18
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update -y
sudo apt-get install nodejs -y

echo "=== Installation Completed Successfully! ==="
echo "Jenkins is available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "=========================================="
