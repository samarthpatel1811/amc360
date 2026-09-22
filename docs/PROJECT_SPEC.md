# AMC360 — Product Specification

## 1. Overview
**AMC360** (Tagline: *AMC, Asset & Service Management*) is a commercial-grade, multi-industry field service and Annual Maintenance Contract management mobile application and backend API platform. It empowers service businesses—including HVAC, Lifts, Generators, Solar, CCTV, Water Purifiers (RO), Fire Safety, Electrical, and Industrial Machinery—to manage their entire service lifecycle without code customization.

## 2. Core Modules
1. **Multi-Tenant Architecture**: Total data isolation per company (`company_id` on all entities).
2. **User Roles**:
   - **Company Admin**: Company profile, technicians, customers, assets, contracts, schedules, parts, invoices, payments, renewals, reports, branding, and audit logs.
   - **Technician**: Mobile job cards, start visit (GPS/timestamp), step-by-step checklist, before/after photos, parts tracking, customer signature, PDF service report generation, offline sync.
   - **Customer**: View covered equipment, active contracts, upcoming visits, completed service history, PDF service reports, raise tickets/complaints with photos, view invoices and payments.
3. **AMC Contract Engine**:
   - Preset durations (1, 3, 6, 12, 24 months) and custom start/end dates.
   - Configurable service frequency (Weekly, Bi-weekly, Monthly, Bi-monthly, Quarterly, Every 4 months, Semi-annually, Annually, Custom interval).
   - First visit rules (start date, after interval, custom date).
   - Fixed or automatic visit count limits.
   - Coverage definitions (parts, emergency visits, labour) and exclusions.
4. **Technician Field Execution**:
   - Dynamic checklist templates (Checkbox, Yes/No, Reading, Pass/Fail, Number, Text).
   - Digital signature capture and timestamping.
   - Server-side PDF report compilation and mobile viewing/sharing.
5. **Billing & Invoicing**:
   - AMC, service, parts, and extra visit invoices.
   - Precise financial math (Subtotal - Discount + Tax = Total).
   - Automatic balance tracking across multiple payments.
6. **Renewals & Auditability**:
   - Expiry cohorts (0–7d, 8–30d, 31–60d, 61–90d).
   - Historical preservation: Renewals create new contracts and schedules without mutating expired historical records.
   - Tamper-evident audit logging of all sensitive actions.
7. **Offline Mode & Synchronization**:
   - Local persistence with SQLite/Drift.
   - Idempotent sync queue preventing duplicate records.
