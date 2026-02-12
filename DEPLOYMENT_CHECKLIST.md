# ✅ DigitalOcean Deployment Checklist

Use this checklist as you go through the deployment process.

## Pre-Deployment
- [ ] DigitalOcean account created
- [ ] Domain name purchased (optional)
- [ ] Website files ready on local computer
- [ ] Database backup created (from local XAMPP)

## Step 1: Create Droplet
- [ ] Droplet created with Ubuntu 22.04 LTS
- [ ] IP address saved
- [ ] SSH key or password set up

## Step 2: Connect to Server
- [ ] Successfully connected via SSH
- [ ] Can see server command prompt

## Step 3: Install Software
- [ ] System updated (`apt update && apt upgrade`)
- [ ] Apache installed
- [ ] PHP installed with extensions
- [ ] MySQL installed
- [ ] MySQL secured with password
- [ ] Composer installed
- [ ] All services running

## Step 4: Database Setup
- [ ] Database `scc_dms` created
- [ ] Database user `sccdms_user` created
- [ ] Database password saved securely
- [ ] Permissions granted

## Step 5: Upload Files
- [ ] WinSCP/FileZilla installed
- [ ] Connected to server via SFTP
- [ ] All files uploaded to `/var/www/sccdms`
- [ ] File permissions set correctly

## Step 6: Apache Configuration
- [ ] Apache config file created
- [ ] Site enabled
- [ ] mod_rewrite enabled
- [ ] Apache restarted

## Step 7: Application Configuration
- [ ] `.env` file created with database credentials
- [ ] Database imported from SQL file
- [ ] Composer dependencies installed
- [ ] File permissions verified

## Step 8: SSL Setup
- [ ] Certbot installed
- [ ] SSL certificate obtained (if domain available)
- [ ] HTTPS working

## Step 9: Firewall
- [ ] UFW firewall enabled
- [ ] SSH access allowed
- [ ] HTTP/HTTPS access allowed

## Step 10: Testing
- [ ] Website loads in browser
- [ ] Can log in
- [ ] Database connection works
- [ ] File uploads work
- [ ] No error messages

## Step 11: Domain Setup (Optional)
- [ ] DNS A record added
- [ ] DNS CNAME record added
- [ ] DNS propagated
- [ ] Domain working

## Step 12: Backups
- [ ] Backup script created
- [ ] Backup script tested
- [ ] Cron job set up for daily backups

## Security
- [ ] MySQL root password changed
- [ ] Separate database user created
- [ ] Firewall configured
- [ ] SSL certificate installed
- [ ] File permissions correct
- [ ] Automatic updates enabled

## Post-Deployment
- [ ] Website fully functional
- [ ] All features tested
- [ ] Error logs checked
- [ ] Backup system verified
- [ ] Documentation saved

---

## 📝 Important Information to Save

**Server IP Address:** _______________________

**SSH Password/Key Location:** _______________________

**MySQL Root Password:** _______________________

**Database User:** `sccdms_user`

**Database Password:** _______________________

**Database Name:** `scc_dms`

**Website Path:** `/var/www/sccdms`

**Domain Name:** _______________________

---

## 🆘 Quick Troubleshooting

**Can't connect via SSH?**
- Check IP address
- Check firewall settings
- Verify SSH key/password

**Website shows 404?**
- Check file location: `ls -la /var/www/sccdms`
- Check Apache config: `apache2ctl -S`
- Check error logs: `tail -f /var/log/apache2/error.log`

**Database connection error?**
- Verify `.env` file credentials
- Test MySQL: `mysql -u sccdms_user -p scc_dms`
- Check MySQL is running: `systemctl status mysql`

**Permission errors?**
- Fix ownership: `chown -R www-data:www-data /var/www/sccdms`
- Fix permissions: `chmod -R 755 /var/www/sccdms`

**500 Internal Server Error?**
- Check PHP errors: `tail -f /var/log/apache2/error.log`
- Check file permissions
- Verify `.env` file exists and is readable

---

**Print this checklist and check off items as you complete them!**

