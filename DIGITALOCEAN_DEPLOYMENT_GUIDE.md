# 🚀 Easy Guide: Deploy Your Website to DigitalOcean

This guide will walk you through hosting your SCCDMS website on DigitalOcean step by step.

---

## 📋 **What You'll Need Before Starting**

- A DigitalOcean account (sign up at [digitalocean.com](https://www.digitalocean.com))
- Your website files (the SCCDMS2 folder you have)
- A domain name (optional, but recommended - you can use the IP address too)
- About 30-60 minutes of time

---

## **STEP 1: Create Your DigitalOcean Droplet** 🖥️

### 1.1 Sign Up / Log In
- Go to [digitalocean.com](https://www.digitalocean.com) and create an account (or log in)
- You'll need a credit card, but they have a $200 free credit for new users

### 1.2 Create a Droplet
1. Click the **"Create"** button (top right) → **"Droplets"**
2. **Choose an Image**: Select **Ubuntu 22.04 LTS** (most stable and beginner-friendly)
3. **Choose a Plan**: 
   - For small to medium websites: **Basic Plan** → **Regular** → **$6/month** (1GB RAM, 1 vCPU)
   - For larger sites: **$12/month** (2GB RAM, 1 vCPU) or higher
4. **Choose a Datacenter**: Pick the region closest to your users (e.g., Singapore if in Philippines)
5. **Authentication**: 
   - Choose **"SSH keys"** (more secure)
   - If you don't have one, click "New SSH Key" and follow instructions
   - OR choose "Password" for now (less secure but easier)
6. **Finalize**:
   - Give it a hostname like `sccdms-server`
   - Click **"Create Droplet"**
   - Wait 1-2 minutes for it to be ready

### 1.3 Get Your Server IP Address
- After creation, you'll see an **IP address** (like `123.456.789.012`)
- **Write this down!** You'll need it to connect to your server

---

## **STEP 2: Connect to Your Server** 🔌

### 2.1 On Windows (Using PowerShell or Command Prompt)

**Option A: Using Password (Easier)**
```bash
ssh root@YOUR_IP_ADDRESS
```
- Replace `YOUR_IP_ADDRESS` with your actual IP
- Type "yes" when asked
- Enter your password when prompted

**Option B: Using SSH Key (More Secure)**
- If you set up SSH keys, use the same command above

### 2.2 You're Now Connected!
- You should see a prompt like: `root@sccdms-server:~#`
- This means you're inside your server!

---

## **STEP 3: Install Required Software** 📦

Run these commands one by one (copy and paste each, press Enter):

### 3.1 Update Your Server
```bash
apt update && apt upgrade -y
```

### 3.2 Install Apache Web Server
```bash
apt install apache2 -y
```

### 3.3 Install PHP and Extensions
```bash
apt install php php-mysql php-mbstring php-xml php-curl php-zip php-gd php-intl -y
```

### 3.4 Install MySQL Database
```bash
apt install mysql-server -y
```

### 3.5 Secure MySQL (Important!)
```bash
mysql_secure_installation
```
- Press Enter for current password (there isn't one yet)
- Type `Y` and set a **strong password** (write it down!)
- Answer `Y` to all other questions

### 3.6 Install Composer (for PHP dependencies)
```bash
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
```

### 3.7 Start Services
```bash
systemctl start apache2
systemctl start mysql
systemctl enable apache2
systemctl enable mysql
```

---

## **STEP 4: Set Up Your Database** 🗄️

### 4.1 Log Into MySQL
```bash
mysql -u root -p
```
- Enter the password you set in step 3.5

### 4.2 Create Database and User
Run these commands inside MySQL (copy all at once):

```sql
CREATE DATABASE scc_dms CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'sccdms_user'@'localhost' IDENTIFIED BY 'YourSecurePassword123!';
GRANT ALL PRIVILEGES ON scc_dms.* TO 'sccdms_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Important**: Replace `YourSecurePassword123!` with a strong password of your choice!

---

## **STEP 5: Upload Your Website Files** 📤

### 5.1 Create Website Directory
```bash
mkdir -p /var/www/sccdms
chown -R www-data:www-data /var/www/sccdms
```

### 5.2 Upload Files from Your Computer

**On Windows, you have several options:**

**Option A: Using WinSCP (Easiest - Recommended)**
1. Download WinSCP from [winscp.net](https://winscp.net)
2. Install and open it
3. Create new connection:
   - Host: Your server IP address
   - Username: `root`
   - Password: Your server password
   - Click "Login"
4. Navigate to `/var/www/sccdms` on the right (server side)
5. Navigate to your `SCCDMS2` folder on the left (your computer)
6. Select all files and folders, drag them to the server
7. Wait for upload to complete

**Option B: Using FileZilla**
1. Download FileZilla from [filezilla-project.org](https://filezilla-project.org)
2. Use SFTP connection with same credentials
3. Upload files same way

**Option C: Using Command Line (Advanced)**
```bash
# On your Windows computer, in PowerShell:
scp -r C:\xampp\htdocs\SCCDMS2\* root@YOUR_IP_ADDRESS:/var/www/sccdms/
```

### 5.3 Set Correct Permissions
```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
find /var/www/sccdms -type f -exec chmod 644 {} \;
```

---

## **STEP 6: Configure Apache** ⚙️

### 6.1 Create Apache Configuration
```bash
nano /etc/apache2/sites-available/sccdms.conf
```

### 6.2 Paste This Configuration
Copy and paste this entire block:

```apache
<VirtualHost *:80>
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    DocumentRoot /var/www/sccdms

    <Directory /var/www/sccdms>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/sccdms_error.log
    CustomLog ${APACHE_LOG_DIR}/sccdms_access.log combined
</VirtualHost>
```

**Note**: Replace `yourdomain.com` with your actual domain, or use your IP address for now.

### 6.3 Save and Exit
- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter` to save

### 6.4 Enable the Site
```bash
a2ensite sccdms.conf
a2enmod rewrite
systemctl restart apache2
```

---

## **STEP 7: Configure Your Application** 🔧

### 7.1 Set Up Environment Variables
```bash
cd /var/www/sccdms
nano .env
```

### 7.2 Add Your Database Configuration
Paste this (update with your actual database password):

```
DB_HOST=localhost
DB_USERNAME=sccdms_user
DB_PASSWORD=YourSecurePassword123!
DB_NAME=scc_dms
APP_TIMEZONE=Asia/Manila
```

**Important**: Replace `YourSecurePassword123!` with the password you set in Step 4.2!

### 7.3 Save and Exit
- `Ctrl + X`, then `Y`, then `Enter`

### 7.4 Import Your Database
```bash
# First, upload your SQL file using WinSCP/FileZilla to /var/www/sccdms/
# Then run:
mysql -u sccdms_user -p scc_dms < /var/www/sccdms/database/scc_dms.sql
```
- Enter your database password when prompted

### 7.5 Install PHP Dependencies
```bash
cd /var/www/sccdms
composer install --no-dev --optimize-autoloader
```

---

## **STEP 8: Set Up SSL (HTTPS) - Free!** 🔒

### 8.1 Install Certbot
```bash
apt install certbot python3-certbot-apache -y
```

### 8.2 Get SSL Certificate
```bash
certbot --apache -d yourdomain.com -d www.yourdomain.com
```

**If you don't have a domain yet**, skip this step and use HTTP for now. You can add SSL later.

### 8.3 Test Auto-Renewal
```bash
certbot renew --dry-run
```

---

## **STEP 9: Configure Firewall** 🛡️

### 9.1 Set Up UFW Firewall
```bash
ufw allow OpenSSH
ufw allow 'Apache Full'
ufw enable
```

### 9.2 Verify Firewall Status
```bash
ufw status
```

---

## **STEP 10: Test Your Website** ✅

### 10.1 Open in Browser
- Go to `http://YOUR_IP_ADDRESS` or `https://yourdomain.com`
- You should see your website!

### 10.2 Common Issues & Fixes

**Issue: "404 Not Found"**
```bash
# Check if files are in the right place
ls -la /var/www/sccdms
# Make sure index.php exists
```

**Issue: "Database Connection Error"**
```bash
# Check database credentials in .env file
cat /var/www/sccdms/.env
# Test database connection
mysql -u sccdms_user -p scc_dms
```

**Issue: "Permission Denied"**
```bash
# Fix permissions
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
```

**Issue: "500 Internal Server Error"**
```bash
# Check Apache error logs
tail -f /var/log/apache2/error.log
# Check PHP errors
tail -f /var/log/apache2/sccdms_error.log
```

---

## **STEP 11: Set Up Domain (Optional but Recommended)** 🌐

### 11.1 Point Your Domain to Your Server
1. Go to your domain registrar (where you bought the domain)
2. Find DNS settings
3. Add an **A Record**:
   - Name: `@` (or leave blank)
   - Value: Your server IP address
   - TTL: 3600
4. Add a **CNAME Record** for www:
   - Name: `www`
   - Value: `yourdomain.com`
   - TTL: 3600

### 11.2 Wait for DNS Propagation
- Can take 5 minutes to 48 hours
- Check with: [whatsmydns.net](https://www.whatsmydns.net)

### 11.3 Update Apache Configuration
```bash
nano /etc/apache2/sites-available/sccdms.conf
```
- Update `ServerName` and `ServerAlias` with your actual domain
- Restart Apache: `systemctl restart apache2`

---

## **STEP 12: Set Up Automatic Backups** 💾

### 12.1 Create Backup Script
```bash
nano /root/backup_sccdms.sh
```

### 12.2 Paste This Script
```bash
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u sccdms_user -pYourSecurePassword123! scc_dms > $BACKUP_DIR/db_$DATE.sql

# Backup files
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/www/sccdms

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

**Important**: Replace `YourSecurePassword123!` with your actual database password!

### 12.3 Make Script Executable
```bash
chmod +x /root/backup_sccdms.sh
```

### 12.4 Set Up Daily Backups (Cron)
```bash
crontab -e
```
- Add this line at the end:
```
0 2 * * * /root/backup_sccdms.sh >> /root/backup.log 2>&1
```
- This runs backup every day at 2 AM

---

## **🎉 Congratulations! Your Website is Live!**

### **Quick Reference Commands**

**Restart Apache:**
```bash
systemctl restart apache2
```

**Check Apache Status:**
```bash
systemctl status apache2
```

**View Error Logs:**
```bash
tail -f /var/log/apache2/error.log
```

**Update Your Website:**
- Just upload new files via WinSCP/FileZilla
- Make sure to set permissions: `chown -R www-data:www-data /var/www/sccdms`

---

## **⚠️ Security Checklist**

- [ ] Changed default MySQL root password
- [ ] Created separate database user (not using root)
- [ ] Set up firewall (UFW)
- [ ] Installed SSL certificate (HTTPS)
- [ ] Set proper file permissions
- [ ] Enabled automatic security updates
- [ ] Set up regular backups

### Enable Automatic Security Updates
```bash
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades
```

---

## **📞 Need Help?**

### Common Commands Cheat Sheet

```bash
# Restart services
systemctl restart apache2
systemctl restart mysql

# Check service status
systemctl status apache2
systemctl status mysql

# View logs
tail -f /var/log/apache2/error.log
tail -f /var/log/apache2/sccdms_error.log

# Check disk space
df -h

# Check memory usage
free -h

# Update system
apt update && apt upgrade -y
```

---

## **🔄 Updating Your Website**

1. Make changes on your local computer
2. Upload changed files via WinSCP/FileZilla
3. Set permissions: `chown -R www-data:www-data /var/www/sccdms`
4. Clear browser cache and test

---

**That's it! Your website should now be live on DigitalOcean! 🚀**

If you run into any issues, check the error logs first, and make sure all passwords and paths are correct.

