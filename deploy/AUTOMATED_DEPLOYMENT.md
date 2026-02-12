# 🤖 Automated Deployment Guide for DigitalOcean

This guide uses automated scripts to deploy your SCCDMS website with minimal manual steps and fewer errors.

---

## 📋 **Prerequisites**

- DigitalOcean account
- A droplet created (Ubuntu 22.04 LTS recommended)
- Your server IP address
- WinSCP or FileZilla installed (for file upload)
- SSH access to your server

---

## 🚀 **Quick Start (3 Steps)**

### **Step 1: Prepare Files Locally**

On your Windows computer, open PowerShell in the SCCDMS2 folder and run:

```powershell
.\deploy\prepare_local.ps1
```

This will:
- ✅ Clean and prepare all files for deployment
- ✅ Remove development/test files
- ✅ Create .env template
- ✅ Verify critical files

**Output:** Files ready in `deploy\files_to_upload\`

---

### **Step 2: Run Automated Server Setup**

Connect to your DigitalOcean server via SSH, then run:

```bash
# Download and run the setup script
curl -o server_setup.sh https://raw.githubusercontent.com/your-repo/deploy/server_setup.sh
# OR copy the script from your local computer

# Make it executable and run
chmod +x server_setup.sh
sudo bash server_setup.sh
```

**OR** if you want to use a configuration file:

```bash
# First, create config (optional - script will prompt if not provided)
sudo bash deploy/config_wizard.sh

# Then run setup with config
sudo bash deploy/server_setup.sh deploy_config.sh
```

**What it does automatically:**
- ✅ Updates system packages
- ✅ Installs Apache, PHP, MySQL, Composer
- ✅ Configures MySQL with secure passwords
- ✅ Sets up Apache virtual host
- ✅ Configures PHP settings
- ✅ Sets up firewall
- ✅ Creates backup scripts
- ✅ Enables automatic security updates

**Time:** ~5-10 minutes

---

### **Step 3: Upload Files and Configure**

#### 3.1 Upload Files

Using WinSCP or FileZilla:
1. Connect to your server (IP address, user: `root`)
2. Navigate to `/var/www/sccdms` on server
3. Upload ALL files from `deploy\files_to_upload\` folder

#### 3.2 Create .env File

On the server, run:

```bash
cd /var/www/sccdms
cp .env.example .env
nano .env
```

Update these values (from the setup summary):
```
DB_HOST=localhost
DB_USERNAME=sccdms_user
DB_PASSWORD=<password from setup summary>
DB_NAME=scc_dms
APP_TIMEZONE=Asia/Manila
```

Save: `Ctrl+X`, then `Y`, then `Enter`

#### 3.3 Import Database

```bash
mysql -u sccdms_user -p scc_dms < database/scc_dms.sql
```
(Enter the database password when prompted)

#### 3.4 Install Dependencies

```bash
cd /var/www/sccdms
composer install --no-dev --optimize-autoloader
```

#### 3.5 Set Permissions

```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
find /var/www/sccdms -type f -exec chmod 644 {} \;
```

#### 3.6 Validate Deployment

```bash
sudo bash deploy/validate_deployment.sh
```

This will check:
- ✅ All files are in place
- ✅ Database connection works
- ✅ Apache is configured correctly
- ✅ Permissions are correct
- ✅ Everything is working

---

## 📝 **Detailed Step-by-Step**

### **Option A: Fully Automated (Recommended)**

1. **Prepare files locally:**
   ```powershell
   cd C:\xampp\htdocs\SCCDMS2
   .\deploy\prepare_local.ps1
   ```

2. **Create configuration (optional but recommended):**
   ```bash
   # On server
   sudo bash deploy/config_wizard.sh
   ```

3. **Run automated setup:**
   ```bash
   # On server
   sudo bash deploy/server_setup.sh deploy_config.sh
   ```
   
   **Save the output!** It contains important passwords.

4. **Upload files via WinSCP/FileZilla:**
   - Source: `deploy\files_to_upload\` (on your computer)
   - Destination: `/var/www/sccdms` (on server)

5. **Configure application:**
   ```bash
   cd /var/www/sccdms
   cp .env.example .env
   nano .env  # Update with passwords from setup summary
   ```

6. **Import database:**
   ```bash
   mysql -u sccdms_user -p scc_dms < database/scc_dms.sql
   ```

7. **Install dependencies:**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

8. **Set permissions:**
   ```bash
   chown -R www-data:www-data /var/www/sccdms
   chmod -R 755 /var/www/sccdms
   ```

9. **Validate:**
   ```bash
   sudo bash deploy/validate_deployment.sh
   ```

10. **Test in browser:**
    - Visit: `http://YOUR_IP_ADDRESS` or `https://yourdomain.com`

