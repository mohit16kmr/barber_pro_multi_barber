# Complete BarberPro Project Setup Guide
**Everything you need to build, develop, and deploy the full stack (Flutter + NestJS + Firebase)**

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [Backend Setup (NestJS)](#backend-setup-nestjs)
6. [Frontend Setup (Flutter)](#frontend-setup-flutter)
7. [Local Development](#local-development)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)

---

## Project Overview

**BarberPro** is a real-time barber booking and queue management system built with:
- **Frontend**: Flutter (Dart) — multi-flavor app (Customer, Barber, Admin)
- **Backend**: NestJS (Node.js + TypeScript) — REST API + WebSocket
- **Persistence**: Firestore (Firebase) — canonical data store
- **Cache/Session**: Redis — refresh tokens, rate limiting
- **Notifications**: FCM (Firebase Cloud Messaging) + SMS (Twilio stub)
- **Deployment**: Google Cloud Run + Docker

**Key Features:**
- Customers book services → barber app receives real-time queue updates
- Barbers skip/complete bookings → customers notified via FCM
- Server-side token generation (Firestore transaction) — no race conditions
- JWT + refresh token rotation via Redis
- WebSocket for live queue sync

---

## Project Structure

```
barberbooking_project/
├── frontend/                          # Flutter app
│   ├── lib/
│   │   ├── main_barber.dart          # Barber app entry
│   │   ├── main_customer.dart        # Customer app entry
│   │   ├── main_admin.dart           # Admin app entry
│   │   ├── models/                   # Data models
│   │   ├── providers/                # State management (Provider)
│   │   ├── screens/                  # UI screens
│   │   ├── services/                 # API/Firebase services
│   │   ├── utils/                    # Utilities & constants
│   │   └── widgets/                  # Reusable components
│   ├── test/                         # Unit & widget tests
│   ├── android/                      # Android native config
│   ├── ios/                          # iOS native config
│   ├── pubspec.yaml                  # Dependencies
│   ├── .env.example                  # Example env (API_BASE_URL, etc.)
│   └── README.md
│
├── backend/                          # NestJS backend
│   ├── src/
│   │   ├── main.ts                   # App entry, Swagger setup
│   │   ├── app.module.ts             # Root module, wiring
│   │   ├── common/
│   │   │   ├── firebase/             # Firebase Admin SDK
│   │   │   ├── redis/                # Redis client
│   │   │   ├── logger/               # Logging
│   │   │   └── websocket/            # Socket.IO gateway
│   │   └── modules/
│   │       ├── auth/                 # JWT, refresh tokens
│   │       ├── bookings/             # Booking creation, Firestore transaction
│   │       ├── queue/                # Queue mgmt, WebSocket emit
│   │       ├── notifications/        # FCM + SMS
│   │       ├── users/                # User profiles
│   │       ├── barbers/              # Barber info
│   │       └── admin/                # Admin endpoints
│   ├── test/                         # Unit & integration tests
│   ├── Dockerfile                    # Container image
│   ├── docker-compose.yml            # Redis + Firestore emulator
│   ├── package.json                  # Node dependencies
│   ├── tsconfig.json                 # TypeScript config
│   ├── .env.example                  # Example env
│   ├── jest.config.js                # Jest test config
│   └── README.md
│
├── docker-compose.yml                # Top-level (optional, if not per-service)
├── README.md                          # Project root README
├── .gitignore                         # Git ignore rules
└── .github/
    └── workflows/
        ├── ci.yml                    # Lint, test, build
        └── deploy.yml                # Deploy to Cloud Run

```

---

## Prerequisites

**Install on your machine:**

1. **Node.js & npm** (v18+)
   - Download: https://nodejs.org/
   - Verify: `node --version && npm --version`

2. **Dart & Flutter** (v3.10+)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`

3. **Docker & Docker Compose** (for emulators)
   - Download: https://docs.docker.com/get-docker/
   - Verify: `docker --version && docker-compose --version`

4. **Git**
   - Download: https://git-scm.com/
   - Verify: `git --version`

5. **Firebase CLI** (optional, for emulator)
   - Install: `npm install -g firebase-tools`
   - Verify: `firebase --version`

6. **Google Cloud SDK** (optional, for Cloud Run deploy)
   - Download: https://cloud.google.com/sdk/docs/install

**Accounts:**
- Firebase project (with Firestore, Authentication, Cloud Messaging enabled)
- Twilio account (for SMS; optional)
- Google Cloud project (for Cloud Run; optional)

---

## Initial Setup

### Step 1: Clone or Create Project

```powershell
# If creating new monorepo (recommended)
mkdir barberbooking_project
cd barberbooking_project
git init

# Copy existing Flutter project into frontend/
# (copy contents of newbarberproject into frontend/ folder)
mkdir frontend
# Copy Flutter app files here

# Copy backend scaffold into backend/
mkdir backend
# Copy barberbooking_project_with_backend or barber-pro-backend here
```

### Step 2: Configure Git

Create `.gitignore` in project root:

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

Create root `README.md`:

```markdown
# BarberPro - Real-Time Barber Booking System

Full-stack Flutter + NestJS application for real-time barber booking and queue management.

## Quick Start

See [backend/README.md](backend/README.md) and [frontend/README.md](frontend/README.md) for setup.

### Local Development

1. Start backend:
   \`\`\`powershell
   cd backend
   docker-compose up -d
   npm ci
   npm run start:dev
   \`\`\`

2. Start frontend:
   \`\`\`powershell
   cd frontend
   flutter clean
   flutter pub get
   flutter run -t lib/main_barber.dart -d chrome
   \`\`\`

3. Swagger API docs: http://localhost:3000/docs

## Project Structure

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed layout.

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for Cloud Run, GitHub Actions, and CI/CD setup.
```

---

## Backend Setup (NestJS)

### Step 1: Project Initialization (if starting fresh)

```powershell
cd backend

# Install NestJS CLI
npm install -g @nestjs/cli

# Create new NestJS project (alternative if not using scaffold)
nest new . --package-manager npm

# Or use existing scaffold (barberbooking_project_with_backend)
# Just cd into it and continue
```

### Step 2: Dependencies

Ensure `package.json` has these key dependencies:

```json
{
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/jwt": "^12.0.0",
    "@nestjs/passport": "^10.0.0",
    "@nestjs/platform-ws": "^10.3.0",
    "@nestjs/swagger": "^7.1.0",
    "@nestjs/websockets": "^10.3.0",
    "firebase-admin": "^12.0.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.1",
    "redis": "^4.6.0",
    "socket.io": "^4.7.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "uuid": "^9.0.1"
  }
}
```

Install:
```powershell
npm ci
```

### Step 3: Configuration

Create `backend/.env.local` from `.env.example`:

```dotenv
NODE_ENV=development
PORT=3000
API_VERSION=v1

# JWT
JWT_SECRET=your-super-secret-key-min-32-chars
JWT_EXPIRATION=3600
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars
JWT_REFRESH_EXPIRATION=2592000

# Firebase (get from service account JSON)
FIREBASE_PROJECT_ID=barber-pro-dev
FIREBASE_PRIVATE_KEY_ID=key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n<paste key>\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@barber-pro-dev.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/...

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# WebSocket
WEBSOCKET_CORS_ORIGIN=*

# Notifications
FCM_SERVER_KEY=<your-fcm-key>
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=+1234567890

# API
API_BASE_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080

# Logging
LOG_LEVEL=debug
```

**Getting Firebase credentials:**
1. Go to Firebase Console → Your Project → Settings → Service Accounts
2. Click "Generate New Private Key"
3. Copy the JSON file contents into your `.env.local`

### Step 4: Docker Compose (for local services)

Create `backend/docker-compose.yml`:

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

Start services:
```powershell
cd backend
docker-compose up -d
```

### Step 5: Core Backend Modules

Ensure these modules are implemented (copy from `barberbooking_project_with_backend` if needed):

**`src/modules/auth/`**
- `auth.controller.ts` — POST `/auth/login`, `/auth/refresh`, `/auth/logout`
- `auth.service.ts` — verify Firebase ID token, generate JWT, refresh token rotation with Redis
- `jwt.strategy.ts` — Passport JWT strategy
- `auth.module.ts`

**`src/modules/bookings/`**
- `bookings.service.ts` — `createBooking()` (Firestore transaction for token allocation)
- `bookings.controller.ts` — POST `/bookings`, GET `/bookings/:id`
- `dto/create-booking.dto.ts`
- `bookings.module.ts`

**`src/modules/queue/`**
- `queue.service.ts` — `getQueue()`, `updateStatus()` (emit WebSocket events)
- `queue.controller.ts` — GET `/queue/:barberId`, PATCH `/bookings/:id/status`
- `queue.module.ts`

**`src/modules/notifications/`** (already implemented in `barberbooking_project_with_backend`)
- `notifications.service.ts` — `sendPush()`, `sendSms()`, `notifyBookingCreated()`, `notifyQueueUpdate()`
- `notifications.controller.ts` — POST `/notifications/push`
- `dto/send-push.dto.ts`
- `notifications.module.ts`

**`src/common/`**
- `firebase/firebase.service.ts` — Firebase Admin SDK initialization
- `redis/redis.service.ts` — Redis client wrapper
- `logger/logger.service.ts` — Simple logging
- `websocket/websocket.gateway.ts` — Socket.IO gateway for queue updates

### Step 6: Main App Entry

Ensure `src/main.ts` includes:

```typescript
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Middleware
  app.use(helmet());
  app.enableCors({ origin: '*', credentials: true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.setGlobalPrefix(`api/${process.env.API_VERSION || 'v1'}`);

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('BarberPro API')
    .setDescription('Real-time barber booking system')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 App running on http://localhost:${port}`);
  console.log(`📚 Docs: http://localhost:${port}/docs`);
}

bootstrap();
```

### Step 7: Run Backend

```powershell
cd backend

# Development (with hot reload)
npm run start:dev

# Production
npm run build
npm run start:prod
```

Visit: http://localhost:3000/docs (Swagger)

---

## Frontend Setup (Flutter)

### Step 1: Project Structure

Ensure existing Flutter project in `frontend/` has:

```
lib/
├── main_barber.dart       # Barber app entry (flavor: barber)
├── main_customer.dart     # Customer app entry (flavor: customer)
├── main_admin.dart        # Admin app entry (flavor: admin)
├── models/                # Booking, Barber, User, etc.
├── providers/             # State management
├── screens/               # UI screens
├── services/              # API & Firebase services
├── utils/                 # Constants, helpers
└── widgets/               # Reusable components
```

### Step 2: Dependencies

Key `pubspec.yaml` entries:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  go_router: ^11.0.0
  firebase_core: ^24.0.0
  cloud_firestore: ^14.0.0
  firebase_auth: ^4.0.0
  firebase_messaging: ^14.0.0
  http: ^1.1.0
  dio: ^5.3.0
  socket_io_client: ^2.0.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  firebase_emulator_setup: ^1.0.0
```

Install:
```powershell
cd frontend
flutter clean
flutter pub get
```

### Step 3: Configuration per Flavor

Create `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String barberApiUrl = 'http://localhost:3000/api/v1';
  static const String customerApiUrl = 'http://localhost:3000/api/v1';
  static const String adminApiUrl = 'http://localhost:3000/api/v1';

  // Or use environment-specific URLs
  static String getApiUrl(String flavor) {
    switch (flavor) {
      case 'barber':
        return 'http://localhost:3000/api/v1'; // Dev
        // return 'https://api.barberpro.com/api/v1'; // Prod
      case 'customer':
        return 'http://localhost:3000/api/v1';
      case 'admin':
        return 'http://localhost:3000/api/v1';
      default:
        return 'http://localhost:3000/api/v1';
    }
  }
}
```

### Step 4: API Service Integration

Update `lib/services/api_service.dart` to call backend instead of direct Firestore:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class ApiService {
  final String baseUrl;

  ApiService({String? customBaseUrl})
      : baseUrl = customBaseUrl ?? AppConfig.getApiUrl('barber');

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bookingData),
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

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update booking status');
    }
  }
}
```

### Step 5: WebSocket Integration (for real-time queue)

Update `lib/services/websocket_service.dart`:

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  late IO.Socket socket;
  final String baseUrl;

  WebSocketService({required this.baseUrl});

  void connect() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 10,
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('WebSocket connected');
    });

    socket.on('disconnect', (_) {
      print('WebSocket disconnected');
    });

    socket.on('queue:updated', (data) {
      print('Queue updated: $data');
      // Update UI via Provider
    });
  }

  void subscribeToQueue(String barberId) {
    socket.emit('subscribe', {'room': 'queue-$barberId'});
  }

  void disconnect() {
    socket.disconnect();
  }
}
```

