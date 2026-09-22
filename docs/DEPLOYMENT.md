# AMC360 — Production Deployment & DevOps Guide

This guide describes how to deploy AMC360 to a production cloud server (AWS, DigitalOcean, Hetzner, Linode, or bare-metal VPS) using Docker Compose or traditional systemd/Nginx configurations.

---

## 1. Architecture Overview

```
 [Client Devices: iOS / Android / Web Admin]
                     │
               HTTPS (Port 443)
                     ▼
         [Nginx Reverse Proxy & SSL]
                     │
         FastCGI (Port 9000)
                     ▼
             [PHP 8.2-FPM App]
              /            \
       MySQL/MariaDB     Redis (Cache & Queues)
        (Port 3306)       (Port 6379)
```

---

## 2. Option A: Docker Compose Deployment (Recommended)

### Step 1: Clone Repository
```bash
git clone https://github.com/your-org/amc360.git /var/www/amc360
cd /var/www/amc360/deployment
```

### Step 2: Configure Production Environment
Edit `.env` in `backend/` and `docker-compose.yml` to supply production database passwords and encryption keys:
```bash
php -r "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"
```

### Step 3: Launch Containers
```bash
docker-compose up -d --build
```

### Step 4: Run Initial Migrations in Container
```bash
docker-compose exec app php artisan migrate --force
docker-compose exec app php artisan db:seed --force
docker-compose exec app php artisan storage:link
```

---

## 3. Option B: Native Ubuntu 22.04 / 24.04 LTS VPS Deployment

### Step 1: Install Required Packages
```bash
sudo apt update && sudo apt install -y \
  nginx mariadb-server php8.2-fpm php8.2-mysql php8.2-bcmath \
  php8.2-gd php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip redis-server certbot python3-certbot-nginx
```

### Step 2: Configure MariaDB Database
```sql
CREATE DATABASE amc360 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'amc_user'@'localhost' IDENTIFIED BY 'STRONG_SECRET_PASSWORD';
GRANT ALL PRIVILEGES ON amc360.* TO 'amc_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 3: Deploy Application Code
```bash
sudo mkdir -p /var/www/amc360
sudo chown -R $USER:www-data /var/www/amc360
git clone https://github.com/your-org/amc360.git /var/www/amc360
cd /var/www/amc360/backend
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
php artisan migrate --force
php artisan db:seed --force
php artisan storage:link
```

### Step 4: Permissions
```bash
sudo chown -R www-data:www-data /var/www/amc360/backend/storage /var/www/amc360/backend/bootstrap/cache
sudo chmod -R 775 /var/www/amc360/backend/storage /var/www/amc360/backend/bootstrap/cache
```

### Step 5: Configure Nginx & SSL
Copy `deployment/nginx.conf` to `/etc/nginx/sites-available/amc360.conf`:
```bash
sudo cp /var/www/amc360/deployment/nginx.conf /etc/nginx/sites-available/amc360.conf
sudo ln -s /etc/nginx/sites-available/amc360.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d api.yourdomain.com
```

### Step 6: Production Optimizations
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## 4. Automated Daily Backups

Set up an automated daily backup script in `/etc/cron.daily/amc360-backup`:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/amc360"
mkdir -p "$BACKUP_DIR"

# Backup MySQL Database
mysqldump -u amc_user -p'amc360_secret' amc360 | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Backup Uploaded Attachments and Reports
tar -czf "$BACKUP_DIR/storage_$DATE.tar.gz" /var/www/amc360/backend/storage/app/public

# Keep only last 30 days
find "$BACKUP_DIR" -type f -mtime +30 -delete
```
Make it executable:
```bash
chmod +x /etc/cron.daily/amc360-backup
```
