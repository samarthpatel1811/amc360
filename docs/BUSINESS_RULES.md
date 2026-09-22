# AMC360 — Business Rules Specification

## 1. Multi-Tenant Data Isolation
- **Tenant Key**: Every tenant-owned table contains `company_id`.
- **Enforcement**:
  - Global query scope applied on all Eloquent models to scope by authenticated user's `company_id`.
  - Backend authorization policies verify that both the operating user and the targeted resources share the same `company_id`.
  - No customer can view another customer's data even within the same company.
  - No technician can view or mutate unassigned jobs or private financial configuration.

## 2. Contract Dates & Duration Arithmetic
- **Start & End Dates**: Stored as standard ISO 8601 calendar dates (`YYYY-MM-DD`).
- **Preset Durations**:
  - 1 Month: Start date + 1 month minus 1 day (e.g., 2026-09-17 $\to$ 2026-10-16).
  - 3 Months: Start date + 3 months minus 1 day (e.g., 2026-09-17 $\to$ 2026-12-16).
  - 6 Months, 12 Months, 24 Months follow the same standard date-boundary logic.
- **Month-End Rule**:
  - If a start date is on the last day of a month (e.g., 2027-01-31), adding 1 month targets the last day of the subsequent month (e.g., 2027-02-28, or 2028-02-29 in leap years).
- **Custom Duration**:
  - Admin may choose any arbitrary start and end dates where `end_date > start_date`.

## 3. Service Frequency & Scheduling Engine
- **Decoupling**: Contract duration and service frequency are strictly decoupled.
- **Frequency Options**:
  - `weekly`: Every 7 days
  - `biweekly`: Every 14 days
  - `monthly`: Every 1 month
  - `bimonthly`: Every 2 months
  - `quarterly`: Every 3 months
  - `four_monthly`: Every 4 months
  - `half_yearly`: Every 6 months
  - `yearly`: Every 12 months
  - `custom_days`: Every $N$ days
  - `custom_months`: Every $N$ months
- **First Visit Rules**:
  - Option 1 (`start_date`): First visit generated on the contract start date.
  - Option 2 (`after_interval`): First visit generated after the first frequency interval.
  - Option 3 (`custom_date`): First visit generated on a custom designated date within contract range.
- **Visit Boundary & Count Restrictions**:
  - Service visits are strictly never automatically scheduled past the contract `end_date`.
  - If a fixed visit count (e.g. 7 visits) is specified, at most 7 included visits are generated.
  - Manually scheduled or extra visits outside contract bounds must be explicitly flagged as `chargeable`.

## 4. Financial Calculations & Invoicing
- **Formula**:
  $$\text{Taxable Amount} = \max(0, \text{Subtotal} - \text{Discount})$$
  $$\text{Tax Amount} = \text{Taxable Amount} \times \left(\frac{\text{Tax Rate}}{100}\right)$$
  $$\text{Total Invoice Amount} = \text{Taxable Amount} + \text{Tax Amount}$$
  $$\text{Balance Due} = \max(0, \text{Total Invoice Amount} - \text{Total Paid})$$
- **Invoice Status Transitions**:
  - `Draft`: Initial editable state.
  - `Issued`: Formal invoice delivered to client.
  - `Partially Paid`: $0 < \text{Total Paid} < \text{Total Invoice Amount}$.
  - `Paid`: $\text{Total Paid} \ge \text{Total Invoice Amount}$ (Balance = 0).
  - `Cancelled`: Voided invoice (historical audit retained).
- **Immutability of Historical Rates**:
  - Applied tax rate, tax amount, and discount amount are permanently stored on the invoice row to prevent future company setting updates from altering historical financial records.

## 5. Service Visit Lifecycle & Field Rules
- **Lifecycle States**:
  - `Scheduled` $\to$ `In Progress` (started by technician with timestamp) $\to$ `Completed` (or `Cancelled`).
- **Completion Requirements**:
  - All mandatory checklist items answered.
  - Service notes (work performed, findings, recommendation) provided.
  - Digital signature captured (unless configured as optional by admin).
  - Parts recorded with coverage classification (`Included in AMC`, `Chargeable`, `Warranty`).
- **Immutability of Completed Records**:
  - Once marked `Completed`, historical service data (completion timestamp, checklist responses, photos, technician ID, customer signature) cannot be overwritten through standard UI.

## 6. Contract Renewal
- **Preservation Principle**:
  - Renewal does NOT mutate or overwrite the expiring/expired contract.
  - A new contract record is created, referencing `renewed_from_contract_id`.
  - Previous contract remains in `Expired` or `Renewed` status for full auditing.

## 7. Offline Synchronization & Idempotency
- **Client Operation ID**: Every offline mutation is tagged with a client-generated UUID `local_operation_id`.
- **Idempotency Guarantee**: The backend checks `local_operation_id`. If an operation has already been processed, the backend returns the existing resource without re-executing business logic or creating duplicate reports/invoices.
- **Conflict Resolution**: Reference data follows "server wins". Unsynced technician forms remain locally protected and prompt the technician if a server-side conflict occurs.