### Step 6: Update Provider to use Backend API

Example `lib/providers/booking_provider.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService apiService;
  List<Booking> bookings = [];
  bool loading = false;

  BookingProvider({required this.apiService});

  Future<void> createBooking(Booking booking) async {
    loading = true;
    notifyListeners();
    try {
      final response = await apiService.createBooking(booking.toJson());
      bookings.add(Booking.fromJson(response));
    } catch (e) {
      print('Error: $e');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadBookings() async {
    loading = true;
    notifyListeners();
    try {
      // Fetch from backend API
      final response = await apiService.getQueue('current_barber_id');
      // Parse and update bookings list
    } catch (e) {
      print('Error: $e');
    }
    loading = false;
    notifyListeners();
  }
}
```

### Step 7: Run Flutter App

```powershell
cd frontend

# Run for barber flavor
flutter run -t lib/main_barber.dart -d chrome

# Or for customer
flutter run -t lib/main_customer.dart -d chrome

# Android
flutter run -t lib/main_barber.dart -d emulator-5554
```

---

## Local Development

### Full Local Setup (One Terminal, Step-by-Step)

**Terminal 1 — Backend:**
```powershell
cd backend

# Start emulators (Redis + Firestore)
docker-compose up -d

# Check if running
docker ps

# Install dependencies
npm ci

# Run backend
npm run start:dev

# Should see: 🚀 Application is running on: http://localhost:3000
```

