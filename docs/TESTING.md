# AMC360 — Comprehensive Testing & Quality Assurance Guide

This document outlines the testing strategy, test suites, and instructions for verifying backend logic, mobile applications, and end-to-end multi-tenant workflows for **AMC360**.

---

## 1. Automated Backend Test Suite

The backend test suite is written using PHPUnit / Pest and validates multi-tenant isolation, contract duration calculations with strict month-end handling, invoice financial formulas, and role-based permissions.

### Running Backend Tests
```bash
cd backend
php artisan test
```

### Covered Test Cases

| Test File | Test Method | Business Rule Validated |
|---|---|---|
| `ContractCalculationServiceTest` | `case 1 one month contract duration` | Start `2026-04-01` -> End `2026-04-30` (Exact 1 calendar month minus 1 day). |
| `ContractCalculationServiceTest` | `case 2 three month contract duration` | Start `2026-01-01` -> End `2026-03-31` (Quarterly duration). |
| `ContractCalculationServiceTest` | `case 3 month end date handling` | Leap and non-leap month-end safety (e.g. Jan 31 -> Feb 28/29). |
| `ContractCalculationServiceTest` | `case 4 custom duration` | Custom specified end date overrides standard duration. |
| `ContractCalculationServiceTest` | `case 5 twelve month quarterly visits` | Generates 4 quarterly scheduled visit dates across 12 months. |
| `ContractCalculationServiceTest` | `case 6 fixed visit count cap` | Strict adherence to `included_visit_count` cap. |
| `InvoiceCalculationServiceTest` | `section 107 financial formula` | Subtotal - Discount + Tax = Total; verified against Section 107 spec. |
| `InvoiceCalculationServiceTest` | `paid in full` | Balance due decreases to exactly 0.00 on complete payment. |
| `AuthenticationAndTenantTest` | `admin login success` | Sanctum bearer token issuance and correct user role payload. |
| `AuthenticationAndTenantTest` | `login with invalid password` | Returns `401 Unauthorized` on credential mismatch. |
| `AuthenticationAndTenantTest` | `technician cannot create customer` | Rejects non-admin user with `403 Forbidden`. |
| `AuthenticationAndTenantTest` | `customer isolation from other customers` | Ensures multi-tenant query scope isolates records between companies. |

---

## 2. Automated Mobile Test Suite

The mobile test suite is executed using `flutter test` and validates client-side financial math, offline synchronization queues, and widget rendering.

### Running Mobile Tests
```bash
cd mobile
flutter test
```

### Covered Mobile Test Suites

| Test File | Target | What is Validated |
|---|---|---|
| `test/validation_test.dart` | Math & Date Logic | Client-side billing calculation (tax, discount, balance due) and date intervals. |
| `test/sync_queue_test.dart` | Storage & Sync | `SecureStorageService` offline queue: enqueue, retrieval, specific UUID removal, clear. |
| `test/widget_test.dart` | UI Smoke Test | Renders root `Amc360App` with `ProviderScope`, verifying login branding and tagline. |

---

## 3. End-to-End Multi-Tenant Verification Walkthrough (Section 146 & 147)

Follow this complete lifecycle to verify all operational flows in sequence:

### Flow 1: Company Admin Setup
1. Open application or API and authenticate with `admin@cooltech.com` / `Secret@123`.
2. Navigate to **Customers** -> Tap **Add Customer** -> Create "Apex Medical Center".
3. Navigate to **Assets** -> Add "MRI Chiller Unit 01" with serial `MRI-CH-8821` -> Verify QR token generated.
4. Navigate to **Contracts** -> Create a 12-Month Comprehensive AMC starting `2026-04-01` with Quarterly visits -> Verify 4 visits generated.

### Flow 2: Field Technician Execution
1. Sign in as `rahul.tech@cooltech.com` / `Secret@123`.
2. View **Today's Jobs** on Technician Dashboard -> Locate scheduled visit for "Apex Medical Center".
3. Tap **Start Visit** -> Visit status transitions to `in_progress`.
4. Navigate to **Checklist** tab -> Mark items as `PASS`, enter voltage reading `230V`.
5. Navigate to **Parts** tab -> Add "Relay Switch 24V" (Coverage: `included`).
6. Navigate to **Photos** tab -> Upload "Before" and "After" maintenance photos.
7. Navigate to **Sign-off** tab -> Capture customer digital signature on the canvas and input technician notes.
8. Tap **Complete Visit & Generate Report** -> Server marks visit as `completed`, freezes record, and compiles the official PDF report.

### Flow 3: Billing & Payments
1. Sign back in as Admin -> Navigate to **Invoices**.
2. Locate the invoice generated for the AMC contract.
3. Tap **Record Payment** -> Enter payment amount and transaction reference -> Balance due updates.

### Flow 4: Customer Portal Verification
1. Sign in as Customer (`customer1@regency.com` / `Customer@123`).
2. Verify customer dashboard shows only the customer's own equipment, active AMC, and past visits.
3. Open completed visit -> Tap **View Report PDF** -> Verify report compiles with company logo, equipment specs, checklist readings, parts, and signatures.

### Flow 5: Contract Renewal
1. Sign in as Admin -> Navigate to **Renewals** cohort.
2. Select contract -> Tap **Renew Now** -> Enter new period and price.
3. Verify old contract is marked `renewed` and a new continuous contract with its fresh service schedule is created.

### Flow 6: Offline Field Synchronization
1. Disconnect network or enable Airplane Mode.
2. Execute a visit completion action on the mobile device -> Record is saved to local offline queue with a unique UUID.
3. Re-enable network -> Navigate to **Offline Sync Manager** -> Tap **Sync Pending Operations**.
4. The server processes the queue via `POST /sync/offline-queue` with idempotent deduplication; exactly 1 visit is recorded without duplication.
