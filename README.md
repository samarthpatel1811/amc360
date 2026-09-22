# AMC360 — AMC, Asset & Service Management

<p align="center">
  <img src="https://raw.githubusercontent.com/flutter/assets/master/flutter_logo.png" height="50" alt="Flutter" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" height="40" alt="Laravel" />
</p>

<p align="center">
  <strong>Production-Grade Multi-Tenant Software for Annual Maintenance Contracts, Equipment & Field Services</strong>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#technology-stack">Tech Stack</a> •
  <a href="#folder-structure">Structure</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#demo-accounts">Demo Accounts</a>
</p>

---

## 🚀 Product Overview

**AMC360** is a complete, commercial-ready software application engineered for service businesses managing Annual Maintenance Contracts (AMC), preventive maintenance schedules, physical assets/equipment, field technicians, complaint ticketing, digital job sheets, customer digital signatures, PDF reports, invoicing, payments, renewals, and offline field operations.

Designed from the ground up to support any maintenance vertical without source code modification:
* AC & HVAC Maintenance
* Elevator & Lift Maintenance
* DG Set & Generator Maintenance
* Solar Power & Inverter Maintenance
* CCTV & Security Systems
* RO & Water Purifier Maintenance
* Fire Safety & Suppression Systems
* Electrical, Plumbing & Facility Services
* Industrial Machinery & Equipment

---

## ✨ Key Features

1. **True Multi-Tenant Isolation:**
   Every customer, asset, contract, schedule, visit, invoice, and log entry is strictly partitioned by `company_id`. No cross-tenant data leakage.

2. **Decoupled AMC Contract & Schedule Engine:**
   Independent duration (e.g. 1 Year, 3 Months, 24 Months) and visit frequency (Monthly, Bi-Monthly, Quarterly, Half-Yearly) with month-end date calculation handling (leap years, 28/29/30/31 days).

3. **Field Technician Execution:**
   Mobile-first job cards with one-tap client calls, navigation, interactive checklist inspection (Pass/Fail/Observations/Readings), before/after photo documentation, spare parts coverage classification (`included` in AMC vs `chargeable`), and digital customer sign-off.

4. **Official Server-Side PDF Service Reports:**
   Automated PDF service report compilation via DomPDF with company branding, asset specifications, technician findings, parts table, and embedded digital signatures.

5. **Complaints & SLA Ticketing:**
   Emergency breakdown complaint logging with automatic SLA resolution countdown, priority classification, and technician assignment.

6. **Invoicing & Payments:**
   Automated billing calculations ($Subtotal - Discount + Tax = Total$), payment recording, overpayment validation, and dynamic balance tracking.

7. **Expiry Cohorts & Renewals:**
   Proactive renewal pipeline partitioned into urgency cohorts (0–7, 8–30, 31–60, 61–90 days). One-tap renewals preserve historical records while generating clean continuous schedules.

8. **Offline Synchronization:**
   Local SQLite / SharedPreferences mutation queue with client-generated UUIDs and server-side idempotent sync (`/sync/offline-queue`) ensuring zero duplicates.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Mobile Client** | Flutter 3.22+, Riverpod 3, GoRouter 17, Dio 5, Printing, Signature |
| **Backend API** | Laravel 11, PHP 8.2+, Laravel Sanctum, Barryvdh DomPDF |
| **Database** | MariaDB 10.4+ / MySQL 8.0+ |
| **Containerization** | Docker, Docker Compose, Nginx, Redis 7 |

---

## 📁 Folder Structure

```
amc360/
├── backend/                  # Laravel 11 REST API Backend
│   ├── app/
│   │   ├── Http/Controllers/Api/V1/   # 14 Multi-Tenant REST API Controllers
│   │   ├── Models/                    # Eloquent Models with BelongsToCompany
│   │   └── Services/                  # Core Business Services (Math, PDF, Audit)
│   ├── database/migrations/           # 14 Multi-Tenant Database Migrations
│   ├── resources/views/reports/       # Blade Template for Signed PDF Service Reports
│   ├── routes/api.php                 # 64 Registered REST API Endpoints
│   └── tests/                         # Unit & Feature Test Suites
├── mobile/                   # Flutter Mobile Client (iOS & Android)
│   ├── lib/
│   │   ├── app/                       # Config, Theme, Routing
│   │   ├── core/                      # ApiClient, Storage, Common UI Widgets
│   │   └── features/                  # 10 Functional Modules & Role Dashboards
│   └── test/                          # Unit & Widget Test Suites
├── deployment/               # DevOps & Production Orchestration
│   ├── Dockerfile                     # PHP 8.2 FPM Image
│   ├── docker-compose.yml             # App, DB, Redis, Nginx, Scheduler
│   └── nginx.conf                     # Production Reverse Proxy Config
└── docs/                     # Full Documentation Suite
    ├── API.md                         # Complete REST API Reference
    ├── BUSINESS_RULES.md              # Domain Business Logic Specification
    ├── DATABASE.md                    # Database Schema & Entity Relationships
    ├── BACKEND_INSTALLATION.md        # Backend Setup Guide
    ├── MOBILE_INSTALLATION.md         # Mobile Setup Guide
    ├── DEPLOYMENT.md                  # Production DevOps Guide
    └── TESTING.md                     # QA & Test Execution Guide
```

---

## ⚡ Quick Start

### 1. Backend Setup
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve --port=8000
```

### 2. Mobile Setup
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Docker Compose (Alternative)
```bash
cd deployment
docker-compose up -d --build
docker-compose exec app php artisan migrate --seed --force
docker-compose exec app php artisan storage:link
```

---

## 👥 Demo Accounts (Pre-Seeded)

The database seeder provisions a fully-populated demonstration environment:

| Role | Email | Password | Access |
|---|---|---|---|
| **Company Admin** | `admin@cooltech.com` | `Secret@123` | Full administrative, customer, technician, contract & financial control |
| **Field Technician** | `rahul.tech@cooltech.com` | `Secret@123` | Mobile job card, checklist, parts, photo upload, and customer signature |
| **Customer** | `customer1@regency.com` | `Customer@123` | Customer portal, registered assets, AMC status, PDF service reports, bills |

---

## 📚 Documentation

For complete technical documentation, refer to the `docs/` directory:
* [REST API Specification](docs/API.md)
* [Business Rules & Formulas](docs/BUSINESS_RULES.md)
* [Database Schema & ERD](docs/DATABASE.md)
* [Backend Installation](docs/BACKEND_INSTALLATION.md)
* [Mobile Installation](docs/MOBILE_INSTALLATION.md)
* [Production Deployment](docs/DEPLOYMENT.md)
* [Testing & QA Walkthrough](docs/TESTING.md)

---

## 📄 License
Commercial proprietary software. Please see [LICENSE-PLACEHOLDER.md](LICENSE-PLACEHOLDER.md) for licensing terms.
