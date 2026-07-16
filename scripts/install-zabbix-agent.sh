#!/bin/bash
# ==============================================================================
# Script Name: install-zabbix-agent.sh
# Description: Installs and configures Zabbix Agent on a target host.
# Usage: chmod +x install-zabbix-agent.sh && ./install-zabbix-agent.sh [SERVER_IP] [HOSTNAME]
#        If SERVER_IP is omitted, it defaults to 127.0.0.1 (local monitor).
# ==============================================================================

set -e

# Configuration variables
SERVER_IP=${1:-"127.0.0.1"}
AGENT_HOSTNAME=${2:-"jenkins-ec2-node"}

echo "=== [1/3] Adding Zabbix Repository & Installing Zabbix Agent ==="
CODENAME=$(lsb_release -cs)
RELEASE=$(lsb_release -rs)

if [ "$RELEASE" == "24.04" ]; then
    DEB_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb"
    DEB_FILE="zabbix-release_latest+ubuntu24.04_all.deb"
elif [ "$RELEASE" == "22.04" ]; then
    DEB_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb"
    DEB_FILE="zabbix-release_latest+ubuntu22.04_all.deb"
else
    DEB_URL="https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb"
    DEB_FILE="zabbix-release_6.0-4+ubuntu20.04_all.deb"
fi

wget -q "$DEB_URL"
sudo dpkg -i "$DEB_FILE"
rm "$DEB_FILE"
sudo apt-get update -y
sudo apt-get install -y zabbix-agent

echo "=== [2/3] Configuring Zabbix Agent ==="
# Update configuration file /etc/zabbix/zabbix_agentd.conf
# Replace Server, ServerActive, and Hostname
sudo sed -i "s/^Server=127.0.0.1/Server=$SERVER_IP/g" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^ServerActive=127.0.0.1/ServerActive=$SERVER_IP/g" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^Hostname=Zabbix server/Hostname=$AGENT_HOSTNAME/g" /etc/zabbix/zabbix_agentd.conf

echo "=== [3/3] Starting & Enabling Zabbix Agent ==="
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

echo "=== Zabbix Agent Setup Completed ==="
echo "Configured Server IP: $SERVER_IP"
echo "Configured Agent Hostname: $AGENT_HOSTNAME"
echo "Agent status is active and running."
echo "====================================="
