#!/bin/bash
###############################################################################
# Configuration Wizard for SCCDMS Deployment
# This script helps you create a configuration file for automated deployment
###############################################################################

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        SCCDMS Deployment Configuration Wizard               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

CONFIG_FILE="deploy_config.sh"

echo "This wizard will help you create a configuration file for automated deployment."
echo "You can press Enter to use default values (shown in brackets)."
echo ""

# Domain name
read -p "Enter your domain name [optional, press Enter to skip]: " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-""}

# Database name
read -p "Enter database name [scc_dms]: " DB_NAME
DB_NAME=${DB_NAME:-"scc_dms"}

# Database user
read -p "Enter database username [sccdms_user]: " DB_USER
DB_USER=${DB_USER:-"sccdms_user"}

# Database password
while [ -z "$DB_PASS" ]; do
    read -sp "Enter database password (required): " DB_PASS
    echo
    if [ -z "$DB_PASS" ]; then
        echo "Password cannot be empty. Please try again."
    fi
done

# Application path
read -p "Enter application path [/var/www/sccdms]: " APP_PATH
APP_PATH=${APP_PATH:-"/var/www/sccdms"}

# Generate configuration file
cat > "$CONFIG_FILE" <<EOF
#!/bin/bash
# SCCDMS Deployment Configuration
# Generated: $(date)

# Domain Configuration
DOMAIN_NAME="${DOMAIN_NAME}"

# Database Configuration
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"

# Application Path
APP_PATH="${APP_PATH}"
EOF

chmod +x "$CONFIG_FILE"

echo ""
echo "✓ Configuration file created: $CONFIG_FILE"
echo ""
echo "You can now use this configuration with the server setup script:"
echo "  sudo bash deploy/server_setup.sh $CONFIG_FILE"
echo ""
echo "⚠️  IMPORTANT: Keep this file secure! It contains passwords."
echo ""

