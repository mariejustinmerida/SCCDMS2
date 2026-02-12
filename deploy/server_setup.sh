#!/bin/bash
###############################################################################
# Automated Server Setup Script for SCCDMS on DigitalOcean
# This script automates the entire server setup process
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables (will be set by config file or prompts)
DB_NAME="scc_dms"
DB_USER="sccdms_user"
DB_PASS=""
DOMAIN_NAME=""
APP_PATH="/var/www/sccdms"
MYSQL_ROOT_PASS=""

###############################################################################
# Helper Functions
###############################################################################

print_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

###############################################################################
# Step 1: System Update
###############################################################################

update_system() {
    print_step "Step 1: Updating System Packages"
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get upgrade -y -qq
    
    print_success "System updated successfully"
}

###############################################################################
# Step 2: Install Required Software
###############################################################################

install_software() {
    print_step "Step 2: Installing Required Software"
    
    print_info "Installing Apache..."
    apt-get install -y apache2 > /dev/null 2>&1
    
    print_info "Installing PHP and extensions..."
    apt-get install -y php php-mysql php-mbstring php-xml php-curl php-zip php-gd php-intl php-cli > /dev/null 2>&1
    
    print_info "Installing MySQL..."
    apt-get install -y mysql-server > /dev/null 2>&1
    
    print_info "Installing additional tools..."
    apt-get install -y curl wget unzip git ufw > /dev/null 2>&1
    
    print_success "All software installed successfully"
}

###############################################################################
# Step 3: Configure MySQL
###############################################################################

configure_mysql() {
    print_step "Step 3: Configuring MySQL Database"
    
    # Generate secure random password if not provided
    if [ -z "$MYSQL_ROOT_PASS" ]; then
        MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        print_info "Generated MySQL root password: $MYSQL_ROOT_PASS"
        print_warning "SAVE THIS PASSWORD! It won't be shown again."
    fi
    
    # Set MySQL root password
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}';" 2>/dev/null || \
    mysql -e "UPDATE mysql.user SET authentication_string=PASSWORD('${MYSQL_ROOT_PASS}') WHERE User='root' AND Host='localhost';" 2>/dev/null || \
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = '${MYSQL_ROOT_PASS}';" 2>/dev/null || true
    
    mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || true
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    # Generate database password if not provided
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    fi
    
    # Create database and user
    print_info "Creating database and user..."
    mysql -u root -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Database configured successfully"
    print_info "Database: $DB_NAME"
    print_info "User: $DB_USER"
    print_info "Password: $DB_PASS"
}

###############################################################################
# Step 4: Install Composer
###############################################################################

install_composer() {
    print_step "Step 4: Installing Composer"
    
    if [ ! -f /usr/local/bin/composer ]; then
        curl -sS https://getcomposer.org/installer | php
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
        print_success "Composer installed successfully"
    else
        print_info "Composer already installed"
    fi
}

###############################################################################
# Step 5: Configure Apache
###############################################################################

configure_apache() {
    print_step "Step 5: Configuring Apache Web Server"
    
    # Enable required modules
    a2enmod rewrite > /dev/null 2>&1
    a2enmod headers > /dev/null 2>&1
    a2enmod ssl > /dev/null 2>&1
    
    # Create Apache virtual host
    cat > /etc/apache2/sites-available/sccdms.conf <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME:-_}
    ServerAlias www.${DOMAIN_NAME:-_}
    DocumentRoot ${APP_PATH}

    <Directory ${APP_PATH}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Security headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    # Logging
    ErrorLog \${APACHE_LOG_DIR}/sccdms_error.log
    CustomLog \${APACHE_LOG_DIR}/sccdms_access.log combined

    # PHP settings
    php_value upload_max_filesize 10M
    php_value post_max_size 12M
    php_value max_execution_time 300
    php_value memory_limit 256M
</VirtualHost>
EOF

    # Disable default site and enable our site
    a2dissite 000-default > /dev/null 2>&1 || true
    a2ensite sccdms.conf > /dev/null 2>&1
    
    # Test Apache configuration
    if apache2ctl configtest > /dev/null 2>&1; then
        systemctl restart apache2
        systemctl enable apache2
        print_success "Apache configured and started successfully"
    else
        print_error "Apache configuration test failed"
        apache2ctl configtest
        exit 1
    fi
}

###############################################################################
# Step 6: Configure PHP
###############################################################################

configure_php() {
    print_step "Step 6: Configuring PHP"
    
    # Update php.ini for production
    PHP_INI="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/apache2/php.ini"
    
    if [ -f "$PHP_INI" ]; then
        sed -i 's/^display_errors = .*/display_errors = Off/' "$PHP_INI"
        sed -i 's/^log_errors = .*/log_errors = On/' "$PHP_INI"
        sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 10M/' "$PHP_INI"
        sed -i 's/^post_max_size = .*/post_max_size = 12M/' "$PHP_INI"
        sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
        sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
        
        systemctl restart apache2
        print_success "PHP configured successfully"
    else
        print_warning "Could not find php.ini, using defaults"
    fi
}

