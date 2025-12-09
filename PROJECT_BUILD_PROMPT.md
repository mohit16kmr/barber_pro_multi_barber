# BarberPro Project Build Prompt & Instructions

**Complete step-by-step prompt to build the entire BarberPro project from scratch.**

Use this file as a checklist and reference to build the complete system (Frontend + Backend + Deployment).

---

## Quick Start Summary

This project consists of:
- **Frontend**: Flutter app (multi-flavor: barber, customer, admin)
- **Backend**: NestJS REST API + WebSocket
- **Database**: Firestore + Redis
- **Notifications**: FCM + SMS (Twilio stub)
- **Hosting**: Google Cloud Run

**Time to build locally:** ~30-45 minutes  
**Time to deploy:** ~15 minutes (after first local run)

---

## Phase 1: Environment & Machine Setup (15 min)

### 1.1 Install Prerequisites

**On Windows (PowerShell):**

```powershell
# Check if Node.js is installed
node --version  # Should be v18 or higher
npm --version

# If not, install from https://nodejs.org/
# After install, restart PowerShell
```

```powershell
# Check if Flutter is installed
flutter --version  # Should be v3.10 or higher

# If not, install from https://flutter.dev/docs/get-started/install/windows
# After install, add to PATH and restart PowerShell
```

```powershell
# Check Docker
docker --version
docker-compose --version

# If not, install from https://docs.docker.com/get-docker/
```

```powershell
# Optional: Firebase CLI (for emulator management)
npm install -g firebase-tools
firebase --version
```

### 1.2 Verify Installations

```powershell
# Run all together
node --version; npm --version; flutter --version; docker --version; docker-compose --version
```

**Expected output:**
```
v18.x.x
9.x.x
Flutter 3.x.x
Docker 24.x.x
Docker Compose 2.x.x
```

---

## Phase 2: Project Structure Setup (10 min)

### 2.1 Create Main Project Folder

```powershell
# Navigate to your projects directory
cd D:\FlutterProjects\bookyourbarber

# Create new project folder
mkdir barberbooking_complete
cd barberbooking_complete

# Initialize Git
git init
```

### 2.2 Create Folder Structure

```powershell
# Create main folders
mkdir frontend
mkdir backend
mkdir .github
mkdir .github\workflows

# Create root config files
New-Item -Path . -Name ".gitignore" -ItemType File
New-Item -Path . -Name "README.md" -ItemType File
New-Item -Path . -Name "docker-compose.yml" -ItemType File
```

### 2.3 Setup .gitignore

Create `barberbooking_complete/.gitignore`:

```
# Node & npm
node_modules/
dist/
*.js
*.js.map
*.d.ts
npm-debug.log*
package-lock.json
.npm

# Flutter
build/
.dart_tool/
.flutter-plugins-dependencies
*.apk
*.ipa
.packages
pubspec.lock

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Environment
.env.local
.env.*.local
*.key
firebase-debug.log

# OS
.DS_Store
Thumbs.db

# Misc
.firebase/
```

---

## Phase 3: Backend Setup (NestJS) (20 min)

### 3.1 Initialize Backend Project

```powershell
cd D:\FlutterProjects\bookyourbarber\barberbooking_complete\backend

# Option A: Use existing scaffold (recommended)
# Copy contents of barberbooking_project_with_backend or barber-pro-backend into this folder
# Then run:
npm ci

# Option B: Create new NestJS project
npm install -g @nestjs/cli
nest new . --package-manager npm
npm install
```

### 3.2 Install Required Dependencies

```powershell
cd backend

# Core NestJS
npm install @nestjs/common @nestjs/core @nestjs/platform-express @nestjs/platform-ws @nestjs/websockets @nestjs/swagger

# Auth & JWT
npm install @nestjs/jwt @nestjs/passport passport passport-jwt jsonwebtoken

# Firebase
npm install firebase-admin

# Database & Cache
npm install redis

# Real-time
npm install socket.io

# Utilities
npm install class-validator class-transformer dotenv helmet uuid

# Dev dependencies
npm install -D @nestjs/cli @nestjs/testing @types/express @types/node @types/jest @types/passport-jwt typescript jest ts-jest ts-node @typescript-eslint/parser @typescript-eslint/eslint-plugin prettier rimraf
```

### 3.3 Create .env.local for Backend

