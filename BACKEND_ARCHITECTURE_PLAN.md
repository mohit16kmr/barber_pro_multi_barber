# BarberPro Backend Architecture & API Plan

**Document Version:** 1.0  
**Date:** December 8, 2025  
**Status:** Planning Phase (awaiting confirmation before implementation)

---

## Executive Summary

This document outlines a complete backend/API separation plan for BarberPro, moving from direct Firestore access in Flutter to a secure, scalable backend API (Node.js/Express + TypeScript or Python/FastAPI). This enables:

- ✅ Centralized business logic and security
- ✅ Atomic operations (token generation, queue management)
- ✅ Better testing, monitoring, and scalability
- ✅ Protected PII and payment data
- ✅ Audit logs and compliance
- ✅ A/B testing and feature flags
- ✅ Easier mobile/web/3rd-party integrations

**Architecture Overview:**
```
┌─────────────────────────────────────────────────────────┐
│  Frontend Layer (Flutter Web/Mobile + Admin Panel)      │
│  ├─ Barber App                                           │
│  ├─ Customer App                                         │
│  └─ Admin Dashboard (web)                                │
└─────────────────────────────────────────────────────────┘
                        ↓ REST/gRPC APIs
┌─────────────────────────────────────────────────────────┐
│  Backend API Layer (Node.js/Express or Python/FastAPI)  │
│  ├─ Auth Service (JWT, OAuth 2.0)                        │
│  ├─ Booking Service (queue, tokens, notifications)       │
│  ├─ Barber Service (profile, availability, earnings)     │
│  ├─ Payment Service (cash handling, reconciliation)       │
│  └─ Admin Service (analytics, compliance)                │
└─────────────────────────────────────────────────────────┘
                        ↓ Queries/Writes
┌─────────────────────────────────────────────────────────┐
│  Persistence Layer                                       │
│  ├─ Firestore (bookings, barbers, users, analytics)      │
│  ├─ Redis Cache (queue state, rate limiting)             │
│  └─ PostgreSQL (audit logs, payments, compliance)        │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Current State Analysis

### 1.1 Current Architecture Weaknesses

| Issue | Impact | Severity |
|-------|--------|----------|
| Direct Firestore access from Flutter | Token generation race conditions; hard to test | **HIGH** |
| Client-side business logic | No audit trail; compliance risk | **HIGH** |
| No rate limiting or abuse detection | DDoS risk; bad data quality | **MEDIUM** |
| No centralized logging | Difficult to debug production issues | **MEDIUM** |
| Duplicate code across flavors | Maintenance burden; inconsistency | **MEDIUM** |
| No API versioning strategy | Breaking changes affect all clients | **MEDIUM** |
| PII stored in Firestore unencrypted | Data security risk | **MEDIUM** |

### 1.2 Current Code Flow

```
Flutter App (Customer)
    ↓
Customer selects barber & services
    ↓
BookingService.createBooking()
    ↓
Firestore Transaction (creates bookings doc, updates barber token)
    ↓
Firestore updates BarberProvider (real-time stream)
    ↓
