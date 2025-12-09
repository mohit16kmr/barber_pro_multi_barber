# BarberPro Complete Project — Start from ZERO Prompt

**For someone with NOTHING installed. Complete step-by-step to build entire project from scratch.**

---

## Your Current Status: ZERO

- ❌ No Node.js installed
- ❌ No Flutter installed
- ❌ No Docker installed
- ❌ No Firebase project
- ❌ No Google Cloud project
- ❌ No project folder created
- ❌ Nothing

**End Result After This Prompt:** Fully working BarberPro app running locally + deployed to cloud.

---

## STEP 1: Install Everything on Your Computer (30-40 min)

### 1.1 Install Node.js & npm

**Windows:**

1. Go to https://nodejs.org/
2. Click **"LTS"** (Long Term Support) version
3. Download the `.msi` file
4. Run the installer, click **Next** multiple times, accept defaults
5. At the end, **DO NOT** uncheck "Add to PATH"
6. Click **Finish**
7. Restart your computer or restart PowerShell

**Verify installation:**
```powershell
node --version
npm --version
```

**Expected output:**
```
v18.18.0
9.8.1
```

If you see version numbers like above, ✅ Node.js is installed.

### 1.2 Install Flutter & Dart

**Windows:**

1. Go to https://flutter.dev/docs/get-started/install/windows
2. Download the **Flutter SDK** (the `.zip` file)
3. Extract it to a folder (example: `C:\flutter`)
4. Open PowerShell as **Administrator**
5. Run:
```powershell
$env:Path += ";C:\flutter\bin"
```
6. Close and reopen PowerShell
7. Run:
```powershell
flutter doctor
```

This will take 2-3 minutes and install Dart, emulator tools, etc.

**Wait for it to finish, then check:**
```powershell
flutter --version
```

**Expected output:**
```
Flutter 3.16.0
```

### 1.3 Install Docker Desktop

**Windows:**

1. Go to https://www.docker.com/products/docker-desktop
2. Download **Docker Desktop for Windows**
3. Run the installer, click **Next**, accept defaults
4. At the end, it will ask to restart — **click Restart**
5. After restart, Docker will start automatically
6. Open PowerShell and run:
```powershell
docker --version
docker-compose --version
```

**Expected output:**
```
Docker version 24.0.0
Docker Compose version 2.20.0
```

### 1.4 Install Git

**Windows:**

1. Go to https://git-scm.com/download/win
2. Download the `.exe` file
3. Run installer, click **Next** multiple times, accept defaults
4. Click **Finish**
5. Restart PowerShell
6. Verify:
```powershell
git --version
```

**Expected output:**
```
git version 2.40.0
```

### 1.5 Install Google Cloud SDK (Optional for Cloud Deploy)

**Windows:**

1. Go to https://cloud.google.com/sdk/docs/install-sdk
2. Download **Google Cloud SDK for Windows**
3. Run installer, click **Next**, accept defaults
4. Restart PowerShell
5. Verify:
```powershell
gcloud --version
```

---

## STEP 2: Create Firebase Project (15 min)

### 2.1 Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **Create a project**
3. Enter name: `barber-pro-dev`
4. Click **Continue**
5. Uncheck "Enable Google Analytics" (not needed for now)
6. Click **Create project**
7. Wait 1-2 minutes for it to be created
8. You should see: "Your Firebase project is ready"

### 2.2 Create Service Account for Backend

1. In Firebase Console, go to **Settings** (gear icon, top right)
2. Click **Service Accounts**
3. Click **Generate New Private Key**
4. A JSON file will download — **SAVE IT CAREFULLY**
5. Rename it to `firebase-credentials.json`
6. **Keep this file secure — never commit to Git**

### 2.3 Enable Required Firebase Services

In Firebase Console:

1. Click **Build** → **Firestore Database**
   - Click **Create database**
   - Select **Start in test mode**
   - Choose region: **us-central1**
   - Click **Create**

