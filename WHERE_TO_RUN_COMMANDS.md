# 📍 Where to Run Each Command - Simple Guide

This guide shows you **exactly where** to run each command - on your **Windows computer** or on your **DigitalOcean server**.

---

## 🖥️ **ON YOUR WINDOWS COMPUTER** (Local)

These commands run in **PowerShell** or **Command Prompt** on your computer.

### **Step 1: Prepare Files**

**Location:** Your Windows computer  
**Where:** PowerShell in the `SCCDMS2` folder

**Option A - Double-click (Easiest):**
```
Just double-click: deploy\prepare_files.bat
```

**Option B - PowerShell:**
1. Open PowerShell
2. Navigate to your project:
   ```powershell
   cd C:\xampp\htdocs\SCCDMS2
   ```
3. Run:
   ```powershell
   .\deploy\prepare_local.ps1
   ```

**What it does:** Prepares files in `deploy\files_to_upload\` folder

---

## 🌐 **ON YOUR DIGITALOCEAN SERVER** (Remote)

These commands run **after you connect to your server** via SSH.

### **How to Connect to Server:**

1. **Open PowerShell or Command Prompt** on your Windows computer
2. **Connect via SSH:**
   ```bash
   ssh root@YOUR_IP_ADDRESS
   ```
   Replace `YOUR_IP_ADDRESS` with your actual server IP (like `123.456.789.012`)

3. **Enter password** when prompted (or use SSH key)

4. **You're now on the server!** You'll see a prompt like:
   ```
   root@sccdms-server:~#
   ```

---

### **Step 2: Upload Setup Script**

**Location:** Your Windows computer  
**Tool:** WinSCP or FileZilla

1. **Open WinSCP** (download from winscp.net if needed)
2. **Connect to server:**
   - Host: `YOUR_IP_ADDRESS`
   - Username: `root`
   - Password: Your server password
3. **Upload file:**
   - From: `C:\xampp\htdocs\SCCDMS2\deploy\server_setup.sh`
   - To: `/root/server_setup.sh` on server

---

### **Step 3: Run Server Setup**

**Location:** DigitalOcean Server  
**Where:** SSH terminal (after connecting)

```bash
# Make script executable
chmod +x /root/server_setup.sh

# Run the setup
sudo bash /root/server_setup.sh
```

**Wait 5-10 minutes** - it will install everything automatically!

---

### **Step 4: Upload Website Files**

**Location:** Your Windows computer  
**Tool:** WinSCP or FileZilla

1. **Connect to server** (same as Step 2)
2. **Upload ALL files:**
   - From: `C:\xampp\htdocs\SCCDMS2\deploy\files_to_upload\` (on your computer)
   - To: `/var/www/sccdms` (on server)
3. **Select all files and folders**, drag them to the server

---

### **Step 5: Configure Application**

**Location:** DigitalOcean Server  
**Where:** SSH terminal

```bash
# Go to application folder
cd /var/www/sccdms

# Copy .env template
cp .env.example .env

# Edit .env file
nano .env
```

**In nano editor:**
- Update the database password (from Step 3 output)
- Save: Press `Ctrl+X`, then `Y`, then `Enter`

---

### **Step 6: Import Database**

**Location:** DigitalOcean Server  
**Where:** SSH terminal

```bash
# Still in /var/www/sccdms folder
mysql -u sccdms_user -p scc_dms < database/scc_dms.sql
```

Enter the database password when prompted.

---

### **Step 7: Install Dependencies**

**Location:** DigitalOcean Server  
**Where:** SSH terminal

```bash
# Still in /var/www/sccdms folder
composer install --no-dev --optimize-autoloader
```

---

### **Step 8: Set Permissions**

**Location:** DigitalOcean Server  
**Where:** SSH terminal

```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
```

---

### **Step 9: Validate (Optional)**

**Location:** DigitalOcean Server  
**Where:** SSH terminal

```bash
# First, upload validate_deployment.sh to server (via WinSCP)
# Then run:
sudo bash /root/validate_deployment.sh
```

---

## 📊 **Quick Reference Table**

| Step | Command | Where to Run |
|------|---------|--------------|
| **1. Prepare files** | `.\deploy\prepare_local.ps1` | 🖥️ Windows (PowerShell) |
| **2. Upload setup script** | (Use WinSCP/FileZilla) | 🖥️ Windows (WinSCP) |
| **3. Run server setup** | `sudo bash /root/server_setup.sh` | 🌐 Server (SSH) |
| **4. Upload website files** | (Use WinSCP/FileZilla) | 🖥️ Windows (WinSCP) |
| **5. Configure .env** | `nano .env` | 🌐 Server (SSH) |
| **6. Import database** | `mysql -u sccdms_user -p scc_dms < database/scc_dms.sql` | 🌐 Server (SSH) |
| **7. Install dependencies** | `composer install` | 🌐 Server (SSH) |
| **8. Set permissions** | `chown -R www-data:www-data /var/www/sccdms` | 🌐 Server (SSH) |
| **9. Validate** | `sudo bash /root/validate_deployment.sh` | 🌐 Server (SSH) |

---

## 🎯 **Visual Guide**

```
┌─────────────────────────────────────────────────┐
│  YOUR WINDOWS COMPUTER                           │
│  (Local - PowerShell/Command Prompt)             │
├─────────────────────────────────────────────────┤
│  ✓ Prepare files                                 │
│  ✓ Upload files via WinSCP/FileZilla            │
└─────────────────────────────────────────────────┘
                    ↕ SSH Connection ↕
┌─────────────────────────────────────────────────┐
│  DIGITALOCEAN SERVER                             │
│  (Remote - SSH Terminal)                         │
├─────────────────────────────────────────────────┤
│  ✓ Run server setup script                      │
│  ✓ Configure .env file                          │
│  ✓ Import database                              │
│  ✓ Install dependencies                         │
│  ✓ Set permissions                              │
└─────────────────────────────────────────────────┘
```

---

## 🔑 **Key Points**

1. **Windows Commands:**
   - Run in PowerShell or Command Prompt
   - On your local computer
   - Usually start with `.\` or `cd`

2. **Server Commands:**
   - Run in SSH terminal
   - After connecting: `ssh root@YOUR_IP`
   - Usually start with `sudo` or `cd /var/www/`

3. **File Uploads:**
   - Use WinSCP or FileZilla
   - From Windows → To Server
   - Drag and drop files

---

## 🆘 **Common Questions**

**Q: How do I know if I'm on the server?**  
A: Your prompt will show `root@server-name:~#` instead of `C:\>`

**Q: Can I copy-paste commands?**  
A: Yes! Right-click in PowerShell/SSH to paste

**Q: What if I get "command not found"?**  
A: Make sure you're in the right location:
   - Windows: `cd C:\xampp\htdocs\SCCDMS2`
   - Server: `cd /var/www/sccdms`

**Q: How do I exit SSH?**  
A: Type `exit` or press `Ctrl+D`

---

## 📝 **Step-by-Step Example**

### **Example: Running Server Setup**

1. **On Windows** - Open PowerShell:
   ```
   C:\Users\YourName>
   ```

2. **Connect to server:**
   ```bash
   ssh root@123.456.789.012
   ```

3. **Now you're on server** - Notice the prompt changed:
   ```
   root@sccdms-server:~#
   ```

4. **Run commands on server:**
   ```bash
   chmod +x /root/server_setup.sh
   sudo bash /root/server_setup.sh
   ```

5. **When done, exit:**
   ```bash
   exit
   ```

6. **Back on Windows:**
   ```
   C:\Users\YourName>
   ```

---

**That's it! Now you know where to run each command! 🎉**

