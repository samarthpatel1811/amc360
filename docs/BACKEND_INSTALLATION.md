# AMC360 — Backend Installation Guide

This guide details the complete step-by-step installation, environment configuration, database migration, and background daemon setup for the **AMC360** production REST API backend.

---

## 1. System Requirements

* **PHP:** 8.2 or 8.3 with the following extensions enabled:
  * `pdo`, `pdo_mysql`
  * `mbstring`, `bcmath`
  * `gd` (required for signature and image processing)
  * `tokenizer`, `xml`, `ctype`, `json`, `curl`, `zip`
* **Database:** MariaDB 10.4+ or MySQL 8.0+
* **Composer:** 2.2+
* **Web Server:** Nginx (recommended) or Apache (with `mod_rewrite`)

---

## 2. Step-by-Step Installation

### Step 1: Navigate to Backend Directory
```bash
cd backend
```

### Step 2: Install PHP Dependencies via Composer
```bash
composer install --optimize-autoloader --no-interaction
```

### Step 3: Configure Environment Variables
Copy the template configuration file:
```bash
cp .env.example .env
```

Generate the encryption key:
```bash
php artisan key:generate
```

Update your database credentials in `.env`:
```env
APP_NAME=AMC360
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=amc360
DB_USERNAME=amc_user
DB_PASSWORD=amc360_secret

# Session & Cache
CACHE_STORE=file
QUEUE_CONNECTION=database
SESSION_DRIVER=file

# Filesystem
FILESYSTEM_DISK=public
```

### Step 4: Run Migrations and Seed Master Catalogs
Execute migrations to create all multi-tenant tables, foreign keys, and indexes:
```bash
php artisan migrate --force
```

To seed the initial demonstration company, roles, equipment catalogs, checklist templates, and sample users:
```bash
php artisan db:seed --force
```

### Step 5: Create Public Storage Symlink
Link the `storage/app/public` directory to `public/storage` so that uploaded visit photos and signatures are accessible over HTTP:
```bash
php artisan storage:link
```

---

## 3. Background Services & Cron Schedules

AMC360 runs an automated contract expiry, renewal notification, and SLA escalation processor every day at 00:01 AM.

### Production Crontab Setup
Add the following line to your server's `crontab` (via `crontab -e`):
```cron
* * * * * cd /path/to/amc360/backend && php artisan schedule:run >> /dev/null 2>&1
```

### Manual Maintenance Command Execution
To immediately trigger the contract status and expiry check:
```bash
php artisan amc360:process-maintenance-schedules
```

---

## 4. Local Development Server
To launch the development server on port 8000:
```bash
php artisan serve --host=127.0.0.1 --port=8000
```

Verify backend health by calling:
```bash
curl http://127.0.0.1:8000/api/v1/auth/me
# Expected: {"message":"Unauthenticated."}
```
