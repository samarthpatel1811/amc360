#!/usr/bin/env node
/**
 * AMC360 - Cloud Firestore Live Database Migrator
 * Automatically uploads all collections from firestore_export.json directly to Google Cloud Firestore.
 *
 * Target Account: samarthpanara12345@gmail.com
 * Project: Service Management System
 */

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const SCRIPT_DIR = __dirname;
const EXPORT_FILE = path.join(SCRIPT_DIR, 'database', 'firestore_export.json');
const DOWNLOADS_DIR = path.join(process.env.HOME || '/Users/apple', 'Downloads');

console.log('='.repeat(65));
console.log('   AMC360 — Cloud Firestore Live Database Migrator');
console.log('='.repeat(65));
console.log('   Target Account: samarthpanara12345@gmail.com');
console.log('   Platform:       Google Firebase / Cloud Firestore');
console.log('='.repeat(65));

// 1. Locate service account key JSON
let keyPath = process.argv[2];

if (!keyPath) {
  // Check candidates in project and Downloads
  const candidates = [
    path.join(SCRIPT_DIR, 'serviceAccountKey.json'),
    path.join(SCRIPT_DIR, 'firebase-credentials.json'),
    path.join(path.dirname(SCRIPT_DIR), 'serviceAccountKey.json'),
  ];

  // Scan Downloads for service account JSON
  if (fs.existsSync(DOWNLOADS_DIR)) {
    const files = fs.readdirSync(DOWNLOADS_DIR);
    for (const file of files) {
      if (file.endsWith('.json') && (file.includes('serviceAccount') || file.includes('firebase-adminsdk') || file.includes('service-management-system') || file.includes('service-management-syste'))) {
        candidates.push(path.join(DOWNLOADS_DIR, file));
      }
    }
  }

  for (const c of candidates) {
    if (fs.existsSync(c)) {
      try {
        const content = JSON.parse(fs.readFileSync(c, 'utf8'));
        if (content.type === 'service_account' && content.project_id) {
          keyPath = c;
          break;
        }
      } catch (_) {}
    }
  }
}

if (!keyPath || !fs.existsSync(keyPath)) {
  console.log('\n[!] Waiting for your Firebase Service Account Key JSON.');
  console.log('\nSteps to get your key in Firebase Console:');
  console.log('  1. In your Firebase browser window, click the Gear Icon (⚙️) next to Project Overview -> "Project settings"');
  console.log('  2. Click the "Service accounts" tab');
  console.log('  3. Click "Generate new private key" -> "Generate key"');
  console.log('  4. Once downloaded, simply run:');
  console.log('     node backend/firebase_firestore_migrate.cjs\n');
  console.log('='.repeat(65));
  process.exit(1);
}

// 2. Initialize Firebase Admin
console.log(`\n[*] Found Service Account Key: ${keyPath}`);
const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
console.log(`[*] Connecting to Firebase Project: ${serviceAccount.project_id}...`);

let app;
try {
  app = initializeApp({
    credential: cert(serviceAccount),
  });
  console.log('[✓] Successfully authenticated with Firebase Project!\n');
} catch (err) {
  console.error(`[!] Authentication error: ${err.message}`);
  process.exit(1);
}

const db = getFirestore(app);

// 3. Read export file
if (!fs.existsSync(EXPORT_FILE)) {
  console.error(`[!] Export file not found at: ${EXPORT_FILE}`);
  process.exit(1);
}

const exportData = JSON.parse(fs.readFileSync(EXPORT_FILE, 'utf8'));
const collections = exportData.collections || {};

async function upload() {
  const collNames = Object.keys(collections);
  console.log(`[*] Uploading ${collNames.length} collections to Cloud Firestore...`);
  console.log(`${'Collection'.padEnd(35)} | ${'Status'.padEnd(15)}`);
  console.log('-'.repeat(52));

  let totalDocs = 0;

  for (const collName of collNames) {
    const docs = collections[collName];
    if (!docs || docs.length === 0) {
      console.log(`  ${collName.padEnd(33)} | (empty, skipped)`);
      continue;
    }

    // Firestore allows up to 500 writes per batch
    const batchSize = 400;
    for (let i = 0; i < docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = docs.slice(i, i + batchSize);
      for (const doc of chunk) {
        const docRef = db.collection(collName).doc(String(doc.id));
        batch.set(docRef, doc.data);
      }
      await batch.commit();
    }

    totalDocs += docs.length;
    console.log(`  ${collName.padEnd(33)} | ✓ ${docs.length} docs`);
  }

  console.log('-'.repeat(52));
  console.log(`[✓] ALL DONE! Successfully transferred ${totalDocs} documents across ${collNames.length} collections`);
  console.log(`    into Cloud Firestore for project "${serviceAccount.project_id}"!`);
  console.log('='.repeat(65));
}

upload().catch((err) => {
  console.error('[!] Migration failed:', err);
  process.exit(1);
});