2. Click **Build** → **Authentication**
   - Click **Get started**
   - Enable **Email/Password** provider

3. Click **Engage** → **Cloud Messaging**
   - You'll see a server key here (save for later)

4. Click **Build** → **Storage**
   - Click **Create** and choose region

---

## STEP 3: Create Project Folders (10 min)

### 3.1 Create Main Project Directory

```powershell
# Navigate to a safe location (example: Documents)
cd C:\Users\YourUsername\Documents

# Create project folder
mkdir barberpro_project
cd barberpro_project

# Initialize Git
git init
```

### 3.2 Create Subfolder Structure

```powershell
# Create frontend folder (Flutter)
mkdir frontend

# Create backend folder (NestJS)
mkdir backend

# Create GitHub workflows folder (for CI/CD)
mkdir .github
mkdir .github\workflows
```

### 3.3 Create .gitignore File

Create a file called `.gitignore` in `C:\Users\YourUsername\Documents\barberpro_project\`:

**Copy and paste this content:**

```
# Environment
.env.local
.env.*.local
firebase-credentials.json
*.key

# Node
node_modules/
dist/
npm-debug.log*
package-lock.json

# Flutter
build/
.dart_tool/
.flutter-plugins-dependencies
pubspec.lock
*.apk
*.ipa

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Docker
.firebase/
```

---

## STEP 4: Setup Backend (NestJS) (30 min)

### 4.1 Create NestJS Project

```powershell
# Navigate to backend folder
cd C:\Users\YourUsername\Documents\barberpro_project\backend

# Install NestJS CLI globally
npm install -g @nestjs/cli

# Create new NestJS project
nest new . --package-manager npm

# Choose "npm" when asked for package manager
```

This will take 2-3 minutes. After it's done:

```powershell
# Verify it worked
npm --version
```

### 4.2 Install Additional Dependencies

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\backend

# Install all required packages
npm install @nestjs/common @nestjs/core @nestjs/platform-express @nestjs/jwt @nestjs/passport passport passport-jwt firebase-admin redis socket.io class-validator class-transformer dotenv helmet uuid

# Install dev dependencies
npm install -D @types/express @types/node typescript @nestjs/swagger swagger-ui-express
```

This takes 2-3 minutes.

### 4.3 Create .env.local File

Create file `backend/.env.local`:

```powershell
cd backend

# Create empty .env.local file
New-Item -Path . -Name ".env.local" -ItemType File
```

Now open this file in any text editor and copy-paste:

```dotenv
NODE_ENV=development
PORT=3000
API_VERSION=v1

JWT_SECRET=your-super-secret-key-minimum-32-characters-long-12345
JWT_EXPIRATION=3600
JWT_REFRESH_SECRET=your-super-secret-refresh-key-minimum-32-chars-12345
JWT_REFRESH_EXPIRATION=2592000

FIREBASE_PROJECT_ID=barber-pro-dev
FIREBASE_PRIVATE_KEY_ID=key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQE... (replace with your actual key)\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@barber-pro-dev.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=123456789

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

WEBSOCKET_CORS_ORIGIN=*
FCM_SERVER_KEY=your-fcm-key-here
SMS_PROVIDER=twilio

API_BASE_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080

LOG_LEVEL=debug
```

**How to get Firebase credentials:**

1. Open `firebase-credentials.json` that you downloaded earlier
2. Find these fields:
   - `private_key` → copy into `FIREBASE_PRIVATE_KEY`
   - `client_email` → copy into `FIREBASE_CLIENT_EMAIL`
   - `project_id` → copy into `FIREBASE_PROJECT_ID`
3. Keep the `\n` characters in the private key — they're important

### 4.4 Create docker-compose.yml for Services

Create file `backend/docker-compose.yml`:

**Copy-paste:**

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: barber-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  firestore-emulator:
    image: odijf/google-cloud-firestore-emulator:latest
    container_name: barber-firestore-emulator
    ports:
      - "8080:8080"
    environment:
      - FIRESTORE_EMULATOR_HOST=0.0.0.0:8080
    volumes:
      - firestore_data:/data

