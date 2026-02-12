# ⚡ Quick Start: Deploy to DigitalOcean (Automated)

**Fastest way to deploy your website with minimal errors!**

---

## 🎯 **3 Simple Steps**

### **Step 1: Prepare Files (2 minutes)**

**On your Windows computer:**

1. Open PowerShell in the SCCDMS2 folder
2. Run:
   ```powershell
   .\deploy\prepare_local.ps1
   ```
   
   **OR** just double-click: `deploy\prepare_files.bat`

3. Wait for it to finish
4. Files are ready in: `deploy\files_to_upload\`

---

### **Step 2: Setup Server (5-10 minutes)**

**On your DigitalOcean server:**

1. Connect via SSH:
   ```bash
   ssh root@YOUR_IP_ADDRESS
   ```

2. Upload the setup script (using WinSCP/FileZilla):
   - Upload `deploy/server_setup.sh` to `/root/` on server

3. Run the setup:
   ```bash
   chmod +x /root/server_setup.sh
   sudo bash /root/server_setup.sh
   ```

4. **SAVE THE OUTPUT!** It contains important passwords.

5. Wait for it to finish (~5-10 minutes)

---

### **Step 3: Upload & Configure (5 minutes)**

1. **Upload files** (using WinSCP/FileZilla):
   - Upload ALL files from `deploy\files_to_upload\` 
   - To: `/var/www/sccdms` on server

2. **Create .env file** (on server):
   ```bash
   cd /var/www/sccdms
   cp .env.example .env
   nano .env
   ```
   
   Update with passwords from Step 2:
   ```
   DB_HOST=localhost
   DB_USERNAME=sccdms_user
   DB_PASSWORD=<password from setup>
   DB_NAME=scc_dms
   APP_TIMEZONE=Asia/Manila
   ```
   
   Save: `Ctrl+X`, `Y`, `Enter`

3. **Import database**:
   ```bash
   mysql -u sccdms_user -p scc_dms < database/scc_dms.sql
   ```
   (Enter password when asked)

4. **Install dependencies**:
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

5. **Set permissions**:
   ```bash
   chown -R www-data:www-data /var/www/sccdms
   chmod -R 755 /var/www/sccdms
   ```

6. **Validate** (optional but recommended):
   ```bash
   sudo bash deploy/validate_deployment.sh
   ```

---

## ✅ **Done!**

Visit: `http://YOUR_IP_ADDRESS` or `https://yourdomain.com`

---

## 🆘 **Quick Troubleshooting**

**Can't connect to server?**
- Check IP address
- Check firewall allows SSH

**Website shows error?**
- Check `.env` file has correct database password
- Check database was imported: `mysql -u sccdms_user -p scc_dms -e "SHOW TABLES;"`
- Check Apache logs: `tail -f /var/log/apache2/error.log`

**Permission errors?**
```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
```

---

## 📚 **Need More Help?**

- **Detailed guide:** See `deploy/AUTOMATED_DEPLOYMENT.md`
- **Manual steps:** See `DIGITALOCEAN_DEPLOYMENT_GUIDE.md`
- **Checklist:** See `DEPLOYMENT_CHECKLIST.md`

---

**That's it! Your website should be live! 🎉**