```powershell
# In backend folder, copy .env.example to .env.local
Copy-Item .env.example .env.local

# Edit .env.local in your editor and fill in values
# Key values needed:
# - FIREBASE_PRIVATE_KEY (from Firebase service account JSON)
# - FIREBASE_CLIENT_EMAIL
# - JWT_SECRET (any strong random string, min 32 chars)
# - JWT_REFRESH_SECRET (another strong random string)
```

**Sample .env.local:**

```dotenv
NODE_ENV=development
PORT=3000
API_VERSION=v1

JWT_SECRET=your-super-secret-key-min-32-characters-long
JWT_EXPIRATION=3600
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-characters-long
JWT_REFRESH_EXPIRATION=2592000

FIREBASE_PROJECT_ID=barber-pro-dev
FIREBASE_PRIVATE_KEY_ID=key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n<paste key>\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@barber-pro-dev.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=client-id

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

WEBSOCKET_CORS_ORIGIN=*

FCM_SERVER_KEY=your-fcm-key
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=

API_BASE_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080

LOG_LEVEL=debug
```

### 3.4 Create docker-compose.yml for Backend

Create `barberbooking_complete/backend/docker-compose.yml`:

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
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

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

### 3.5 Start Backend Services

```powershell
cd backend

# Start Docker services
docker-compose up -d

# Verify services are running
docker ps

# Should show two containers: redis and firestore-emulator
```

### 3.6 Run Backend

```powershell
cd backend

# Install node modules
npm ci

# Start in development mode (watch mode)
npm run start:dev

# Should see:
# 🚀 Application is running on: http://localhost:3000
# 📚 Swagger documentation: http://localhost:3000/docs
```

**Verify Backend is Running:**

Open in browser: `http://localhost:3000/docs`  
Should see Swagger API documentation.

### 3.7 Backend Modules Checklist

Ensure these modules exist in `src/modules/`:

- [ ] `auth/` — Login, refresh, logout, JWT strategy
- [ ] `bookings/` — Create booking (server-side transaction), get booking
- [ ] `queue/` — Get queue, update status (WebSocket emit)
- [ ] `notifications/` — Send push (FCM), send SMS (stub)
- [ ] `users/` — User profiles
- [ ] `barbers/` — Barber info

If any are missing, copy from `barberbooking_project_with_backend` scaffold.

---

## Phase 4: Frontend Setup (Flutter) (15 min)

### 4.1 Copy Existing Flutter Project

```powershell
# Navigate to frontend folder
cd D:\FlutterProjects\bookyourbarber\barberbooking_complete\frontend

# Copy existing Flutter app files from newbarberproject
# (Copy lib/, pubspec.yaml, android/, ios/, test/, etc.)
```

### 4.2 Clean & Get Dependencies

```powershell
cd frontend

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Verify
flutter pub outdated
```

### 4.3 Update API Configuration

Edit `frontend/lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String devApiUrl = 'http://localhost:3000/api/v1';
  static const String prodApiUrl = 'https://barberpro-backend-xyz.a.run.app/api/v1';

  static String getApiUrl({bool isProd = false}) {
    return isProd ? prodApiUrl : devApiUrl;
  }

  static String getWebSocketUrl({bool isProd = false}) {
    final baseUrl = getApiUrl(isProd: isProd);
    return baseUrl.replaceFirst('/api/v1', '');
  }
}
```

### 4.4 Update API Service

Ensure `frontend/lib/services/api_service.dart` uses backend instead of direct Firestore:

```dart
import 'package:http/http.dart' as http;
import 'package:your_app/config/app_config.dart';
import 'dart:convert';

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
    throw Exception('Failed to create booking: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getQueue(String barberId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/queue/$barberId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get queue');
  }

  // Add other endpoints as needed
}
```

### 4.5 Run Flutter App

```powershell
cd frontend

# Run for barber flavor
flutter run -t lib/main_barber.dart -d chrome

# Or for customer
flutter run -t lib/main_customer.dart -d chrome

# Or Android emulator
flutter run -t lib/main_barber.dart -d emulator-5554
```

**Verify Frontend is Running:**

Should see the BarberPro app UI in browser/emulator.

---

## Phase 5: Verify Full Stack Integration (10 min)

### 5.1 Test Backend API

**Terminal 1 (already running backend):**

```powershell
# Backend should still be running on http://localhost:3000
```

**Terminal 2 (test API):**