**Terminal 2 — Frontend:**
```powershell
cd frontend

# Clean
flutter clean

# Get dependencies
flutter pub get

# Run (choose device: chrome, android, etc.)
flutter run -t lib/main_barber.dart -d chrome
```

**Terminal 3 — Test Notifications (optional):**
```powershell
# Test push notification endpoint
curl -X POST http://localhost:3000/api/v1/notifications/push `
  -H "Content-Type: application/json" `
  -d '{
    "topic": "barber-123",
    "title": "Test Notification",
    "body": "This is a test push",
    "data": {"bookingId": "booking-456"}
  }'
```

### Verify Everything is Working

1. **Backend Swagger**: http://localhost:3000/docs
   - Try `/auth/login` endpoint (POST)
   - Verify response includes JWT token

2. **Frontend running**: Should see app UI on Chrome/emulator
   - Try creating a booking (calls backend API)
   - Check terminal output for API responses

3. **Redis**: Verify data is stored
   ```powershell
   docker exec barber-redis redis-cli
   > KEYS *
   > GET <key>
   ```

4. **Firestore Emulator**: Check data
   - Visit http://localhost:8080 (if emulator has UI)
   - Or use Firebase Admin CLI to verify collections

---

## Testing

### Backend Tests (NestJS + Jest)

