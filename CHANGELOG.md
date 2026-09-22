# Changelog

All notable changes to the **AMC360** software package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-17

### Added

#### Core Architecture
* Multi-tenant architecture with global scope `TenantScope` and `company_id` partitioning across all database tables.
* Decoupled contract duration engine supporting 1-month, 3-month, 6-month, 12-month, 24-month, and custom durations with month-end date calculation handling (leap years, 28/29/30/31 days).
* Automatic scheduled visit date generator with support for Monthly, Bi-Monthly, Quarterly, and Half-Yearly frequencies.
* Thread-safe sequential numbering engine for `CUST-`, `AMC-`, `SR-`, `VISIT-`, `SRPT-`, `INV-`, and `PAY-` identifiers.

#### Field Service Execution
* Mobile-first technician job cards with contact phone actions and location directions.
* Interactive dynamic checklist engine supporting Pass, Fail, and quantitative sensor/voltage readings.
* Replacement spare parts and materials tracker with `included` (AMC covered) vs `chargeable` classification.
* Camera photo documentation for "Before" and "After" maintenance verification.
* Touch-enabled digital customer sign-off canvas.
* Automatic server-side signed PDF service report generator via DomPDF with company branding, asset specifications, technician findings, parts table, and embedded signatures.

#### Customer Portal & SLA Ticketing
* Customer self-service portal displaying registered equipment, AMC coverage status, service visit history, and downloadable PDF service reports.
* Service complaint ticketing engine with priority classification and automated SLA countdown timers.

#### Invoicing, Payments & Renewals
* Strict financial calculation service implementing $Subtotal - Discount + Tax = Grand Total$.
* Payment ledger with overpayment validation and real-time balance due deduction.
* Expiry cohorts engine (0–7, 8–30, 31–60, 61–90 days) with 1-tap contract renewals preserving historical agreements.

#### Offline Synchronization
* Client-side offline mutation queue with client-generated UUIDs.
* Idempotent batch sync endpoint (`POST /sync/offline-queue`) ensuring zero duplicated service visits or parts.

#### Quality Assurance & DevOps
* Automated PHPUnit test suite covering contract duration math, financial calculations, authentication, and tenant isolation.
* Automated Flutter test suite covering billing calculations, offline queue storage, and login interface smoke tests.
* Docker Compose orchestration with PHP 8.2-FPM, Nginx, MariaDB, Redis, and cron scheduler containers.
* Complete documentation suite: API specification, business rules, database schema, installation guides, deployment guide, and QA walkthrough.