---

### **Option B: Semi-Automated (Interactive Prompts)**

If you don't create a config file, the setup script will prompt you for:
- Domain name (optional)
- Database password (or auto-generate)

Just run:
```bash
sudo bash deploy/server_setup.sh
```

And answer the prompts.

---

## 🔧 **Troubleshooting**

### **Script won't run:**
```bash
chmod +x deploy/server_setup.sh
sudo bash deploy/server_setup.sh
```

### **Permission errors:**
```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
```

### **Database connection fails:**
1. Check `.env` file has correct credentials
2. Verify database exists: `mysql -u sccdms_user -p scc_dms -e "SHOW TABLES;"`
3. Check MySQL is running: `systemctl status mysql`

### **Website shows 500 error:**
```bash
# Check Apache error log
tail -f /var/log/apache2/error.log

# Check PHP errors
tail -f /var/log/apache2/sccdms_error.log
```

### **Files not uploading:**
- Make sure you're uploading to `/var/www/sccdms`
- Check you have write permissions
- Verify WinSCP/FileZilla connection is working

---

## 📊 **What Gets Automated**

✅ **Server Setup:**
- System updates
- Software installation (Apache, PHP, MySQL, Composer)
- MySQL secure configuration
- Apache virtual host setup
- PHP optimization
- Firewall configuration
- Automatic security updates
- Backup script creation

✅ **File Preparation:**
- Removes development files
- Creates deployment package
- Validates critical files
- Creates .env template

✅ **Validation:**
- Checks all files exist
- Verifies database connection
- Tests Apache configuration
- Validates permissions
- Checks PHP extensions

---

## 🔐 **Security Features**

The automated setup includes:
- ✅ Secure MySQL configuration
- Secure random password generation
- Firewall setup (UFW)
- Automatic security updates
- Proper file permissions
- SSL-ready configuration

---

## 📦 **Files Created**

After running the scripts, you'll have:

**On Server:**
- `/var/www/sccdms` - Your application
- `/etc/apache2/sites-available/sccdms.conf` - Apache config
- `/root/backup_sccdms.sh` - Backup script
- `/root/sccdms_setup_summary.txt` - Setup summary (SAVE THIS!)

**On Local:**
- `deploy/files_to_upload/` - Files ready for upload
- `deploy_config.sh` - Your configuration (if created)

---

## 🎯 **Next Steps After Deployment**

1. **Set up SSL (HTTPS):**
   ```bash
   sudo apt install certbot python3-certbot-apache
   sudo certbot --apache -d yourdomain.com
   ```

2. **Configure domain DNS:**
   - Add A record pointing to your server IP
   - Wait for DNS propagation

3. **Test all features:**
   - Login
   - Upload documents
   - Create workflows
   - Test AI features

4. **Monitor logs:**
   ```bash
   tail -f /var/log/apache2/error.log
   tail -f /var/www/sccdms/logs/*.log
   ```

---

## 💡 **Tips**

- **Save passwords:** The setup script shows passwords - save them securely!
- **Test locally first:** Make sure your site works on XAMPP before deploying
- **Backup regularly:** The backup script runs daily at 2 AM
- **Monitor resources:** Check server resources with `htop` or `df -h`
- **Keep updated:** Run `sudo apt update && sudo apt upgrade` regularly

---

## 🆘 **Need Help?**

1. **Check validation script output:**
   ```bash
   sudo bash deploy/validate_deployment.sh
   ```

2. **View setup summary:**
   ```bash
   cat /root/sccdms_setup_summary.txt
   ```

3. **Check logs:**
   ```bash
   tail -f /var/log/apache2/error.log
   ```

---

**That's it! The automated scripts handle most of the work for you! 🚀**

