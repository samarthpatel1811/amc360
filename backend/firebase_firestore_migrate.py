#!/usr/bin/env python3
"""
AMC360 - Cloud Firestore Live Database Migrator
Uploads all collections from firestore_export.json directly to Google Cloud Firestore in Firebase Console.

Requirements:
    pip install firebase-admin

Usage:
    python3 firebase_firestore_migrate.py [path/to/serviceAccountKey.json]
"""

import os
import sys
import json
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EXPORT_FILE = os.path.join(SCRIPT_DIR, "database", "firestore_export.json")

def print_banner():
    print("=" * 65)
    print("   AMC360 — Cloud Firestore Live Database Migrator")
    print("=" * 65)
    print("   Target Account: samarthpanara12345@gmail.com")
    print("   Platform:       Google Firebase / Cloud Firestore")
    print("=" * 65)

def main():
    print_banner()

    # Parse arguments
    parser = argparse.ArgumentParser(description="Upload AMC360 database to Firebase Firestore.")
    parser.add_argument(
        "service_account",
        nargs="?",
        default=None,
        help="Path to Firebase Service Account JSON key"
    )
    args = parser.parse_args()

    # Find service account key if not specified
    key_path = args.service_account
    if not key_path:
        # Check standard locations
        candidates = [
            os.path.join(SCRIPT_DIR, "serviceAccountKey.json"),
            os.path.join(SCRIPT_DIR, "firebase-credentials.json"),
            os.path.join(os.path.dirname(SCRIPT_DIR), "serviceAccountKey.json"),
            os.path.expanduser("~/Downloads/serviceAccountKey.json"),
        ]
        for c in candidates:
            if os.path.exists(c):
                key_path = c
                break

    if not key_path or not os.path.exists(key_path):
        print("\n[!] Firebase Service Account Key JSON not found.")
        print("\nTo upload your database directly to Firestore in Firebase Console:")
        print("  1. Open Firebase Console: https://console.firebase.google.com")
        print("  2. Select/create your project with samarthpanara12345@gmail.com")
        print("  3. Go to Project Settings (gear icon) -> Service accounts")
        print("  4. Click 'Generate new private key' (downloads a JSON file)")
        print(f"  5. Run: python3 {os.path.basename(__file__)} path/to/downloaded-key.json\n")
        print("-----------------------------------------------------------------")
        print("ℹ️  Note: You can also use the 1-click Instant Web Import into")
        print("   Firebase Realtime Database using:")
        print(f"   {os.path.join(SCRIPT_DIR, 'database', 'firebase_realtime_database.json')}")
        print("   In Firebase Console -> Realtime Database -> (⋮) -> 'Import JSON'")
        print("-----------------------------------------------------------------")
        sys.exit(1)

    # Check if firebase_admin is installed
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("\n[!] 'firebase-admin' Python package is not installed.")
        print("Please install it by running:")
        print("    pip install firebase-admin")
        print("or:")
        print("    pip3 install firebase-admin\n")
        sys.exit(1)

    if not os.path.exists(EXPORT_FILE):
        print(f"[!] Export file not found at: {EXPORT_FILE}")
        print("Please run python3 export_to_firebase.py first.")
        sys.exit(1)

    print(f"\n[*] Authenticating with service account: {key_path}...")
    try:
        cred = credentials.Certificate(key_path)
        app = firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("[✓] Connected to Firebase Project successfully!\n")
    except Exception as e:
        print(f"[!] Failed to authenticate with Firebase: {e}")
        sys.exit(1)

    with open(EXPORT_FILE, "r", encoding="utf-8") as f:
        export_data = json.load(f)

    collections = export_data.get("collections", {})
    total_docs = 0

    print(f"[*] Uploading {len(collections)} collections to Cloud Firestore...")
    print(f"{'Collection':<35} | {'Status':<15}")
    print("-" * 52)

    for coll_name, docs in collections.items():
        if not docs:
            print(f"  {coll_name:<33} | (empty, skipped)")
            continue

        # Batch writes (Firestore allows up to 500 operations per batch)
        batch_size = 400
        for i in range(0, len(docs), batch_size):
            batch = db.batch()
            chunk = docs[i:i + batch_size]
            for doc in chunk:
                doc_id = str(doc["id"])
                doc_ref = db.collection(coll_name).document(doc_id)
                batch.set(doc_ref, doc["data"])
            batch.commit()

        total_docs += len(docs)
        print(f"  {coll_name:<33} | ✓ {len(docs)} docs")

    print("-" * 52)
    print(f"[✓] Migration complete! Successfully transferred {total_docs} documents")
    print("    to Cloud Firestore in your Firebase Console.")
    print("=" * 65)

if __name__ == "__main__":
    main()
