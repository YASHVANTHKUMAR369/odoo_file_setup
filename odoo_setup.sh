#!/bin/bash

# Color codes
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # No Color

# Prompting for user input
read -p "Enter the file name without extension: " FILE_NAME
read -p "Enter the database name: " DB_NAME
read -p "Enter the admin password: " ADMIN_PASS
read -p "Enter the Odoo user (e.g., odoo): " ODOO_USER
read -p "Enter the XML-RPC port (default: 8069): " PORT
read -p "Enter the addons path (e.g., /opt/odoo/custom_addons): " ADDONS_PATH

# Set default values if input is empty
PORT=${PORT:-8069}  # If no input, set default port to 8069

# Navigate to /etc directory
cd /etc || { echo "Failed to change directory to /etc"; exit 1; }

# Create the file in /etc
CONFIG_PATH="/etc/$FILE_NAME.conf"

# Use sudo to write to /etc
echo ""
echo -e "${GREEN}Creating a Config file at $CONFIG_PATH.${NC}"
echo ""
sudo bash -c "cat <<EOF > $CONFIG_PATH
[options]
; This is the password that allows database operations:
db_host = False
db_port = False
db_user = False
db_password = False
db_name = $DB_NAME

; Admin password for database manager
admin_passwd = $ADMIN_PASS

; File system paths
addons_path = $ADDONS_PATH

; Server settings
xmlrpc_port = $PORT

; Other settings
limit_memory_soft = 640000000
limit_memory_hard = 760000000
limit_time_cpu = 60
limit_time_real = 120
EOF"

# Notify the user
echo ""
echo -e "${GREEN}Config File created successfully at $CONFIG_PATH.${NC}"
echo ""


SERVICE_PATH="/etc/systemd/system/$FILE_NAME.service"
echo ""
echo -e "${GREEN}Creating a service file at $FILE_NAME.service.${NC}"
echo ""

IFS=',' read -ra ADDONS_ARRAY <<< "$ADDONS_PATH"

ODOO_BIN=$(echo "${ADDONS_ARRAY[0]}" | sed 's|addons|odoo-bin|')

read -p "Enter the description name: " DESCRIPTION
sudo bash -c "cat <<EOF > $SERVICE_PATH
[Unit]
Description=$DESCRIPTION
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=$FILE_NAME
PermissionsStartOnly=true
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_BIN -c /etc/$FILE_NAME.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF"

# Notify the user
echo ""
echo -e "${GREEN}Service file created successfully at $FILE_NAME.service.${NC}"
echo ""

sudo systemctl daemon-reload
sudo systemctl enable --now $FILE_NAME
sudo systemctl status $FILE_NAME