Barber App sees new booking in queue
```

**Problem:** This flow is direct and atomic _only_ because Firestore transactions work. There's no validation layer, rate limiting, or business rule enforcement.

---

## 2. Proposed Backend & API Plan

### 2.1 Technology Stack (Recommended)

**Option A: Node.js + Express (Recommended for quick adoption)**
- **Language:** TypeScript (for type safety)
- **Framework:** Express.js (lightweight, familiar)
- **Database:** Firestore (keep) + PostgreSQL (audit/payments)
- **Cache:** Redis (queue state, rate limiting)
- **Auth:** Firebase Auth tokens (validated server-side) + JWT
- **Deployment:** Cloud Run, Google Compute Engine, or AWS EC2
- **ORM:** Prisma (for PostgreSQL operations)
- **Testing:** Jest + Supertest
- **Monitoring:** Cloud Logging, Sentry, or DataDog

**Option B: Python + FastAPI (More scalable, async-first)**
- **Language:** Python 3.11+
- **Framework:** FastAPI (async, auto-OpenAPI docs)
- **Database:** Firestore + PostgreSQL
- **ORM:** SQLAlchemy
- **Auth:** Firebase Auth + JWT
- **Deployment:** Cloud Run, Heroku, or AWS Lambda
- **Testing:** pytest + pytest-asyncio
- **Monitoring:** Cloud Logging, Sentry

**Recommendation:** Start with **Node.js + TypeScript + Express** for faster iteration; can migrate to FastAPI later if needed.

---

### 2.2 High-Level API Endpoints

#### **Authentication Endpoints**
```
POST   /api/v1/auth/register              # Sign up (customer or barber)
POST   /api/v1/auth/login                 # Email/phone login
POST   /api/v1/auth/login/google          # Google OAuth callback
POST   /api/v1/auth/refresh               # Refresh JWT token
POST   /api/v1/auth/logout                # Logout & invalidate token
GET    /api/v1/auth/me                    # Get current user profile
POST   /api/v1/auth/verify-otp            # Verify phone OTP
```

#### **Booking Endpoints (Customer-facing)**
```
POST   /api/v1/bookings                   # Create a booking
GET    /api/v1/bookings/:bookingId        # Get booking details
GET    /api/v1/bookings                   # List customer's bookings
PATCH  /api/v1/bookings/:bookingId        # Update booking (cancel, reschedule)
GET    /api/v1/bookings/:bookingId/token # Get token (for in-shop display)
POST   /api/v1/bookings/:bookingId/rate  # Submit rating/review
```

#### **Queue Endpoints (Barber-facing)**
```
GET    /api/v1/queue/my-queue             # Get barber's queue (real-time stream via SSE/WebSocket)
PATCH  /api/v1/queue/:bookingId/status   # Update booking status (waiting→next→serving→completed)
PATCH  /api/v1/queue/:bookingId/skip     # Skip customer (append to end of queue)
GET    /api/v1/queue/earnings            # Get daily/weekly earnings
GET    /api/v1/queue/stats               # Get service metrics (avg time, completions)
```

#### **Barber Profile Endpoints**
```
GET    /api/v1/barbers/search             # Search barbers (location, availability)
GET    /api/v1/barbers/:barberId          # Get barber profile
PATCH  /api/v1/barbers/me                 # Update own profile
GET    /api/v1/barbers/me/availability   # Get availability slots
PATCH  /api/v1/barbers/me/availability   # Set availability/shifts
```

#### **Admin Endpoints**
```
GET    /api/v1/admin/analytics            # Dashboard metrics
GET    /api/v1/admin/bookings             # Filter/search all bookings
GET    /api/v1/admin/barbers              # Manage barbers
GET    /api/v1/admin/payments             # Payment reconciliation
POST   /api/v1/admin/reports/export       # Export analytics
```

#### **Real-Time Endpoints (WebSocket / Server-Sent Events)**
```
WS     /ws/queue/:barberId                # Real-time queue updates (barber)
WS     /ws/booking/:bookingId             # Real-time booking status (customer)
SSE    /api/v1/queue/stream               # Alternative: Server-sent events for queue
```

---

### 2.3 Data Models & Database Schema

#### **Firestore Collections (unchanged, but read-only from client)**

```firestore
bookings/{bookingId}
├─ customerId (string)
├─ barberId (string)
├─ tokenNumber (int) ← Generated by backend
├─ services (array of {serviceId, name, price, duration})
├─ totalPrice (float)
├─ status (string: waiting, next, serving, completed, cancelled, skipped)
├─ paymentMethod (string: cash, card, upi)
├─ paymentStatus (string: pending, completed)
├─ bookingTime (timestamp)
├─ estimatedWaitTime (int, minutes)
├─ actualServiceTime (int, minutes)
├─ completionTime (timestamp)
├─ cancellationReason (string)
├─ cancelledBy (string: customer, barber, system)
├─ rating (float, 0-5)
├─ review (string)
└─ metadata.createdAt (timestamp)

barbers/{barberId}
├─ userId (string, foreign key to users)
├─ name (string)
├─ phone (string)
├─ email (string)
├─ profileImage (url)
├─ services (array of {serviceId, name, price, duration})
├─ currentToken (int)
├─ queueLength (int)
├─ availableSlots (array of {date, startTime, endTime})
├─ rating (float)
├─ totalCompletedBookings (int)
└─ metadata.createdAt (timestamp)

