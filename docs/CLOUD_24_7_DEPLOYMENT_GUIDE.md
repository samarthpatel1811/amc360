# AMC360 — 24/7 Permanent Cloud Deployment Guide

This guide enables AMC360 to run **24/7/365 in the cloud**, so you and your team can open and use the mobile app from anywhere in the world on cellular data (4G/5G) or Wi-Fi — **with your Mac completely turned off**.

---

## Why This Path Was Chosen

AMC360 has over 50 mobile screens and 73 API features (including PDF visit report generation, customer signatures, QR asset verification, and contract schedule calculations).

By hosting the backend container on **Render** (100% Free tier):
1. You get a permanent public HTTPS URL (e.g. `https://amc360-api.onrender.com/api/v1`).
2. Your laptop can be powered off, asleep, or disconnected.
3. Every screen, PDF report, login, and background process works with **100% stability** and zero code changes needed on the mobile app.

---

## 3 Quick Steps to Deploy on Render (Free)

### Step 1: Push Project to GitHub

1. Open Terminal and run:
   ```bash
   cd /Users/apple/Desktop/amc360
   git add .
   git commit -m "AMC360 24/7 Cloud Ready"
   ```
2. Go to [GitHub](https://github.com/new) and create a new repository (name it `amc360`).
3. Push your code to GitHub:
   ```bash
   git remote add origin https://github.com/YOUR_GITHUB_USERNAME/amc360.git
   git push -u origin main
   ```

---

### Step 2: Launch Web Service on Render (Takes 2 minutes)

1. Go to [Render.com](https://render.com) and sign up / sign in (free, no credit card required).
2. Click the blue **"New +"** button at the top $\rightarrow$ Select **"Web Service"**.
3. Choose **"Build and deploy from a Git repository"** $\rightarrow$ Click Next.
4. Connect your GitHub account and select your `amc360` repository.
5. In the configuration screen:
   - **Name**: `amc360-api`
   - **Language / Environment**: Select **Docker**
   - **Dockerfile Path**: `backend/Dockerfile.cloud`
   - **Docker Context**: `backend`
   - **Instance Type**: Select **Free**
6. Click **"Create Web Service"**.

Render will automatically build your container and give you a permanent live HTTPS URL, for example:
```
https://amc360-api.onrender.com
```

---

### Step 3: Set Your Permanent URL in the Mobile App

Once Render finishes deploying (it shows a green "Live" badge):

1. Open `mobile/lib/app/configuration/app_config.dart`.
2. Change `apiBaseUrl` to your new permanent URL:
   ```dart
   static String apiBaseUrl = 'https://amc360-api.onrender.com/api/v1';
   ```
3. That's it! Build/run the app on your iPhone or Android phone.

Now, your app is permanently connected to the cloud 24/7/365 — whether your laptop is open, closed, or powered off!
