# Step-by-Step: Push to GitHub and Deploy on Digital Ocean

Follow these steps in order. Replace anything in **ALL_CAPS** with your real values.

---

## Part 1: Push Your Project to GitHub

### Step 1.1: Install Git (if you don’t have it)

1. Download Git for Windows: https://git-scm.com/download/win  
2. Run the installer. You can leave default options.  
3. Close and reopen any terminal/PowerShell after installing.

### Step 1.2: Open terminal in your project folder

1. Press **Windows + R**, type `powershell`, press Enter.  
2. Go to your project folder:
   ```powershell
   cd C:\xampp\htdocs\SCCDMS2
   ```

### Step 1.3: Turn this folder into a Git repo and push to GitHub

Copy and run **one block at a time** in PowerShell. Replace **YOUR_GITHUB_USERNAME** and **YOUR_REPO_NAME** with your GitHub username and the repository name you created (e.g. `SCCDMS2`).

```powershell
cd C:\xampp\htdocs\SCCDMS2
```

```powershell
git init
```

```powershell
git add .
```

```powershell
git status
```
(You should see a list of files that will be committed. You should **not** see `.env` or `vendor` in the list.)

```powershell
git commit -m "Initial commit - SCC Document Management System"
```

Now add your GitHub repo as “remote” and push. Use your **exact** repo URL.  
If your repo is empty and GitHub shows “create new repo”, the URL is usually:
`https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git`

```powershell
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
```

```powershell
git branch -M main
```

```powershell
git push -u origin main
```

- If Git asks for **username**: type your GitHub username.  
- If Git asks for **password**: use a **Personal Access Token**, not your GitHub password.  
  - To create one: GitHub → Settings → Developer settings → Personal access tokens → Generate new token.  
  - Give it “repo” scope and copy the token. Paste it when asked for password.

After this, your code is on GitHub.

---

## Part 2: Deploy on Digital Ocean

### Step 2.1: Create a Droplet (if you haven’t yet)

1. Log in to https://cloud.digitalocean.com  
2. Click **Create** → **Droplets**  
3. Choose **Ubuntu 22.04 LTS**  
4. Plan: **Basic**, **Regular** (e.g. $6/month)  
5. Choose a datacenter (e.g. closest to you)  
6. Authentication: **Password** (easier) or **SSH key**  
7. Create Droplet and note the **IP address** (e.g. `164.92.xxx.xxx`)

### Step 2.2: Connect to your Droplet

Open PowerShell and run (replace **YOUR_DROPLET_IP** with the IP from Step 2.1):

```powershell
ssh root@YOUR_DROPLET_IP
```

Type `yes` if asked, then enter the root password you set.  
You should see something like `root@your-droplet:~#` — you’re on the server.

### Step 2.3: Install Apache, PHP, MySQL, and Composer

Copy and paste **each block** one at a time on the server:

```bash
apt update && apt upgrade -y
```

```bash
apt install apache2 -y
```

```bash
apt install php php-mysql php-mbstring php-xml php-curl php-zip php-gd php-intl -y
```

```bash
apt install mysql-server -y
```

```bash
mysql_secure_installation
```
- Current password: just press **Enter**  
- Set a **strong root password** and remember it  
- Answer **Y** to the rest

```bash
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
```

```bash
systemctl start apache2
systemctl start mysql
systemctl enable apache2
systemctl enable mysql
```

### Step 2.4: Create database and user

```bash
mysql -u root -p
```

(Enter the MySQL root password you set.)

Inside MySQL, run (replace **YourSecurePassword123** with a strong password):

```sql
CREATE DATABASE scc_dms CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'sccdms_user'@'localhost' IDENTIFIED BY 'YourSecurePassword123';
GRANT ALL PRIVILEGES ON scc_dms.* TO 'sccdms_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 2.5: Get your code from GitHub

Replace **YOUR_GITHUB_USERNAME** and **YOUR_REPO_NAME** with your GitHub repo details. If the repo is **private**, use a Personal Access Token in the URL:  
`https://YOUR_TOKEN@github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git`

```bash
cd /var/www
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git sccdms
cd sccdms
```

### Step 2.6: Create `.env` and set permissions

```bash
cp config/production.env.example .env
nano .env
```

In the editor:

- Set `DB_PASSWORD=` to the same password you used for `sccdms_user` (e.g. `YourSecurePassword123`)  
- Set `DB_USERNAME=sccdms_user` and `DB_NAME=scc_dms`  
- Save: **Ctrl+O**, Enter, then **Ctrl+X**

```bash
chown -R www-data:www-data /var/www/sccdms
chmod -R 755 /var/www/sccdms
```

### Step 2.7: Import database and install PHP dependencies

From your **Windows** machine, copy the database file to the server (in a **new** PowerShell window, from your project folder):

```powershell
scp C:\xampp\htdocs\SCCDMS2\database\scc_dms.sql root@YOUR_DROPLET_IP:/tmp/
```

Back **on the server** (SSH session):

```bash
mysql -u sccdms_user -p scc_dms < /tmp/scc_dms.sql
```

(Use the same password you set for `sccdms_user`.)

```bash
cd /var/www/sccdms
composer install --no-dev --optimize-autoloader
```

### Step 2.8: Configure Apache

```bash
nano /etc/apache2/sites-available/sccdms.conf
```

Paste this (replace **yourdomain.com** with your domain or leave as-is and use the droplet IP for now):

```apache
<VirtualHost *:80>
    ServerName yourdomain.com
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

Save: **Ctrl+O**, Enter, **Ctrl+X**.

```bash
a2ensite sccdms.conf
a2enmod rewrite
systemctl restart apache2
```

### Step 2.9: Open the site

In your browser go to: **http://YOUR_DROPLET_IP**

You should see your SCC DMS (login page). If you use a domain later, point its A record to this IP and set `ServerName` in the Apache config to that domain.

---

## Quick reference

| What | Where |
|------|--------|
| GitHub repo URL | `https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME` |
| Droplet IP | Digital Ocean → Droplets → your droplet → IP |
| Site on server | `/var/www/sccdms` |
| Config (passwords, DB) | `/var/www/sccdms/.env` |
| Restart Apache | `systemctl restart apache2` |

---

## If something goes wrong

- **Git push asks for password**  
  Use a GitHub Personal Access Token instead of your GitHub password.

- **SSH “Connection refused”**  
  Check the droplet IP and that the droplet is running. On Digital Ocean, check the firewall (e.g. allow SSH).

- **Site shows 404 or blank**  
  Check: `ls /var/www/sccdms` and that `index.php` exists. Restart Apache: `systemctl restart apache2`.

- **“Database connection failed”**  
  Check `.env`: `DB_HOST=localhost`, `DB_USERNAME=sccdms_user`, `DB_PASSWORD=` (correct password), `DB_NAME=scc_dms`.  
  Test: `mysql -u sccdms_user -p scc_dms` (should log in).

- **Google Login / AI not working**  
  In Google Cloud Console, add your production URL (e.g. `https://yourdomain.com/google_auth_callback.php`) to Authorized redirect URIs. Put your Gemini API key and Google client ID/secret in `.env` (see `config/production.env.example`).

You can do this step by step; if you tell me where you’re stuck (e.g. “Step 1.3 push” or “Step 2.5 clone”), I can give you exact commands for that step.