Create `backend/test/bookings.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { BookingsService } from '../src/modules/bookings/bookings.service';
import { FirebaseService } from '../src/common/firebase/firebase.service';

describe('BookingsService', () => {
  let service: BookingsService;
  let firebaseService: FirebaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BookingsService,
        {
          provide: FirebaseService,
          useValue: { getFirestore: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<BookingsService>(BookingsService);
    firebaseService = module.get<FirebaseService>(FirebaseService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a booking with transaction', async () => {
    // Mock Firestore transaction
    const mockFirestore = {
      runTransaction: jest.fn().mockResolvedValue({
        bookingId: 'booking-123',
        token: 1,
      }),
    };

    jest.spyOn(firebaseService, 'getFirestore').mockReturnValue(mockFirestore as any);

    // Test booking creation
    const booking = await service.createBooking({
      barberId: 'barber-123',
      customerId: 'customer-456',
      serviceId: 'service-789',
    });

    expect(booking).toHaveProperty('bookingId');
  });
});
```

Run tests:
```powershell
cd backend

# Run all tests
npm run test

# Run with coverage
npm run test:cov

# Watch mode
npm run test:watch
```

### Frontend Tests (Flutter)

Create `frontend/test/booking_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/providers/booking_provider.dart';
import 'package:your_app/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('BookingProvider', () {
    late MockApiService mockApiService;
    late BookingProvider bookingProvider;

    setUp(() {
      mockApiService = MockApiService();
      bookingProvider = BookingProvider(apiService: mockApiService);
    });

    test('should create booking successfully', () async {
      final mockBooking = {'id': '123', 'status': 'pending'};
      when(mockApiService.createBooking(any))
          .thenAnswer((_) async => mockBooking);

      // Act
      await bookingProvider.createBooking(Booking(...));

      // Assert
      expect(bookingProvider.bookings.length, 1);
    });
  });
}
```