users/{userId}
├─ name (string)
├─ phone (string)
├─ email (string)
├─ userType (string: customer, barber, admin)
├─ profileImage (url)
├─ address (string)
├─ fcmToken (string)
└─ metadata.createdAt (timestamp)
```

#### **PostgreSQL Schema (for audit, payments, compliance)**

```sql
-- Audit Logs (immutable)
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    userId VARCHAR(255),
    action VARCHAR(255),        -- create_booking, update_status, etc.
    resourceType VARCHAR(255),  -- booking, barber, payment
    resourceId VARCHAR(255),
    oldValues JSONB,            -- Before update
    newValues JSONB,            -- After update
    ipAddress VARCHAR(45),
    userAgent TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INDEX idx_audit_logs_userId_createdAt;

-- Payment Ledger (immutable)
CREATE TABLE payment_ledger (
    id SERIAL PRIMARY KEY,
    bookingId VARCHAR(255),
    barberId VARCHAR(255),
    customerId VARCHAR(255),
    amount DECIMAL(10, 2),
    currency VARCHAR(3),       -- INR, USD
    method VARCHAR(50),        -- cash, card, upi
    status VARCHAR(50),        -- pending, completed, failed
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP
);
INDEX idx_payment_ledger_bookingId;
INDEX idx_payment_ledger_barberId_createdAt;

-- Rate Limits (for abuse detection)
CREATE TABLE rate_limits (
    id SERIAL PRIMARY KEY,
    userId VARCHAR(255),
    endpoint VARCHAR(255),
    requestCount INT,
    windowStart TIMESTAMP,
    windowEnd TIMESTAMP
);
INDEX idx_rate_limits_userId_endpoint_windowStart;

-- Feature Flags (for A/B testing, rollouts)
CREATE TABLE feature_flags (
    id SERIAL PRIMARY KEY,
    flagName VARCHAR(255) UNIQUE,
    enabled BOOLEAN,
    rolloutPercentage INT,      -- 0-100
    targetUserIds JSONB,        -- specific user IDs to enable for
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP
);
```

---

### 2.4 Business Logic to Move to Backend

#### **Critical (Move immediately)**

1. **Token Generation** (currently in BookingService.createBooking)
   - Backend increments `currentToken` atomically
   - Prevents race conditions and duplicate tokens
   - Firestore transaction → SQL transaction + Firestore update

2. **Queue Management** (currently in BarberProvider)
   - Calculate next-in-line status
   - Handle skips and queue reordering
   - Only backend can update booking status
   - Barber app reads status, doesn't write directly

3. **Payment & Earnings Calculation**
   - Backend calculates barber earnings
   - Reconcile with manual payments
   - Audit trail in PostgreSQL
   - PII (bank accounts, tax IDs) stored only in PostgreSQL (encrypted)

4. **Rate Limiting & Abuse Detection**
   - Prevent booking spam
   - Prevent double-booking same time slot
   - Limit queue state changes
   - Block suspicious IP addresses

5. **Notifications** (currently triggered from client)
   - Backend owns notification logic
   - Send SMS/push when customer notified (30 min, 10 min before)
   - Send notification when barber service starts
   - Send confirmation when booking completed

#### **Important (Move soon)**

6. **Availability Slot Management**
   - Barber sets shifts/availability
   - Backend validates no time conflicts
   - Calculate wait time predictions
   - Backend reserves slots atomically

7. **Search & Discovery**
   - Backend filters barbers by location, availability, rating
   - Cache results in Redis
   - Full-text search (barber name, service)

8. **Admin Analytics**
   - Aggregate metrics from Firestore (read-only)
   - Calculate KPIs (avg service time, daily bookings, revenue)
   - Generate reports
   - Export to CSV/PDF

#### **Nice-to-Have (Move later)**

9. **Recommendation Engine**
   - Suggest barbers based on customer history
   - Suggest time slots based on barber load
   - ML model for price optimization

10. **Integration Webhooks**
    - Third-party payment integration callbacks
    - SMS gateway callbacks
    - Accounting system exports

---

### 2.5 Authentication & Authorization

#### **JWT-based Auth Flow**

```
┌──────────┐                                    ┌─────────┐
│  Client  │                                    │ Backend │
└────┬─────┘                                    └────┬────┘
     │                                               │
     │  1. POST /auth/register (email, password)    │
     │──────────────────────────────────────────────>
     │                                               │
     │  2. Validate & create Firebase Auth user     │
     │  3. Get Firebase ID token                    │
     │  4. Generate JWT (valid for 1 hour)          │
     │  5. Generate refresh token (valid for 30 d)  │
     │<─────────────────────────────────────────────│
     │  { jwt, refreshToken, expiresIn }            │
     │                                               │
     │  6. Store jwt in memory, refreshToken in SS  │
     │                                               │
     │  For each API call:                          │
     │  7. Add "Authorization: Bearer <jwt>"        │
     │──────────────────────────────────────────────>
     │                                               │
     │  8. Verify JWT signature & claims            │
     │  9. Extract userId, userType, permissions    │
     │                                               │
     │  10. Execute request (with auth context)     │
     │<─────────────────────────────────────────────│
     │  { data, status }                            │