###############################################################################
# Step 7: Configure Firewall
###############################################################################

configure_firewall() {
    print_step "Step 7: Configuring Firewall"
    
    ufw --force enable > /dev/null 2>&1 || true
    ufw allow OpenSSH > /dev/null 2>&1
    ufw allow 'Apache Full' > /dev/null 2>&1
    
    print_success "Firewall configured successfully"
}

###############################################################################
# Step 8: Create Application Directory
###############################################################################

create_app_directory() {
    print_step "Step 8: Creating Application Directory"
    
    mkdir -p "${APP_PATH}"
    chown -R www-data:www-data "${APP_PATH}"
    chmod -R 755 "${APP_PATH}"
    
    print_success "Application directory created: $APP_PATH"
}

###############################################################################
# Step 9: Set Up Automatic Security Updates
###############################################################################

setup_auto_updates() {
    print_step "Step 9: Setting Up Automatic Security Updates"
    
    apt-get install -y unattended-upgrades > /dev/null 2>&1
    
    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    print_success "Automatic security updates configured"
}

###############################################################################
# Step 10: Create Backup Script
###############################################################################

create_backup_script() {
    print_step "Step 10: Creating Backup Script"
    
    cat > /root/backup_sccdms.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Load database credentials from .env if available
if [ -f /var/www/sccdms/.env ]; then
    source <(grep -E '^DB_' /var/www/sccdms/.env | sed 's/^/export /')
fi

# Backup database
if [ ! -z "$DB_NAME" ] && [ ! -z "$DB_USER" ] && [ ! -z "$DB_PASSWORD" ]; then
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/db_$DATE.sql" 2>/dev/null
    gzip "$BACKUP_DIR/db_$DATE.sql"
    echo "Database backup: db_$DATE.sql.gz"
fi

# Backup files
tar -czf "$BACKUP_DIR/files_$DATE.tar.gz" -C /var/www/sccdms . 2>/dev/null
echo "Files backup: files_$DATE.tar.gz"

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
BACKUP_SCRIPT

    chmod +x /root/backup_sccdms.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "backup_sccdms.sh"; echo "0 2 * * * /root/backup_sccdms.sh >> /root/backup.log 2>&1") | crontab -
    
    print_success "Backup script created and scheduled"
}

###############################################################################
# Step 11: Generate Configuration Summary
###############################################################################

generate_summary() {
    print_step "Step 11: Generating Configuration Summary"
    
    SUMMARY_FILE="/root/sccdms_setup_summary.txt"
    
    cat > "$SUMMARY_FILE" <<EOF
================================================================================
SCCDMS Server Setup Summary
Generated: $(date)
================================================================================

SERVER INFORMATION:
-------------------
IP Address: $(curl -s ifconfig.me || echo "Not available")
Domain: ${DOMAIN_NAME:-"Not configured"}
Application Path: ${APP_PATH}

DATABASE INFORMATION:
--------------------
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASS}
MySQL Root Password: ${MYSQL_ROOT_PASS}

NEXT STEPS:
-----------
1. Upload your website files to: ${APP_PATH}
2. Create .env file in ${APP_PATH} with database credentials
3. Import your database SQL file
4. Run: cd ${APP_PATH} && composer install
5. Set proper file permissions: chown -R www-data:www-data ${APP_PATH}
6. Configure SSL certificate (if domain is set up)

IMPORTANT FILES:
----------------
Apache Config: /etc/apache2/sites-available/sccdms.conf
Backup Script: /root/backup_sccdms.sh
This Summary: ${SUMMARY_FILE}

================================================================================
⚠️  IMPORTANT: Save this information securely!
================================================================================
EOF

    cat "$SUMMARY_FILE"
    print_success "Summary saved to: $SUMMARY_FILE"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     SCCDMS Automated Server Setup for DigitalOcean         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    check_root
    
    # Load configuration if provided
    if [ -f "$1" ]; then
        print_info "Loading configuration from: $1"
        source "$1"
    else
        # Interactive prompts if no config file
        if [ -z "$DOMAIN_NAME" ]; then
            read -p "Enter your domain name (or press Enter to skip): " DOMAIN_NAME
        fi
        
        if [ -z "$DB_PASS" ]; then
            read -sp "Enter database password (or press Enter to generate): " DB_PASS
            echo
            if [ -z "$DB_PASS" ]; then
                print_info "Will generate secure password automatically"
            fi
        fi
    fi
    
    # Execute all setup steps
    update_system
    install_software
    configure_mysql
    install_composer
    configure_apache
    configure_php
    configure_firewall
    create_app_directory
    setup_auto_updates
    create_backup_script
    generate_summary
    
    print_step "Setup Complete!"
    print_success "Server is ready for your application files"
    print_info "Next: Upload your files and configure .env file"
    print_warning "Don't forget to save the passwords shown above!"
}

# Run main function
main "$@"

