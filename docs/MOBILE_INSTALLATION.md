# AMC360 — Mobile Application Installation & Build Guide

This guide details the installation, configuration, testing, and production build steps for the **AMC360** Flutter mobile application on Android and iOS.

---

## 1. Prerequisites

* **Flutter SDK:** Version 3.22.0 or higher
* **Dart SDK:** Version 3.4.0 or higher
* **Android Studio:** Android SDK API 34+ (for Android compilation)
* **Xcode:** Version 15+ (for iOS compilation on macOS)

Verify your development environment:
```bash
flutter doctor
```

---

## 2. Step-by-Step Setup

### Step 1: Navigate to Mobile Directory
```bash
cd mobile
```

### Step 2: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Configure API Connection
Open `lib/app/configuration/app_config.dart` and configure your backend endpoint:
```dart
class AppConfig {
  static const String appName = 'AMC360';
  static const String appTagline = 'AMC, Asset & Service Management';
  static const String appVersion = 'v1.0.0';

  // Point to your live backend domain or local network IP
  static String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';
}
```

> **Note for Android Emulators & Real Devices:**
> * Android Emulator: Use `http://10.0.2.2:8000/api/v1`
> * Physical Mobile Device: Use your machine's local Wi-Fi IP (e.g. `http://192.168.1.15:8000/api/v1`)

---

## 3. Platform Configuration & Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
The following permissions are required for barcode scanning, before/after photo uploads, and location stamping:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

### iOS (`ios/Runner/Info.plist`)
Add user-facing privacy descriptions:
```xml
<key>NSCameraUsageDescription</key>
<string>AMC360 requires camera access to scan equipment QR codes and capture maintenance proof photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>AMC360 requires photo library access to upload service report attachments.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>AMC360 records your GPS coordinates when starting and completing field service visits.</string>
```

---

## 4. Running the Application

### Debug Mode
```bash
flutter run
```

### Profile Mode (Performance Tuning)
```bash
flutter run --profile
```

---

## 5. Building Release Artifacts

### Android APK (Direct Distribution / Sideload)
```bash
flutter build apk --release --split-per-abi
```
Generated APKs will be located at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Android App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
Generated AAB will be located at:
`build/app/outputs/bundle/release/app-release.aab`

### iOS IPA (Apple App Store / TestFlight)
```bash
flutter build ipa --release
```
Generated archive will be located at:
`build/ios/archive/Runner.xcarchive`