```

**Token Schema (JWT Payload):**
```json
{
  "sub": "firebase-uid",
  "userId": "custom-user-id",
  "userType": "customer",           // "customer", "barber", "admin"
  "email": "user@example.com",
  "phone": "+1234567890",
  "permissions": ["bookings.read", "bookings.write"],
  "iat": 1733705200,
  "exp": 1733708800                 // 1 hour
}
```

**Refresh Token Flow:**
```
When JWT expires (401 Unauthorized):
1. Client sends refreshToken to POST /auth/refresh
2. Backend validates refreshToken
3. Issue new JWT (1 hour) + new refresh token (30 days)
4. Client retries original request
```

---

### 2.6 API Request/Response Format

#### **Standard Request**
```json
POST /api/v1/bookings
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "barberId": "barber-123",
  "serviceIds": ["service-1", "service-2"],
  "bookingDate": "2025-12-10",
  "preferredTime": "14:00",  // Optional
  "notes": "Please be gentle"
}
```

#### **Standard Response (Success)**
```json
{
  "success": true,
  "data": {
    "bookingId": "booking-456",
    "tokenNumber": 42,
    "status": "waiting",
    "estimatedWaitTime": 45,
    "createdAt": "2025-12-08T14:30:00Z"
  },
  "meta": {
    "timestamp": "2025-12-08T14:30:00Z",
    "requestId": "req-xyz-789"
  }
}
```

#### **Standard Response (Error)**
```json
{
  "success": false,
  "error": {
    "code": "BARBER_UNAVAILABLE",
    "message": "Barber not available at requested time",
    "details": {
      "nextAvailableTime": "2025-12-11T10:00:00Z"
    }
  },
  "meta": {
    "timestamp": "2025-12-08T14:30:00Z",
    "requestId": "req-xyz-789"
  }
}
```

#### **Error Codes**
```
400 BAD_REQUEST              Invalid input data
401 UNAUTHORIZED             Missing or invalid token
403 FORBIDDEN                Insufficient permissions
404 NOT_FOUND                Resource not found
409 CONFLICT                 Barber unavailable, slot taken, etc.
429 RATE_LIMIT_EXCEEDED      Too many requests
500 INTERNAL_ERROR           Server error
```

---

### 2.7 Real-Time Communication Strategy

#### **Option 1: WebSocket (Recommended for queue updates)**
- **Use case:** Barber queue updates, customer booking status
- **Namespace:** `/ws/queue/:barberId`, `/ws/booking/:bookingId`
- **Frequency:** Updates when status changes
- **Libraries:** Socket.io or ws + Redis pub/sub for multi-server scaling

```dart
// Flutter WebSocket client
final socket = IO.io(
  'https://api.barberpro.com',
  OptionBuilder()
    .setTransports(['websocket'])
    .enableForceNew()
    .setAuth({'token': jwt})
    .build(),
);

socket.on('queue_updated', (data) {
  setState(() => queue = data);
});

