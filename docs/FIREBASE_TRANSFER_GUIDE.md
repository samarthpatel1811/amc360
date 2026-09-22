# AMC360 — Firebase Console Database Transfer & Connection Guide

This guide explains how your AMC360 database has been exported and how to transfer and view the complete database in **Firebase Console** under your account (**samarthpanara12345@gmail.com**), as well as how the login page connection has been resolved.

---

## 1. Summary of Generated Firebase Export Files

All 34 tables (222 records) from `backend/database/database.sqlite` have been extracted, validated, and formatted into production-ready Firebase files:

| File | Target Firebase Product | How to Transfer |
|---|---|---|
| `backend/database/firebase_realtime_database.json` | **Firebase Realtime Database** | **1-Click Direct Web Upload** in Firebase Console |
| `backend/database/firestore_export.json` | **Cloud Firestore** | Automated batch ingestion via `firebase_firestore_migrate.py` |
| `backend/database/firebase_auth_users.json` | **Firebase Authentication** | User import via Firebase CLI (`auth:import`) or Admin SDK |
| `backend/firebase_firestore_migrate.py` | **Cloud Firestore Uploader** | Python migration tool that pushes all collections to Firestore |

---

## 2. Method A: Instant 1-Click Import into Firebase Realtime Database (Easiest)

Firebase Realtime Database has a native browser upload feature:

1. Open [Google Firebase Console](https://console.firebase.google.com) signed in as **samarthpanara12345@gmail.com**.
2. Select your AMC360 project (or click **"Add project"** and name it `amc360`).
3. In the left navigation bar, go to **Build $\rightarrow$ Realtime Database**.
4. Click **"Create Database"** (choose test mode or locked mode, location: default/closest).
5. On the **Data** tab, click the **three dots menu (⋮)** in the top right corner.
6. Click **"Import JSON"**.
7. Select the file from your computer:
   ```
   /Users/apple/Desktop/amc360/backend/database/firebase_realtime_database.json
   ```
8. Click **Import**.
9. **Done!** Within seconds, all tables (`companies`, `users`, `customers`, `assets`, `contracts`, `service_schedules`, `invoices`, `payments`, etc.) will appear live in your Firebase Console!

---

## 3. Method B: Batch Upload into Cloud Firestore

Cloud Firestore is Google's recommended document database for production apps.

### Step 1: Create Firestore in Firebase Console
1. In [Firebase Console](https://console.firebase.google.com), go to **Build $\rightarrow$ Firestore Database**.
2. Click **"Create database"** (choose native mode and your preferred region).

### Step 2: Download Service Account Key
1. Click the **Gear Icon (⚙️)** in the top left next to *Project Overview* $\rightarrow$ **Project settings**.
2. Navigate to the **Service accounts** tab.
3. Click **"Generate new private key"** $\rightarrow$ Click **"Generate key"**.
4. A `.json` credential file will download (e.g. into your `Downloads` folder).

### Step 3: Run the Migration Script
Run the following terminal command from the project root:

```bash
# Install Firebase Admin SDK (if not already installed)
pip3 install firebase-admin

# Run the live uploader with your downloaded key:
python3 backend/firebase_firestore_migrate.py ~/Downloads/your-downloaded-key.json
```

The script will automatically batch-write all 34 collections directly into Cloud Firestore:
- `companies`
- `users` (with `samarthpanara12345@gmail.com` as primary admin)
- `customers`
- `assets`
- `contracts`
- `service_schedules`
- `service_visits`
- `invoices`
- `payments`
- ...and all remaining reference and relation tables.

When you refresh the **Firestore Database** tab in Firebase Console, all collections and documents with their preserved IDs and relational fields will be immediately visible and editable!

---

## 4. Method C: Firebase Authentication Import

To import all 11 user accounts with their passwords, phone numbers, and role claims (`admin`, `technician`, `customer`):

Using the Firebase CLI:
```bash
firebase auth:import backend/database/firebase_auth_users.json \
  --hash-algo=BCRYPT \
  --rounds=10 \
  --project=YOUR_FIREBASE_PROJECT_ID
```

Your primary administrator account:
- **Email**: `samarthpanara12345@gmail.com`
- **Role**: `admin`
- **Default Password**: `Secret@123`

---

## 5. Login Page Connection Error: How It Has Been Resolved

### Why the error occurred
The Flutter app was attempting to reach an ephemeral Cloudflare tunnel URL:
`https://est-studios-roads-investigator.trycloudflare.com/api/v1`
Because Cloudflare quick tunnels expire when the server shuts down, the domain became unreachable.

### Changes implemented to fix it:
1. **Live Wi-Fi Endpoint Default**:
   `AppConfig.apiBaseUrl` and `currentWifiUrl` are now pointed to your host IP:
   `http://10.20.57.32:8000/api/v1`
   With dead-tunnel protection that automatically discards expired `trycloudflare.com` URLs.
2. **Interactive Connection Diagnostics in Login Screen**:
   - Quick-preset buttons for **Wi-Fi (10.20.57.32)**, **Localhost (127.0.0.1)**, and **Android Emulator (10.0.2.2)**.
   - Built-in **"Test Connection / Ping"** button that performs a live ping with real-time latency and company verification.
   - Quick action in the login error banner: tapping **"Change Server URL / Test Ping"** directly opens the network configuration modal.
3. **Automated Server & Tunnel Bridge Synchronization (`server.py`)**:
   Whenever `python3 backend/server.py` is started:
   - It automatically detects your current Wi-Fi IP and network state.
   - If a new Cloudflare tunnel is created, it automatically updates both `tunnel_url.txt` and `mobile/lib/app/configuration/app_config.dart`.
