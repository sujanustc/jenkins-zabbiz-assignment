#!/bin/bash
# ==============================================================================
# Script Name: install-zabbix.sh
# Description: Installs Zabbix Server, MySQL, Apache, Frontend, and Agent on Ubuntu.
# Supports: Ubuntu 20.04, 22.04, and 24.04 LTS.
# Usage: chmod +x install-zabbix.sh && ./install-zabbix.sh
# ==============================================================================

set -e

# Detect Ubuntu version
CODENAME=$(lsb_release -cs)
RELEASE=$(lsb_release -rs)

echo "=== [1/6] Detecting OS version ==="
echo "Detected Ubuntu version: $RELEASE ($CODENAME)"

# Select Zabbix version (Zabbix 7.0 LTS is recommended, fallback to 6.0 for older OS if needed)
if [ "$RELEASE" == "24.04" ]; then
    DEB_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb"
    DEB_FILE="zabbix-release_latest+ubuntu24.04_all.deb"
elif [ "$RELEASE" == "22.04" ]; then
    DEB_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb"
    DEB_FILE="zabbix-release_latest+ubuntu22.04_all.deb"
else
    # Fallback to Zabbix 6.0 LTS for 20.04 or others
    DEB_URL="https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb"
    DEB_FILE="zabbix-release_6.0-4+ubuntu20.04_all.deb"
fi

echo "=== [2/6] Installing Zabbix Repository ==="
wget -q "$DEB_URL"
sudo dpkg -i "$DEB_FILE"
rm "$DEB_FILE"
sudo apt-get update -y

echo "=== [3/6] Installing MySQL Server ==="
sudo apt-get install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

echo "=== [4/6] Setting up Zabbix Database ==="
DB_PASS="zabbix_password"

# Create database and user
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER zabbix@localhost IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;"
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"

echo "=== [5/6] Installing Zabbix Server, Frontend, and Agent ==="
sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent php-mysql

echo "Importing database schema (this may take a minute)..."
# Locate the schema file (could be in /usr/share/zabbix-sql-scripts or /usr/share/doc)
SCHEMA_PATH=""
if [ -f "/usr/share/zabbix-sql-scripts/mysql/server.sql.gz" ]; then
    SCHEMA_PATH="/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"
elif [ -f "/usr/share/zabbix-sql-scripts/mysql/schema.sql.gz" ]; then
    SCHEMA_PATH="/usr/share/zabbix-sql-scripts/mysql/schema.sql.gz"
elif [ -f "/usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz" ]; then
    SCHEMA_PATH="/usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz"
fi

if [ -n "$SCHEMA_PATH" ]; then
    zcat "$SCHEMA_PATH" | mysql -uzabbix -p"$DB_PASS" zabbix
else
    echo "ERROR: Zabbix SQL schema file not found!"
    exit 1
fi

# Reset log_bin_trust_function_creators
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"

echo "=== [6/6] Configuring Zabbix Server ==="
# Set DBPassword in zabbix_server.conf
sudo sed -i "s/# DBPassword=/DBPassword=$DB_PASS/g" /etc/zabbix/zabbix_server.conf

# Restart and enable services
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "=== Zabbix Server Installation Completed Successfully! ==="
echo "Zabbix Web UI is available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/zabbix"
echo "Database configuration detail: User = zabbix, DB = zabbix, Password = $DB_PASS"
echo "========================================================="