socket.emit('request_queue_stream', {'barberId': '123'});
```

#### **Option 2: Server-Sent Events (SSE) - Simpler alternative**
- **Use case:** One-way updates (notifications, status changes)
- **Frequency:** Lower latency requirements
- **Libraries:** Native JavaScript EventSource, or Flutter packages

```dart
// Flutter SSE client
final eventSource = EventSource(
  Uri.parse('https://api.barberpro.com/api/v1/queue/stream?barberId=123'),
  headers: {'Authorization': 'Bearer $jwt'},
);

eventSource.listen((event) {
  final booking = jsonDecode(event.data);
  setState(() => queue.updateBooking(booking));
});
```

**Recommendation:** Use **WebSocket for barber queue** (frequent updates), **Push notifications (Firebase Cloud Messaging)** for customer notifications.

---

### 2.8 Security Considerations

#### **Data Security**
- ✅ Encrypt PII at rest (phone, address) using AES-256
- ✅ HTTPS only (TLS 1.3)
- ✅ JWT tokens signed with RS256 (asymmetric)
- ✅ Store sensitive data (bank accounts) in PostgreSQL, encrypted
- ✅ Firestore rules: Read/write only your own data

#### **API Security**
- ✅ Rate limiting: 100 requests/minute per user
- ✅ CORS: Restrict to known domains
- ✅ CSRF protection (if using cookies)
- ✅ Input validation (sanitize, type-check)
- ✅ SQL injection prevention (use ORM, parameterized queries)
- ✅ Audit logging for sensitive operations
- ✅ API versioning to avoid breaking changes

#### **Infrastructure Security**
- ✅ Secrets management (environment variables, Google Secret Manager)
- ✅ Network policies (firewall rules)
- ✅ DDoS protection (Cloud Armor / WAF)
- ✅ Backup & disaster recovery (daily backups)
- ✅ Monitoring & alerting (log analysis, uptime checks)

---

## 3. New Folder Structure

### **Frontend (Flutter) - Restructured**
```
newbarberproject/
├─ lib/
│  ├─ main.dart (router entry)
│  ├─ main_barber.dart
│  ├─ main_customer.dart
│  ├─ main_admin.dart
│  ├─ config/
│  │  ├─ app_constants.dart      (now: only client-side constants)
│  │  ├─ api_config.dart         (NEW: API base URLs, endpoints)
│  │  └─ firebase_options.dart
│  ├─ models/
│  │  ├─ booking.dart
│  │  ├─ barber.dart
│  │  ├─ user.dart
│  │  ├─ service.dart
│  │  └─ index.dart
│  ├─ services/
│  │  ├─ api/                    (NEW: API client services)
│  │  │  ├─ api_client.dart      (Base HTTP client with JWT handling)
│  │  │  ├─ auth_api.dart        (Auth endpoints)
│  │  │  ├─ booking_api.dart     (Booking endpoints)
│  │  │  ├─ barber_api.dart      (Barber endpoints)
│  │  │  ├─ queue_api.dart       (Queue endpoints)
│  │  │  └─ admin_api.dart
│  │  ├─ local/                  (Local storage, caching)
│  │  │  ├─ storage_service.dart
│  │  │  ├─ cache_service.dart
│  │  │  └─ preferences_service.dart
│  │  ├─ websocket/              (NEW: Real-time services)
│  │  │  ├─ websocket_service.dart
│  │  │  └─ queue_stream_service.dart
│  │  ├─ notification/           (Existing notification logic)
│  │  │  └─ notification_service.dart
│  │  ├─ auth_service.dart       (Simplified: delegates to API)
│  │  ├─ booking_service.dart    (Deprecated: use BookingApi instead)
│  │  ├─ barber_service.dart     (Refactored: use BarberApi)
│  │  └─ user_service.dart
│  ├─ providers/
│  │  ├─ auth_provider.dart      (Uses AuthApi)
│  │  ├─ booking_provider.dart   (Uses BookingApi)
│  │  ├─ barber_provider.dart    (Uses QueueApi & BarberApi)
│  │  ├─ admin_provider.dart
│  │  └─ theme_provider.dart
│  ├─ screens/
│  │  ├─ auth/
│  │  ├─ customer/
│  │  ├─ barber/
│  │  ├─ admin/
│  │  └─ shared/
│  ├─ widgets/
│  ├─ utils/
│  └─ routes/
│     └─ router.dart (GoRouter config)
├─ test/
│  ├─ unit/
│  │  ├─ models/
│  │  ├─ services/
│  │  │  ├─ api/
│  │  │  │  ├─ auth_api_test.dart
│  │  │  │  ├─ booking_api_test.dart
│  │  │  │  └─ queue_api_test.dart
│  │  │  └─ local/
│  │  └─ providers/
│  ├─ widget/
│  │  ├─ screens/
│  │  └─ widgets/
│  └─ integration/
│     └─ booking_flow_test.dart
├─ pubspec.yaml
└─ README.md
```

### **Backend (Node.js/Express) - New Project**
```
barber-pro-backend/
├─ src/
│  ├─ main.ts                   (Express app entry)
│  ├─ config/
│  │  ├─ env.ts                 (Environment variables)
│  │  ├─ firebase.ts            (Firebase Admin SDK init)
│  │  ├─ postgres.ts            (Database connection)
│  │  ├─ redis.ts               (Redis client)
│  │  └─ logger.ts
│  ├─ middleware/
│  │  ├─ auth.ts                (JWT verification)
│  │  ├─ errorHandler.ts        (Global error handling)
│  │  ├─ rateLimit.ts           (Rate limiting)
│  │  ├─ logger.ts              (Request logging)
│  │  └─ validation.ts          (Input validation)
│  ├─ controllers/
│  │  ├─ auth.controller.ts
│  │  ├─ bookings.controller.ts
│  │  ├─ barbers.controller.ts
│  │  ├─ queue.controller.ts
│  │  └─ admin.controller.ts
│  ├─ services/                 (Business logic)
│  │  ├─ auth.service.ts
│  │  ├─ booking.service.ts     (Token generation, queue logic)
│  │  ├─ barber.service.ts      (Availability, earnings)
│  │  ├─ queue.service.ts       (Queue state, ordering)
│  │  ├─ payment.service.ts     (Earnings, reconciliation)
│  │  ├─ notification.service.ts (SMS, push notifications)
│  │  └─ admin.service.ts       (Analytics, reporting)
│  ├─ repositories/             (Data access, Firestore + PostgreSQL)
│  │  ├─ booking.repository.ts
│  │  ├─ barber.repository.ts
│  │  ├─ user.repository.ts
│  │  ├─ audit.repository.ts
│  │  └─ payment.repository.ts
│  ├─ routes/
│  │  ├─ auth.routes.ts
│  │  ├─ bookings.routes.ts
│  │  ├─ barbers.routes.ts
│  │  ├─ queue.routes.ts
│  │  ├─ admin.routes.ts
│  │  └─ index.ts               (Mount all routes)
│  ├─ websocket/
│  │  ├─ handlers/
│  │  │  ├─ queue.handler.ts
│  │  │  └─ booking.handler.ts
│  │  └─ manager.ts             (WebSocket connection manager)
│  ├─ models/
│  │  ├─ booking.model.ts
│  │  ├─ barber.model.ts
│  │  ├─ user.model.ts
│  │  └─ payment.model.ts
│  ├─ types/
│  │  ├─ index.ts               (TypeScript interfaces)
│  │  └─ api.types.ts
│  ├─ utils/
│  │  ├─ jwt.ts                 (JWT generation/verification)
│  │  ├─ validation.ts          (Input validation schemas)
│  │  ├─ error.ts               (Custom error classes)
│  │  └─ logger.ts              (Logging utility)
│  └─ seeds/                    (Database seeding scripts)
│     ├─ users.seed.ts
│     └─ services.seed.ts
├─ migrations/                  (PostgreSQL migrations)
│  ├─ 001_create_audit_logs.sql
│  ├─ 002_create_payment_ledger.sql
│  └─ 003_create_rate_limits.sql
├─ tests/
│  ├─ unit/
│  │  ├─ services/
│  │  │  ├─ booking.service.test.ts
│  │  │  ├─ queue.service.test.ts
│  │  │  └─ payment.service.test.ts
│  │  └─ utils/
│  ├─ integration/
│  │  ├─ booking.integration.test.ts
│  │  └─ queue.integration.test.ts
│  └─ fixtures/
│     └─ test-data.ts
├─ docs/
│  ├─ API.md                    (OpenAPI/Swagger)
│  ├─ ARCHITECTURE.md
│  └─ DEPLOYMENT.md
├─ .env.example
├─ .env.local (git-ignored)
├─ Dockerfile
├─ docker-compose.yml
├─ package.json
├─ tsconfig.json
├─ jest.config.js
└─ README.md
```

---

## 4. Data Migration Strategy

### **Phase 1: Parallel Running (Week 1-2)**
Both Firestore (client) and Backend (API) write to Firestore simultaneously.

```
┌────────────┐
│ Flutter    │
│ Booking    │──┐
│ Create     │  │
└────────────┘  │
                ├──> Firestore (bookings collection)