volumes:
  redis_data:
  firestore_data:
```

### 4.5 Start Backend Services

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\backend

# Start Docker containers (Redis + Firestore)
docker-compose up -d

# Check if they're running
docker ps

# Should show two containers
```

### 4.6 Copy Backend Module Files

**Since you're starting from zero, copy the Notifications module files from `barberbooking_project_with_backend` folder:**

From: `d:\FlutterProjects\bookyourbarber\barberbooking_project_with_backend\src\modules\`

Copy to: `C:\Users\YourUsername\Documents\barberpro_project\backend\src\modules\`

The modules you need:
- `notifications/` (with service, controller, DTO, module)
- `auth/` (skeleton)
- `bookings/` (skeleton)
- `queue/` (skeleton)

Also copy:
- `src/common/firebase/`
- `src/common/redis/`
- `src/common/logger/`
- `src/common/websocket/`

And update:
- `src/app.module.ts` (import all modules)
- `src/main.ts` (Swagger setup)

### 4.7 Start Backend

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\backend

# Install node modules
npm ci

# Start in development mode
npm run start:dev

# You should see:
# 🚀 Application is running on: http://localhost:3000
# 📚 Swagger documentation: http://localhost:3000/docs
```

**Test it:**
Open in browser: `http://localhost:3000/docs`

Should see API documentation page.

---

## STEP 5: Setup Frontend (Flutter) (20 min)

### 5.1 Copy Existing Flutter Project

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\frontend

# Copy Flutter app files from existing project
# From: d:\FlutterProjects\bookyourbarber\newbarberproject
# Copy to: C:\Users\YourUsername\Documents\barberpro_project\frontend

# After copying, you should have:
# - lib/
# - pubspec.yaml
# - android/
# - ios/
# - test/
# - etc.
```

### 5.2 Clean and Get Dependencies

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\frontend

# Clean build
flutter clean

# Get dependencies
flutter pub get

# This takes 2-3 minutes
```

### 5.3 Update API Configuration

Create file `frontend/lib/config/app_config.dart`:

```dart
class AppConfig {
  // Local development
  static const String devApiUrl = 'http://localhost:3000/api/v1';
  
  // Production (update after Cloud Run deployment)
  static const String prodApiUrl = 'https://barberpro-backend-xxxxx.a.run.app/api/v1';

  static String getApiUrl({bool isProd = false}) {
    return isProd ? prodApiUrl : devApiUrl;
  }

  static String getWebSocketUrl({bool isProd = false}) {
    final baseUrl = getApiUrl(isProd: isProd);
    return baseUrl.replaceFirst('/api/v1', '');
  }
}
```

### 5.4 Update API Service

Ensure `frontend/lib/services/api_service.dart` calls backend API:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.getApiUrl();

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getQueue(String barberId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/queue/$barberId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed');
  }
}
```

### 5.5 Run Flutter App

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project\frontend

# Check available devices
flutter devices

# Run on Chrome (easiest for testing)
flutter run -t lib/main_barber.dart -d chrome

# Or Android emulator
flutter run -t lib/main_barber.dart -d emulator-5554
```

Should see app running in browser or emulator.

---

## STEP 6: Test Everything Together (10 min)

### 6.1 Verify Backend is Running

**Terminal 1:**
```powershell
cd backend
npm run start:dev
# Should show: 🚀 Application is running on: http://localhost:3000
```

### 6.2 Verify Frontend is Running

**Terminal 2:**
```powershell
cd frontend
flutter run -t lib/main_barber.dart -d chrome
# Should show app in browser
```

### 6.3 Test API Call from Frontend

In the Flutter app:
1. Try to create a booking (or perform any action that calls backend)
2. Check **Terminal 1** (backend) for logs showing the API call
3. Should see something like: `[LOG] Creating booking...`

If you see logs, ✅ **Full stack is working!**

### 6.4 Test Docker Services

