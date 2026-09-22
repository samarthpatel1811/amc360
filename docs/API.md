# AMC360 REST API Specification (v1)

Base URL: `http://<host>:<port>/api/v1`

All requests and responses use `application/json` format unless downloading binary reports or uploading media attachments.

---

## 1. Authentication & Security

### `POST /auth/login`
Authenticates a user and returns a Laravel Sanctum bearer token.

**Request Body:**
```json
{
  "email": "admin@cooltech.com",
  "password": "Secret@123"
}
```

**Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "1|sanctum_token_string_here",
    "user": {
      "id": 1,
      "company_id": 1,
      "name": "CoolTech Admin",
      "email": "admin@cooltech.com",
      "role": "admin"
    },
    "company": {
      "id": 1,
      "name": "CoolTech Air Conditioning Services",
      "business_type": "hvac",
      "currency_symbol": "₹",
      "default_tax_rate": "18.00"
    }
  }
}
```

### `GET /auth/me`
Returns current authenticated session user and company data.
*Requires `Authorization: Bearer <token>`.*

---

## 2. Customers

### `GET /customers`
Query parameters: `search`, `customer_type`, `page`, `per_page`.

### `POST /customers`
Creates a customer and optionally a customer portal user account.
```json
{
  "name": "Regency Towers Co-Op Housing Society",
  "company_name": "Regency Towers",
  "customer_type": "commercial",
  "contact_person": "Vikram Patel",
  "phone": "+91 98250 11223",
  "email": "manager@regency.com",
  "address_line_1": "Plot 42, Satellite Road",
  "city": "Ahmedabad",
  "state": "Gujarat",
  "postal_code": "380015",
  "create_user_account": true,
  "user_password": "Customer@123"
}
```

---

## 3. Assets & Equipment

### `GET /assets`
Query parameters: `customer_id`, `status`, `search`.

### `POST /assets`
Registers an asset with automatic QR token generation:
```json
{
  "customer_id": 1,
  "asset_category_id": 1,
  "name": "Server Room VRV Indoor Unit 01",
  "brand": "Daikin",
  "model_number": "FXFQ50AVEB",
  "serial_number": "DKN-VRV-94812",
  "capacity": "2.0 TR",
  "location_in_facility": "2nd Floor Server Room"
}
```

### `GET /assets/qr/{qrToken}`
Resolves an asset from its unique printed QR code, returning asset specifications, active AMC contract, and service history.

---

## 4. Annual Maintenance Contracts (AMC)

### `POST /contracts/preview-dates`
Simulates exact visit schedule dates without persisting to database:
```json
{
  "start_date": "2026-04-01",
  "duration_type": "12_months",
  "service_frequency": "quarterly",
  "first_visit_rule": "immediate"
}
```

### `POST /contracts`
Creates an AMC agreement, links equipment, and automatically generates service visit schedule dates:
```json
{
  "customer_id": 1,
  "title": "Comprehensive HVAC AMC - Regency Towers",
  "type": "comprehensive",
  "start_date": "2026-04-01",
  "duration_type": "12_months",
  "service_frequency": "quarterly",
  "first_visit_rule": "immediate",
  "total_price": 45000.00,
  "asset_ids": [1, 2]
}
```

### `POST /contracts/{id}/renew`
Preserves historical contract records and creates a clean continuous renewal contract:
```json
{
  "start_date": "2027-04-01",
  "duration_type": "12_months",
  "service_frequency": "quarterly",
  "total_price": 48000.00,
  "asset_ids": [1, 2]
}
```

---

## 5. Field Service Visits & Execution

### `POST /service-visits/start`
Starts a scheduled maintenance visit:
```json
{
  "schedule_id": 1,
  "latitude": 23.0225,
  "longitude": 72.5714,
  "client_operation_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### `POST /service-visits/{id}/checklist`
Updates checklist items with observations and readings:
```json
{
  "items": [
    { "id": 1, "is_passed": true, "value": "230V stable" },
    { "id": 2, "is_passed": true, "value": "Cleaned air filter" }
  ]
}
```

### `POST /service-visits/{id}/parts`
Records spare parts and consumables used:
```json
{
  "part_name": "Capacitor 45uF",
  "quantity": 1,
  "unit_price": 450.00,
  "coverage_type": "included",
  "notes": "Preventive replacement during Q1 maintenance"
}
```

### `POST /service-visits/{id}/signature`
Stores customer digital sign-off:
```json
{
  "signed_by_name": "Vikram Patel",
  "signature_image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
}
```

### `POST /service-visits/{id}/complete`
Freezes the visit record and triggers automatic server-side PDF generation:
```json
{
  "work_performed": "Comprehensive cleaning of condenser and evaporator coils, refrigerant pressure checked, filter washed, and electrical connections tightened.",
  "findings": "System operating within optimal parameters.",
  "recommendations": "Keep outdoor area clear of debris."
}
```

### `GET /service-visits/{id}/pdf`
Returns the generated binary PDF service report for printing, emailing, or preview.

---

## 6. Service Requests (Complaints / SLA)

### `POST /service-requests`
Submits a breakdown complaint ticket with automatic SLA deadline:
```json
{
  "asset_id": 1,
  "title": "Abnormal compressor noise",
  "description": "Vibrating sound during startup in cooling mode",
  "issue_type": "Abnormal Noise / Vibration",
  "priority": "high",
  "preferred_date": "2026-04-15"
}
```

### `POST /service-requests/{id}/assign`
Assigns a field technician:
```json
{
  "technician_id": 2
}
```

---

## 7. Invoicing & Billing

### `POST /invoices`
Generates an invoice:
```json
{
  "customer_id": 1,
  "contract_id": 1,
  "issue_date": "2026-04-01",
  "due_date": "2026-04-15",
  "discount_amount": 0,
  "tax_rate": 18.0,
  "items": [
    {
      "description": "Annual Maintenance Contract - Year 1",
      "quantity": 1,
      "unit_price": 45000.00
    }
  ]
}
```

### `POST /payments`
Records a payment with real-time balance recalculation:
```json
{
  "invoice_id": 1,
  "amount": 25000.00,
  "payment_date": "2026-04-05",
  "payment_method": "bank_transfer",
  "transaction_reference": "NEFT-HDFC-99182312"
}
```

---

## 8. Offline Synchronization

### `POST /sync/offline-queue`
Batch-processes queued offline mobile operations with strict UUID idempotency to ensure zero duplicate records:
```json
{
  "operations": [
    {
      "local_operation_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "entity_type": "service_visit",
      "operation_type": "complete_visit",
      "payload": {
        "visit_id": 1,
        "work_performed": "Service completed offline.",
        "completed_at": "2026-04-10 11:30:00"
      }
    }
  ]
}
```