```powershell
# Test health endpoint
curl http://localhost:3000/docs

# Should return Swagger UI (HTTP 200)
```

### 5.2 Test Notifications Endpoint

```powershell
# Send test push notification
$body = @{
    topic = "barber-123"
    title = "Test Notification"
    body = "This is a test push"
    data = @{ bookingId = "booking-456" }
} | ConvertTo-Json

curl -X POST http://localhost:3000/api/v1/notifications/push `
  -H "Content-Type: application/json" `
  -d $body

# Should return: { "success": true, "result": "..." }
```

### 5.3 Test Frontend Calling Backend

**In Flutter app:**
1. Create a booking
2. Check backend terminal for API call logs
3. Should see booking created in Firebase Emulator

**In backend terminal, look for logs like:**
```
[LOG] [BookingsService] Creating booking...
[LOG] [BookingsService] Booking created: booking-123, token: 1
```

### 5.4 Verify Redis & Firestore

**Check Redis:**
```powershell
docker exec barber-redis redis-cli
> KEYS *
> GET refreshs:user-123
```

**Check Firestore Emulator:**
Open http://localhost:8080 in browser (if UI is available).

---

## Phase 6: Testing (10 min)

### 6.1 Backend Unit Tests

```powershell
cd backend

# Run all tests
npm run test

# Run with coverage
npm run test:cov

# Watch mode
npm run test:watch
```

### 6.2 Frontend Widget Tests

```powershell
cd frontend

# Run all tests
flutter test

# Run specific test
flutter test test/booking_provider_test.dart

# With coverage
flutter test --coverage
```

---

## Phase 7: Build for Production (5 min)

### 7.1 Build Backend Docker Image

```powershell
cd backend

# Create Dockerfile if not exists
# (See COMPLETE_PROJECT_SETUP_GUIDE.md for Dockerfile content)

# Build image
docker build -t barberpro-backend:latest .

# Test locally
docker run -p 3000:3000 `
  -e NODE_ENV=production `
  -e JWT_SECRET=your-secret `
  -e FIREBASE_PROJECT_ID=barber-pro-dev `
  barberpro-backend:latest
```

### 7.2 Build Flutter Apps

```powershell
cd frontend

# Build APK (Android)
flutter build apk --release -t lib/main_barber.dart

# Build AAB for Play Store (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release
```

---

## Phase 8: Deployment to Cloud Run (15 min)

### 8.1 Setup Google Cloud Project

```powershell
# Authenticate with Google Cloud
gcloud auth login

# Set project
gcloud config set project <YOUR_PROJECT_ID>

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 8.2 Create Service Account

```powershell
# Create service account
gcloud iam service-accounts create barber-backend-sa

# Grant Cloud Run Admin role
gcloud projects add-iam-policy-binding <PROJECT_ID> `
  --member=serviceAccount:barber-backend-sa@<PROJECT_ID>.iam.gserviceaccount.com `
  --role=roles/run.admin
```

### 8.3 Push Docker Image to Google Container Registry

```powershell
cd backend

# Configure Docker auth
gcloud auth configure-docker

# Tag image
docker tag barberpro-backend:latest gcr.io/<PROJECT_ID>/barberpro-backend:latest

# Push to GCR
docker push gcr.io/<PROJECT_ID>/barberpro-backend:latest
```

### 8.4 Deploy to Cloud Run

```powershell
# Deploy service
gcloud run deploy barberpro-backend `
  --image gcr.io/<PROJECT_ID>/barberpro-backend:latest `
  --region us-central1 `
  --platform managed `
  --service-account barber-backend-sa@<PROJECT_ID>.iam.gserviceaccount.com `
  --set-env-vars "NODE_ENV=production,JWT_SECRET=<YOUR_SECRET>,FIREBASE_PROJECT_ID=barber-pro-dev" `
  --memory 512Mi `
  --cpu 1 `
  --allow-unauthenticated
```

**Output will show:**
```
Service URL: https://barberpro-backend-<random>.a.run.app
```

### 8.5 Update Flutter Config for Production

Edit `frontend/lib/config/app_config.dart`:

```dart
static const String prodApiUrl = 'https://barberpro-backend-<random>.a.run.app/api/v1';
```

Build and deploy Flutter app to Play Store, App Store, or web.

---

## Phase 9: GitHub Actions CI/CD (10 min)

### 9.1 Create CI Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: cd backend && npm ci
      - run: cd backend && npm run lint
      - run: cd backend && npm run test

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter analyze
      - run: cd frontend && flutter test
```

