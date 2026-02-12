# 🚀 Automated Deployment Scripts

This folder contains automated scripts to deploy your SCCDMS website to DigitalOcean with minimal errors.

## 📁 Files Overview

### **For Local Computer (Windows):**
- `prepare_local.ps1` - Prepares files for deployment (removes dev files, creates package)

### **For Server (Linux):**
- `server_setup.sh` - **MAIN SCRIPT** - Automates entire server setup
- `config_wizard.sh` - Interactive wizard to create configuration file
- `validate_deployment.sh` - Validates deployment after files are uploaded

### **Documentation:**
- `AUTOMATED_DEPLOYMENT.md` - Complete automated deployment guide
- `README.md` - This file

---

## 🎯 Quick Start

### **1. Prepare Files (On Your Computer)**
```powershell
.\deploy\prepare_local.ps1
```

### **2. Setup Server (On DigitalOcean Server)**
```bash
# Upload server_setup.sh to server, then:
sudo bash server_setup.sh
```

### **3. Upload Files & Configure**
- Upload files from `deploy\files_to_upload\` to `/var/www/sccdms`
- Create `.env` file with database credentials
- Import database
- Run validation script

See `AUTOMATED_DEPLOYMENT.md` for detailed instructions.

---

## 📋 What Each Script Does

### `prepare_local.ps1`
- ✅ Copies all necessary files
- ✅ Removes development/test files
- ✅ Creates .env template
- ✅ Validates critical files exist
- ✅ Creates deployment package

### `server_setup.sh`
- ✅ Updates system
- ✅ Installs Apache, PHP, MySQL, Composer
- ✅ Configures MySQL securely
- ✅ Sets up Apache virtual host
- ✅ Configures PHP
- ✅ Sets up firewall
- ✅ Creates backup scripts
- ✅ Enables auto-updates

### `config_wizard.sh`
- ✅ Interactive prompts
- ✅ Creates configuration file
- ✅ Saves passwords securely

### `validate_deployment.sh`
- ✅ Checks all files exist
- ✅ Verifies database connection
- ✅ Tests Apache configuration
- ✅ Validates permissions
- ✅ Checks PHP extensions
- ✅ Tests web server response

---

## 🔧 Usage Examples

### **Fully Automated (with config):**
```bash
# 1. Create config
sudo bash deploy/config_wizard.sh

# 2. Run setup
sudo bash deploy/server_setup.sh deploy_config.sh

# 3. Upload files (via WinSCP/FileZilla)

# 4. Configure .env and import database

# 5. Validate
sudo bash deploy/validate_deployment.sh
```

### **Semi-Automated (interactive):**
```bash
# Just run - it will prompt you
sudo bash deploy/server_setup.sh
```

---

## ⚠️ Important Notes

1. **Save Passwords:** The setup script generates passwords - save them!
2. **Run as Root:** Server scripts need `sudo` or root access
3. **Test First:** Test on a development server before production
4. **Backup:** Always backup before deploying

---

## 🆘 Troubleshooting

**Script permission denied:**
```bash
chmod +x deploy/server_setup.sh
```

**Can't connect to database:**
- Check `.env` file has correct credentials
- Verify MySQL is running: `systemctl status mysql`

**Files not found:**
- Make sure you're in the correct directory
- Check file paths in scripts

**Apache errors:**
```bash
tail -f /var/log/apache2/error.log
apache2ctl configtest
```

---

## 📚 More Information

- See `AUTOMATED_DEPLOYMENT.md` for complete guide
- See `../DIGITALOCEAN_DEPLOYMENT_GUIDE.md` for manual steps
- See `../DEPLOYMENT_CHECKLIST.md` for checklist

---

**Happy Deploying! 🎉**