Run tests:
```powershell
cd frontend

# Run all tests
flutter test

# Run specific test file
flutter test test/booking_provider_test.dart

# With coverage
flutter test --coverage
```

---

## Deployment

### Step 1: Build Docker Image

Create `backend/Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Build
RUN npm run build

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start
CMD ["npm", "run", "start:prod"]
```

Build:
```powershell
cd backend

# Build image
docker build -t barberpro-backend:latest .

# Test locally
docker run -p 3000:3000 `
  -e FIREBASE_PROJECT_ID=barber-pro-dev `
  -e JWT_SECRET=your-secret `
  -e REDIS_HOST=host.docker.internal `
  barberpro-backend:latest
```

### Step 2: Google Cloud Setup

```powershell
# Install gcloud CLI
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set project
gcloud config set project <YOUR_PROJECT_ID>

# Create service account (or reuse existing)
gcloud iam service-accounts create barber-backend-sa

# Grant Cloud Run permissions
gcloud projects add-iam-policy-binding <PROJECT_ID> `
  --member=serviceAccount:barber-backend-sa@<PROJECT_ID>.iam.gserviceaccount.com `
  --role=roles/run.admin
```

### Step 3: Deploy to Cloud Run

```powershell
# Push to Google Container Registry
docker tag barberpro-backend:latest gcr.io/<PROJECT_ID>/barberpro-backend:latest
docker push gcr.io/<PROJECT_ID>/barberpro-backend:latest

# Deploy to Cloud Run
gcloud run deploy barberpro-backend `
  --image gcr.io/<PROJECT_ID>/barberpro-backend:latest `
  --region us-central1 `
  --platform managed `
  --service-account barber-backend-sa@<PROJECT_ID>.iam.gserviceaccount.com `
  --set-env-vars "FIREBASE_PROJECT_ID=barber-pro-dev,JWT_SECRET=<YOUR_SECRET>" `
  --memory 512Mi `
  --cpu 1 `
  --allow-unauthenticated
```

### Step 4: Setup Secrets (Cloud Secret Manager)

```powershell
# Create secret for Firebase service account
gcloud secrets create firebase-service-account --data-file=credentials.json

# Grant Cloud Run service account access
gcloud secrets add-iam-policy-binding firebase-service-account `
  --member=serviceAccount:barber-backend-sa@<PROJECT_ID>.iam.gserviceaccount.com `
  --role=roles/secretmanager.secretAccessor

# Reference in deployment: --set-env-vars FIREBASE_PRIVATE_KEY=<secret reference>
```

