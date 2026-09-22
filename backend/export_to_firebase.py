#!/usr/bin/env python3
"""
AMC360 - Complete SQLite to Firebase Exporter
Exports all 34 tables from database.sqlite into:
1. Firebase Realtime Database JSON (ready for 1-click web console import)
2. Cloud Firestore Collections JSON (ready for batch Firestore ingestion)
3. Firebase Auth Users JSON (ready for Firebase Authentication import)

Target Admin Account: samarthpanara12345@gmail.com
"""

import os
import sys
import json
import sqlite3
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "database", "database.sqlite")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "database")

BOOLEAN_FIELDS = {
    "tax_enabled", "require_customer_signature", "require_gps", "require_service_photos",
    "is_read", "is_completed", "is_required", "email_verified_at"
}

FLOAT_FIELDS = {
    "total_amount", "subtotal", "tax_amount", "paid_amount", "balance_amount",
    "unit_cost", "selling_price", "unit_price", "total_price", "stock_quantity",
    "minimum_stock", "default_tax_rate", "tax_rate", "latitude", "longitude",
    "contract_value", "amount", "cost"
}

JSON_FIELDS = {
    "skills", "metadata", "old_values", "new_values", "settings", "checklist_data",
    "custom_fields", "options"
}

def clean_value(col_name, val):
    if val is None:
        return None
    if col_name in BOOLEAN_FIELDS:
        return bool(val)
    if col_name in FLOAT_FIELDS:
        try:
            return float(val)
        except (ValueError, TypeError):
            return val
    if col_name in JSON_FIELDS and isinstance(val, str):
        val_str = val.strip()
        if (val_str.startswith("{") and val_str.endswith("}")) or (val_str.startswith("[") and val_str.endswith("]")):
            try:
                return json.loads(val_str)
            except Exception:
                return val
    return val

def export():
    if not os.path.exists(DB_PATH):
        print(f"[!] Database file not found at: {DB_PATH}")
        sys.exit(1)

    print("=" * 65)
    print("   AMC360 — SQLite to Firebase Console Export Suite")
    print("=" * 65)
    print(f"   Database:   {DB_PATH}")
    print(f"   Output Dir: {OUTPUT_DIR}")
    print(f"   Admin:      samarthpanara12345@gmail.com")
    print("-" * 65)

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
    tables = [row[0] for row in cursor.fetchall()]

    from datetime import timezone
    realtime_db = {}
    firestore_db = {"metadata": {"exported_at": datetime.now(timezone.utc).isoformat(), "total_tables": len(tables)}, "collections": {}}
    auth_users = []

    print(f"[*] Found {len(tables)} tables. Extracting...")
    print(f"{'Table Name':<35} | {'Rows':<8}")
    print("-" * 46)

    total_records = 0

    for table in tables:
        cursor.execute(f'SELECT * FROM "{table}"')
        rows = cursor.fetchall()
        row_count = len(rows)
        total_records += row_count
        print(f"  {table:<33} | {row_count:<8}")

        realtime_table = {}
        firestore_docs = []

        for row in rows:
            record = {}
            for key in row.keys():
                record[key] = clean_value(key, row[key])

            doc_id = str(record.get("id", len(firestore_docs) + 1))
            realtime_table[doc_id] = record
            firestore_docs.append({
                "id": doc_id,
                "data": record
            })

            # Handle auth users
            if table == "users":
                auth_users.append({
                    "localId": str(record.get("id")),
                    "email": record.get("email"),
                    "displayName": record.get("name"),
                    "phoneNumber": record.get("phone"),
                    "emailVerified": bool(record.get("email_verified_at")),
                    "customAttributes": json.dumps({
                        "role": record.get("role", "admin"),
                        "company_id": record.get("company_id")
                    }),
                    "passwordHash": record.get("password")
                })

        realtime_db[table] = realtime_table
        firestore_db["collections"][table] = firestore_docs

    conn.close()

    # 1. Save Firebase Realtime Database JSON
    rtdb_file = os.path.join(OUTPUT_DIR, "firebase_realtime_database.json")
    with open(rtdb_file, "w", encoding="utf-8") as f:
        json.dump(realtime_db, f, indent=2, ensure_ascii=False)

    # 2. Save Cloud Firestore Collections JSON
    firestore_file = os.path.join(OUTPUT_DIR, "firestore_export.json")
    with open(firestore_file, "w", encoding="utf-8") as f:
        json.dump(firestore_db, f, indent=2, ensure_ascii=False)

    # 3. Save Firebase Auth Users JSON
    auth_file = os.path.join(OUTPUT_DIR, "firebase_auth_users.json")
    with open(auth_file, "w", encoding="utf-8") as f:
        json.dump({"users": auth_users}, f, indent=2, ensure_ascii=False)

    print("-" * 65)
    print(f"[✓] Exported {total_records} total records across {len(tables)} tables successfully!")
    print("\n   Generated Firebase Console Import Files:")
    print(f"   1. Realtime DB:  {rtdb_file} ({os.path.getsize(rtdb_file) / 1024:.1f} KB)")
    print(f"   2. Firestore:    {firestore_file} ({os.path.getsize(firestore_file) / 1024:.1f} KB)")
    print(f"   3. Auth Users:   {auth_file} ({os.path.getsize(auth_file) / 1024:.1f} KB)")
    print("=" * 65)

if __name__ == "__main__":
    export()