### 9.2 Create Deploy Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - uses: google-github-actions/setup-gcloud@v1
      - run: gcloud auth configure-docker
      - run: docker build -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }} backend/
      - run: docker push gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }}
      - uses: google-github-actions/deploy-cloudrun@v1
        with:
          service: barberpro-backend
          image: gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }}
          region: us-central1
```

### 9.3 Add GitHub Secrets

Go to GitHub repo Settings → Secrets and add:
- `GCP_SA_KEY` (service account JSON)
- `GCP_PROJECT_ID` (your Google Cloud project ID)

---

## Phase 10: Final Verification Checklist

- [ ] Backend running locally (`npm run start:dev`)
- [ ] Frontend running locally (`flutter run`)
- [ ] Redis container running (`docker ps`)
- [ ] Firestore emulator running (`docker ps`)
- [ ] Swagger docs accessible (`http://localhost:3000/docs`)
- [ ] Backend tests passing (`npm run test`)
- [ ] Frontend tests passing (`flutter test`)
- [ ] API calls working from Flutter
- [ ] Notifications endpoint working (curl test)
- [ ] WebSocket real-time updates working
- [ ] Docker image built successfully
- [ ] Cloud Run deployment successful
- [ ] GitHub Actions workflows passing
- [ ] Production URL updated in Flutter config
- [ ] End-to-end test on staging environment

---

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| `Port 3000 already in use` | `lsof -i :3000` then `kill -9 <PID>` (Mac/Linux) or use Task Manager (Windows) |
| `Firebase credentials not found` | Ensure `FIREBASE_PRIVATE_KEY` is in `.env.local` with proper escaping |
| `Redis connection error` | Run `docker-compose up -d` and verify `docker ps` |
| `Flutter build errors` | Run `flutter clean && flutter pub get` |
| `WebSocket connection fails` | Check backend is running and CORS is enabled |
| `Docker build fails` | Ensure Docker is running: `docker ps` |
| `Cloud Run deploy fails` | Check logs: `gcloud run logs barberpro-backend --limit 50` |

---

## Time Estimates

| Phase | Time | Notes |
|-------|------|-------|
| 1. Environment Setup | 15 min | One-time, includes installations |
| 2. Project Structure | 10 min | One-time folder setup |
| 3. Backend Setup | 20 min | Includes Docker, npm install, .env config |
| 4. Frontend Setup | 15 min | Depends on existing Flutter project |
| 5. Integration Test | 10 min | Verify full stack works |
| 6. Testing | 10 min | Run unit tests |
| 7. Build Production | 5 min | Docker + Flutter builds |
| 8. Cloud Run Deploy | 15 min | GCP setup + deployment |
| 9. GitHub Actions | 10 min | CI/CD workflow setup |
| 10. Final Check | 5 min | Verification checklist |
| **Total** | **~2 hours** | First time only; subsequent changes are faster |

---

## Key Commands Quick Reference

```powershell
# Backend - Start
docker-compose up -d
npm run start:dev

# Backend - Stop
docker-compose down

# Backend - Test
npm run test

# Frontend - Run
flutter run -t lib/main_barber.dart -d chrome

# Frontend - Test
flutter test

# Build Docker image
docker build -t barberpro-backend:latest .

# Deploy to Cloud Run
gcloud run deploy barberpro-backend --image gcr.io/<PROJECT>/barberpro-backend:latest

# View Cloud Run logs
gcloud run logs barberpro-backend --limit 50

# Check running processes
docker ps
```

---

## Resources & Links

- **Flutter Docs**: https://flutter.dev/docs
- **NestJS Docs**: https://docs.nestjs.com
- **Firebase Admin SDK**: https://firebase.google.com/docs/database/admin/start
- **Google Cloud Run**: https://cloud.google.com/run/docs
- **Docker Docs**: https://docs.docker.com
- **GitHub Actions**: https://docs.github.com/en/actions

---

## Support

For issues or questions:
1. Check Troubleshooting section in this file
2. Review COMPLETE_PROJECT_SETUP_GUIDE.md for detailed explanations
3. Check backend logs: `docker logs barber-redis` or `npm run start:dev` console
4. Check Cloud Run logs: `gcloud run logs barberpro-backend`

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Status:** Production Ready  
**Audience:** Full-stack developers building BarberPro project