### Step 5: GitHub Actions CI/CD

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

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v4
        with:
          context: ./backend
          push: true
          tags: gcr.io/${{ env.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }}

      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v1
        with:
          service: barberpro-backend
          image: gcr.io/${{ env.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }}
          region: us-central1
          env_vars: |
            FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
            JWT_SECRET=${{ secrets.JWT_SECRET }}
```

### Step 6: Update Flutter to Point to Production Backend

Update `lib/config/app_config.dart`:

```dart
class AppConfig {
  static String getApiUrl(String flavor) {
    const isProd = bool.fromEnvironment('PROD', defaultValue: false);
    
    if (isProd) {
      return 'https://barberpro-backend-<random>.a.run.app/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}
```

Build Flutter for production:
```powershell
cd frontend

# Build APK (Android)
flutter build apk --release -t lib/main_barber.dart -t lib/main_customer.dart

# Build AAB (Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build web
flutter build web --release
```

---

## Troubleshooting

### Backend Issues

**Q: `FIREBASE_PRIVATE_KEY` format error**
- A: Use multiline string with literal `\n` chars. In `.env`:
  ```
  FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nactual_key_content\n-----END PRIVATE KEY-----\n"
  ```

**Q: Redis connection error**
- A: Ensure `docker-compose up -d` ran and Redis is listening on `6379`:
  ```powershell
  docker ps | grep redis
  docker logs barber-redis
  ```

**Q: Firestore Emulator not connecting**
- A: Set `FIRESTORE_EMULATOR_HOST=localhost:8080` in `.env.local`

**Q: JWT token expired**
- A: Increase `JWT_EXPIRATION` in `.env` (in seconds)

### Frontend Issues

**Q: "Cannot connect to backend"**
- A: Verify backend is running on `http://localhost:3000` and CORS is enabled

**Q: WebSocket connection fails**
- A: Ensure Socket.IO is properly wired in `websocket.gateway.ts` and frontend connects to same URL

**Q: Firebase initialization fails in Flutter tests**
- A: Initialize Firebase in test setup:
  ```dart
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  ```

### Deployment Issues

**Q: Cloud Run deployment fails**
- A: Check logs: `gcloud run logs barber-backend --limit 50`

**Q: Container doesn't start**
- A: Verify health check endpoint exists and returns 200

---

## Summary Checklist

- [ ] Firebase project created with Firestore, Auth, Cloud Messaging
- [ ] Service account credentials obtained and added to `.env.local`
- [ ] Backend `.env.local` configured (JWT, Redis, Firebase, Twilio)
- [ ] Docker & Docker Compose installed
- [ ] `docker-compose up -d` started Redis + Firestore
- [ ] Backend: `npm ci && npm run start:dev` running
- [ ] Frontend: `flutter run -t lib/main_barber.dart -d chrome` running
- [ ] API calls made successfully (test with curl or Postman)
- [ ] Unit tests passing (`npm run test`, `flutter test`)
- [ ] Notifications working (test FCM push)
- [ ] WebSocket real-time queue sync working
- [ ] Docker image built and pushed to registry
- [ ] Cloud Run deployment successful
- [ ] GitHub Actions CI/CD configured
- [ ] Production URLs updated in Flutter config
- [ ] Final testing on staging/production

---

## Key Endpoints Summary

### Authentication
- `POST /api/v1/auth/login` → { idToken } → { accessToken, refreshToken }
- `POST /api/v1/auth/refresh` → { refreshToken } → { accessToken, refreshToken }
- `POST /api/v1/auth/logout` → clear tokens

### Bookings
- `POST /api/v1/bookings` → create booking (server-side token generation)
- `GET /api/v1/bookings/:id` → get booking details

### Queue
- `GET /api/v1/queue/:barberId` → get barber's queue
- `PATCH /api/v1/bookings/:id/status` → update booking status (skip/complete)

### Notifications
- `POST /api/v1/notifications/push` → send FCM push to token/topic
- WebSocket `queue:updated` event → queue changed on barber's app

---

**Created:** December 2025  
**Version:** 1.0  
**Status:** Complete Setup Guide
