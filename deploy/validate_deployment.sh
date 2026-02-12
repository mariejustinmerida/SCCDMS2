#!/bin/bash
###############################################################################
# Deployment Validation Script
# Run this after uploading files to verify everything is set up correctly
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_PATH="${1:-/var/www/sccdms}"
ERRORS=0
WARNINGS=0

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

clear
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SCCDMS Deployment Validation                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

print_header "1. Checking Application Directory"

if [ -d "$APP_PATH" ]; then
    print_success "Application directory exists: $APP_PATH"
else
    print_error "Application directory not found: $APP_PATH"
    exit 1
fi

print_header "2. Checking Critical Files"

CRITICAL_FILES=(
    "index.php"
    "composer.json"
    "includes/config.php"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$APP_PATH/$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
    fi
done

print_header "3. Checking File Permissions"

OWNER=$(stat -c '%U:%G' "$APP_PATH" 2>/dev/null || stat -f '%Su:%Sg' "$APP_PATH" 2>/dev/null)
if [ "$OWNER" = "www-data:www-data" ] || [ "$OWNER" = "_www:_www" ]; then
    print_success "Correct ownership: $OWNER"
else
    print_warning "Incorrect ownership: $OWNER (should be www-data:www-data)"
    print_info "Fix with: chown -R www-data:www-data $APP_PATH"
fi

print_header "4. Checking .env File"

if [ -f "$APP_PATH/.env" ]; then
    print_success ".env file exists"
    
    # Check if .env has required variables
    if grep -q "DB_HOST" "$APP_PATH/.env" && grep -q "DB_USERNAME" "$APP_PATH/.env" && grep -q "DB_PASSWORD" "$APP_PATH/.env"; then
        print_success ".env contains database configuration"
    else
        print_warning ".env file exists but may be missing required variables"
    fi
    
    # Check if password is still default
    if grep -q "CHANGE_THIS_PASSWORD" "$APP_PATH/.env"; then
        print_error ".env file still contains default password!"
    fi
else
    print_error ".env file not found!"
    print_info "Create it from .env.example and update with your credentials"
fi

print_header "5. Checking Database Connection"

if [ -f "$APP_PATH/.env" ]; then
    source <(grep -E '^DB_' "$APP_PATH/.env" | sed 's/^/export /')
    
    if [ ! -z "$DB_NAME" ] && [ ! -z "$DB_USERNAME" ] && [ ! -z "$DB_PASSWORD" ]; then
        if mysql -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1" > /dev/null 2>&1; then
            print_success "Database connection successful"
            
            # Check if database has tables
            TABLE_COUNT=$(mysql -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES" 2>/dev/null | wc -l)
            if [ "$TABLE_COUNT" -gt 1 ]; then
                print_success "Database contains $((TABLE_COUNT-1)) tables"
            else
                print_warning "Database appears to be empty - you may need to import your SQL file"
            fi
        else
            print_error "Cannot connect to database - check credentials in .env"
        fi
    else
        print_warning "Database credentials not found in .env"
    fi
else
    print_warning "Cannot check database - .env file missing"
fi

print_header "6. Checking Composer Dependencies"

if [ -f "$APP_PATH/vendor/autoload.php" ]; then
    print_success "Composer dependencies installed"
else
    print_warning "Composer dependencies not installed"
    print_info "Run: cd $APP_PATH && composer install --no-dev --optimize-autoloader"
fi

print_header "7. Checking Apache Configuration"

if systemctl is-active --quiet apache2; then
    print_success "Apache is running"
else
    print_error "Apache is not running"
    print_info "Start with: systemctl start apache2"
fi

if apache2ctl configtest > /dev/null 2>&1; then
    print_success "Apache configuration is valid"
else
    print_error "Apache configuration has errors"
    print_info "Check with: apache2ctl configtest"
fi

# Check if site is enabled
if [ -L "/etc/apache2/sites-enabled/sccdms.conf" ]; then
    print_success "Apache site is enabled"
else
    print_warning "Apache site may not be enabled"
    print_info "Enable with: a2ensite sccdms.conf && systemctl reload apache2"
fi

print_header "8. Checking PHP Configuration"

PHP_VERSION=$(php -r 'echo PHP_VERSION;')
print_info "PHP Version: $PHP_VERSION"

REQUIRED_EXTENSIONS=("mysqli" "mbstring" "xml" "curl" "zip" "gd")
for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if php -m | grep -q "^$ext$"; then
        print_success "PHP extension installed: $ext"
    else
        print_error "PHP extension missing: $ext"
    fi
done

print_header "9. Checking Storage Directories"

STORAGE_DIRS=("storage" "uploads" "temp" "logs")
for dir in "${STORAGE_DIRS[@]}"; do
    if [ -d "$APP_PATH/$dir" ]; then
        print_success "Directory exists: $dir"
        
        # Check if writable
        if [ -w "$APP_PATH/$dir" ]; then
            print_success "Directory is writable: $dir"
        else
            print_warning "Directory may not be writable: $dir"
            print_info "Fix with: chmod -R 755 $APP_PATH/$dir"
        fi
    else
        print_warning "Directory missing: $dir"
        print_info "Create with: mkdir -p $APP_PATH/$dir && chmod 755 $APP_PATH/$dir"
    fi
done

print_header "10. Checking Firewall"

if command -v ufw > /dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        print_success "Firewall is active"
        
        if ufw status | grep -q "Apache Full"; then
            print_success "Apache ports are open"
        else
            print_warning "Apache ports may not be open"
        fi
    else
        print_warning "Firewall is not active"
    fi
else
    print_warning "UFW firewall not installed"
fi

print_header "11. Testing Web Server Response"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
    print_success "Web server is responding (HTTP $HTTP_CODE)"
else
    print_error "Web server returned HTTP $HTTP_CODE"
    print_info "Check Apache error logs: tail -f /var/log/apache2/error.log"
fi

# Final Summary
print_header "Validation Summary"

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "All checks passed! Your deployment looks good."
elif [ $ERRORS -eq 0 ]; then
    print_warning "$WARNINGS warning(s) found - review above"
    print_success "No critical errors found"
else
    print_error "$ERRORS error(s) and $WARNINGS warning(s) found"
    print_info "Please fix the errors above before going live"
fi

echo ""
print_info "For detailed logs, check:"
print_info "  - Apache errors: tail -f /var/log/apache2/error.log"
print_info "  - Application errors: tail -f $APP_PATH/logs/*.log"
echo ""

exit $ERRORS