```powershell
# Terminal 3
# Check Redis
docker exec barber-redis redis-cli PING
# Should return: PONG

# Check Firestore Emulator
# Open browser: http://localhost:8080
# Should show emulator UI
```

---

## STEP 7: Build Docker Image (15 min)

### 7.1 Create Dockerfile for Backend

Create file `backend/Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

EXPOSE 3000

# Start
CMD ["npm", "run", "start:prod"]
```

### 7.2 Build Docker Image

```powershell
cd backend

# Build image
docker build -t barberpro-backend:latest .

# This takes 2-3 minutes
# You should see: Successfully tagged barberpro-backend:latest
```

### 7.3 Test Docker Image Locally

```powershell
# Run container
docker run -p 3000:3000 `
  -e NODE_ENV=production `
  -e JWT_SECRET=your-secret-key `
  -e FIREBASE_PROJECT_ID=barber-pro-dev `
  barberpro-backend:latest

# Should show: 🚀 Application is running on: http://localhost:3000
```

---

## STEP 8: Deploy to Google Cloud Run (20 min)

### 8.1 Setup Google Cloud Project

```powershell
# Authenticate
gcloud auth login
# A browser window will open — sign in with your Google account

# Set project
gcloud config set project barber-pro-dev

# Enable APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 8.2 Create Service Account

```powershell
# Create service account
gcloud iam service-accounts create barber-backend-sa

# Grant permissions
gcloud projects add-iam-policy-binding barber-pro-dev `
  --member=serviceAccount:barber-backend-sa@barber-pro-dev.iam.gserviceaccount.com `
  --role=roles/run.admin
```

### 8.3 Push Docker Image to Google Container Registry

```powershell
cd backend

# Configure Docker auth
gcloud auth configure-docker

# Tag image
docker tag barberpro-backend:latest gcr.io/barber-pro-dev/barberpro-backend:latest

# Push to registry
docker push gcr.io/barber-pro-dev/barberpro-backend:latest

# This takes 5-10 minutes
```

### 8.4 Deploy to Cloud Run

```powershell
# Deploy
gcloud run deploy barberpro-backend `
  --image gcr.io/barber-pro-dev/barberpro-backend:latest `
  --region us-central1 `
  --platform managed `
  --service-account barber-backend-sa@barber-pro-dev.iam.gserviceaccount.com `
  --set-env-vars "NODE_ENV=production,JWT_SECRET=your-secret-key,FIREBASE_PROJECT_ID=barber-pro-dev" `
  --memory 512Mi `
  --cpu 1 `
  --allow-unauthenticated

# After deployment, you'll see:
# Service URL: https://barberpro-backend-xxxxxx.a.run.app
```

**Copy this URL — it's your production backend!**

### 8.5 Update Flutter Config for Production

Edit `frontend/lib/config/app_config.dart`:

```dart
// Replace with your actual Cloud Run URL
static const String prodApiUrl = 'https://barberpro-backend-xxxxxx.a.run.app/api/v1';
```

---

## STEP 9: Build & Deploy Flutter App (25 min)

### 9.1 Build Android APK (for testing)

```powershell
cd frontend

# Build APK (debug)
flutter build apk -t lib/main_barber.dart

# APK will be at: build/app/outputs/flutter-apk/app.apk
```

### 9.2 Build for Play Store (Android)

```powershell
cd frontend

# Build App Bundle (required for Play Store)
flutter build appbundle -t lib/main_barber.dart --release

# Bundle will be at: build/app/outputs/bundle/release/app.aab
```

### 9.3 Build for App Store (iOS)

```powershell
cd frontend

# Build iOS app
flutter build ios -t lib/main_barber.dart --release

# This requires macOS and Xcode
```

### 9.4 Build for Web

```powershell
cd frontend

# Build web version
flutter build web -t lib/main_barber.dart --release