┌────────────┐  │
│ Backend    │──┘
│ Booking    │
│ Create     │
└────────────┘
```

**Implementation:**
1. Deploy backend (read-only initially, no writes)
2. Update Flutter app to call backend API (but ignore response, keep using Firestore)
3. Validate backend logic matches Firestore behavior
4. Run consistency checks (compare counts, sample data)

### **Phase 2: Gradual Cutover (Week 2-3)**
Enable backend writes in canary fashion.

```
10% of users → New backend writes
├─ Monitor for errors (logs, errors, latency)
└─ If good: expand to 50% → 100%
```

**Implementation:**
1. Add feature flag: `USE_BACKEND_FOR_BOOKINGS`
2. Canary 10% of users to backend writes
3. Monitor metrics (error rate, latency, duplication)
4. Expand gradually: 25% → 50% → 100%
5. Validate consistency (Firestore vs PostgreSQL audit logs)

### **Phase 3: Cleanup (Week 4)**
Retire old client-side code once backend is stable.

```
├─ Remove Firestore writes from BookingService
├─ Remove deprecated provider methods
├─ Archive barberQueue collection (don't delete)
├─ Update unit tests to use API mocks
└─ Deploy new Flutter version
```

---

## 5. API Versioning & Deprecation Strategy

### **Versioning Scheme**
- **URL-based:** `/api/v1/`, `/api/v2/` (recommended)
- **Header-based:** `API-Version: 2` (alternative)

### **Deprecation Timeline**
```
Day 1:  Launch v2 API alongside v1
Week 1: Announce deprecation of v1 (email to developers)
Week 4: Stop issuing new auth tokens for v1 clients
Week 8: v1 becomes read-only (no writes)
Week 12: v1 shut down
```

---

## 6. Testing Strategy for Backend

### **Unit Tests (Services)**
- Token generation atomicity
- Queue ordering logic
- Earnings calculation
- Permission checks

### **Integration Tests (API)**
- Booking creation workflow
- Queue updates via WebSocket
- Auth token refresh
- Rate limiting

### **Contract Tests (Frontend ↔ Backend)**
- API responses match expected schema
- Error codes and messages
- Field names and types

### **Load Tests**
- 1000 concurrent users booking
- 10,000 queue updates/second
- Notification delivery under load

---

## 7. Monitoring & Observability

### **Metrics to Track**
- API endpoint latency (p50, p95, p99)
- Error rates by endpoint
- Booking creation success rate
- Queue update latency
- WebSocket connection count

### **Logs to Collect**
- All API requests (method, path, status, latency)
- Authentication failures
- Business logic errors (token generation, queue conflicts)
- Database query performance
- WebSocket events

### **Alerts to Set Up**
- 5xx error rate > 1%
- API latency p99 > 1000ms
- Database connection pool exhaustion
- Disk space > 80%
- Firestore quota exceeded

---

## 8. Deployment Architecture

### **Development Environment**
```
┌─────────────────────────────────────┐
│ Developer Laptop                    │
├─────────────────────────────────────┤
│ Docker Compose:                     │
│ ├─ Backend API (Node.js)            │
│ ├─ Firestore Emulator               │
│ ├─ PostgreSQL (local)               │
│ ├─ Redis (local)                    │
│ └─ MockGoogleSignIn                 │
├─────────────────────────────────────┤
│ .env.local (git-ignored)            │
│ DATABASE_URL=localhost:5432         │
│ FIREBASE_PROJECT_ID=emu-project    │
└─────────────────────────────────────┘
```

**Commands:**
```bash
docker-compose up -d              # Start all services
npm run dev                        # Start Node server
npm test                           # Run tests
npm run migrate                    # Run migrations
```

### **Staging Environment**
- Cloud Run for backend
- Firestore (test project)
- PostgreSQL on Cloud SQL
- Redis on Memorystore

### **Production Environment**
- Cloud Run (auto-scaling)
- Firestore (production)
- PostgreSQL on Cloud SQL with HA
- Redis on Memorystore (replicated)
- Cloud Armor + Cloud CDN
- Cloud Logging + Sentry

---

## 9. Cost Estimates

| Component | Estimate | Notes |
|-----------|----------|-------|
| Cloud Run (backend) | $50–200/month | Depends on traffic |
| PostgreSQL | $100–300/month | db-f1-micro (dev) → db-g1-small (prod) |
| Redis | $20–100/month | dev: 1GB, prod: 5GB |
| Firestore | ~$50–200/month | Read/write operations |
| **Total** | **$220–800/month** | Varies with scale |

---

## 10. Implementation Checklist

### **Week 1: Backend Setup & Authentication**
- [ ] Create backend repository (Node.js + TypeScript + Express)
- [ ] Set up PostgreSQL migrations
- [ ] Implement Auth service (JWT generation, refresh)
- [ ] Unit tests for Auth service
- [ ] Deploy to Cloud Run (staging)

### **Week 2: Booking & Queue Services**
- [ ] Implement BookingService (token generation, create, update)
- [ ] Implement QueueService (queue state, ordering)
- [ ] Add integration tests
- [ ] WebSocket handlers for real-time updates
- [ ] Deploy to Cloud Run (staging)

### **Week 3: Flutter API Refactor**
- [ ] Create API client classes (AuthApi, BookingApi, QueueApi)
- [ ] Update providers to use API clients
- [ ] Update UI screens to work with new providers
- [ ] Unit tests for API clients (mock HTTP)
- [ ] Widget tests (updated to mock APIs)

### **Week 4: Testing & Canary Rollout**
- [ ] E2E tests (barber + customer flow)
- [ ] Load tests on backend
- [ ] Deploy backend to production
- [ ] Feature flag: gradual rollout (10% → 100%)
- [ ] Monitoring & alerting configured

### **Week 5: Cleanup & Deprecation**
- [ ] Remove deprecated Firestore writes from Flutter
- [ ] Archive barberQueue collection
- [ ] Finalize migration (audit logs, backups)
- [ ] Documentation updated
- [ ] Team training

---

## 11. Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking change in API | Medium | High | Versioning, contract tests, staged rollout |
| Booking duplication | Low | High | Transaction consistency, duplicate detection |
| Data loss during migration | Very Low | Critical | Backup before migration, dry-run first |
| Backend downtime | Low | High | High availability (multiple replicas), fallback to read-only |
| Performance regression | Medium | Medium | Load tests before release, monitoring |

---

## 12. Success Criteria

- ✅ Backend API handles 1000 concurrent users
- ✅ Booking creation latency < 500ms
- ✅ Queue updates delivered within 1 second
- ✅ 99.9% API uptime
- ✅ Zero data loss or duplication during migration
- ✅ All existing functionality preserved
- ✅ Audit logs complete and queryable
- ✅ Team comfortable maintaining new architecture

---

## Next Steps

1. **Review this plan** and provide feedback
2. **Choose tech stack** (Node.js + Express or Python + FastAPI)
3. **Approve folder structures** and naming conventions
4. **Schedule kickoff meeting** with team
5. **Create project repository** (backend)
6. **Begin Week 1 implementation** (Auth service)

---

**Document prepared by:** AI Assistant  
**Date:** December 8, 2025  
**Status:** ⏳ **Awaiting User Confirmation**