# Web files will be at: build/web/
# Upload to any hosting (Firebase Hosting, Netlify, Vercel, etc.)
```

---

## STEP 10: Final Checklist

Before considering the project DONE:

- [ ] All software installed (Node, Flutter, Docker, Git, GCloud)
- [ ] Firebase project created
- [ ] Firebase credentials (`firebase-credentials.json`) saved
- [ ] Backend folder created with NestJS
- [ ] Backend modules copied (notifications, auth, bookings, queue)
- [ ] `backend/.env.local` filled with Firebase credentials
- [ ] Docker services running (`redis` + `firestore-emulator`)
- [ ] Backend running locally (`npm run start:dev`)
- [ ] Swagger docs visible at `http://localhost:3000/docs`
- [ ] Frontend copied to `frontend/` folder
- [ ] `flutter pub get` completed
- [ ] Frontend running locally (`flutter run`)
- [ ] Backend and frontend talking to each other (test API call)
- [ ] Docker image built and running locally
- [ ] Docker image pushed to Google Container Registry
- [ ] Backend deployed to Cloud Run
- [ ] Cloud Run URL is accessible
- [ ] Flutter config updated with Cloud Run URL
- [ ] Android APK/AAB built
- [ ] iOS app built (or skipped if Windows-only)
- [ ] Web version built
- [ ] All tests passing

---

## Summary of URLs

After everything is done, you'll have:

| Service | URL |
|---------|-----|
| Local Backend | `http://localhost:3000` |
| Local Swagger Docs | `http://localhost:3000/docs` |
| Local Firestore Emulator | `http://localhost:8080` |
| Production Backend (Cloud Run) | `https://barberpro-backend-xxxxx.a.run.app` |
| Production Swagger Docs | `https://barberpro-backend-xxxxx.a.run.app/docs` |

---

## Quick Command Reference

```powershell
# BACKEND
cd backend
docker-compose up -d          # Start services
npm run start:dev             # Run backend
npm run test                  # Test backend
docker build -t barberpro-backend:latest .  # Build image
docker push gcr.io/barber-pro-dev/barberpro-backend:latest  # Push to GCR

# FRONTEND
cd frontend
flutter clean                 # Clean
flutter pub get              # Get dependencies
flutter run -t lib/main_barber.dart -d chrome  # Run
flutter test                 # Test
flutter build apk            # Build APK

# GOOGLE CLOUD
gcloud auth login            # Authenticate
gcloud config set project barber-pro-dev  # Set project
gcloud run logs barberpro-backend  # View logs
```

---

## If Something Goes Wrong

| Problem | Solution |
|---------|----------|
| "Node is not installed" | Restart PowerShell after installing Node.js |
| "Flutter not found" | Add `C:\flutter\bin` to PATH or restart |
| "Port 3000 in use" | Find what's using it: `netstat -ano \| findstr :3000` then `taskkill /pid <PID> /f` |
| "Docker not running" | Open Docker Desktop |
| "Firebase credentials error" | Copy-paste the actual values from your `firebase-credentials.json` file |
| "Can't connect to backend from Flutter" | Make sure backend is running on `http://localhost:3000` |
| "Cloud Run deployment fails" | Check logs: `gcloud run logs barberpro-backend --limit 50` |

---

## You're Done! 🎉

**Time to complete:** ~3-4 hours first time  
**After first time:** Changes take 5-10 minutes

You now have:
- ✅ Fully working BarberPro app running locally
- ✅ Backend running on your computer
- ✅ Frontend (Flutter) running on your computer
- ✅ Real-time database (Firestore)
- ✅ Cache layer (Redis)
- ✅ Backend deployed to Google Cloud Run
- ✅ Ready to add more features

**Next steps after this:**
- Add more features (payments, reviews, etc.)
- Add tests for everything
- Setup GitHub Actions CI/CD
- Deploy Flutter app to Play Store / App Store
- Add monitoring and logging
- Scale with more resources

---

**Document:** BarberPro Start from ZERO Prompt  
**Version:** 1.0  
**Date:** December 2025  
**Status:** Complete & Ready to Use
