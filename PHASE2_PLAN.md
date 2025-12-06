# Phase 2: UI Implementation Plan
**Status:** In Progress  
**Goal:** Build complete user-facing mobile UI with real-time features, navigation, and polished user experience.

---

## 📋 Overview
Phase 2 focuses on implementing all Flutter screens, navigation, widgets, and integrating real-time Firestore listeners with user interaction flows.

### Key Features to Implement
1. **Authentication UI** — Login, Signup, Password Reset
2. **Barber Discovery & Home** — Browse services, view barber profiles, real-time availability
3. **Booking Flow** — Select barber, service, time slot, confirm booking
4. **Queue Management** — Real-time queue view, booking status, wait time estimates
5. **Profile & Settings** — User profile, app preferences, notification settings
6. **Navigation** — Bottom navigation (Customer) / Tab navigation (Barber), deep linking support
7. **Real-time Updates** — Firestore listeners for queue, bookings, availability
8. **Notifications** — Push notifications for booking confirmations, queue updates
9. **Analytics** — Event tracking for key user actions

---

## 🏗️ Project Structure (Phase 2)
```
lib/
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── splash_screen.dart
│   ├── customer/
│   │   ├── home_screen.dart
│   │   ├── discovery_screen.dart
│   │   ├── booking_screen.dart
│   │   ├── queue_screen.dart
│   │   ├── booking_details_screen.dart
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart
│   ├── barber/
│   │   ├── barber_home_screen.dart
│   │   ├── barber_availability_screen.dart
│   │   ├── queue_management_screen.dart
│   │   ├── barber_profile_screen.dart
│   │   └── barber_settings_screen.dart
│   └── app_shell.dart (Navigation wrapper)
├── widgets/
│   ├── booking_card.dart
│   ├── queue_item.dart
│   ├── service_tile.dart
│   ├── barber_card.dart
│   ├── time_slot_selector.dart
│   ├── booking_timeline.dart
│   ├── custom_app_bar.dart
│   ├── loading_indicator.dart
│   └── error_dialog.dart
├── routes/
│   └── app_routes.dart (GoRouter configuration)
├── config/
│   ├── app_theme.dart (already exists)
│   └── app_constants.dart (already exists)
├── models/ (already done in Phase 1)
├── services/ (already done in Phase 1)
├── providers/ (already done in Phase 1)
└── main.dart (update with routing)
```

---

## 📱 Screen Specifications

### 1. Authentication Screens
**login_screen.dart**
- Email & password input with validation
- "Forgot Password?" link → forgot_password_screen
- "Don't have an account?" → signup_screen
- Sign-in button with loading state
- Integration: AuthService, AuthProvider

**signup_screen.dart**
- User type selection (Customer / Barber)
- Email, password, name input
- Terms & conditions checkbox
- Sign-up button
- "Already have an account?" → login_screen

**forgot_password_screen.dart**
- Email input
- Send reset link button
- Confirmation message

**splash_screen.dart**
- App logo animation
- Check auth state → route to home/login

---

### 2. Customer Screens

**home_screen.dart** (Customer main screen after login)
- Greeting message ("Hi, [Name]!")
- Quick booking card (CTA: "Book Now")
- Recent bookings list
- Featured barbers carousel
- Quick stats (upcoming bookings, completed services)

**discovery_screen.dart**
- Search bar (search by barber name, service)
- Filter: service type, rating, distance, availability
- BarberCard list with:
  - Barber image, name, rating
  - Services offered
  - "View Profile" → barber profile
  - "Book Now" → booking_screen

**booking_screen.dart**
- Step-based UI (Barber → Service → Time → Confirm)
- Barber profile mini-view
- Service selection with pricing
- Time slot selector (real-time availability)
- Booking summary & confirm button

**queue_screen.dart**
- Real-time queue visualization (position in queue)
- Estimated wait time
- Current barber info
- Live queue timeline
- Cancel booking option

**booking_details_screen.dart**
- Full booking details (date, time, barber, service, price)
- QR code for check-in
- Cancel / Reschedule buttons
- Chat with barber (optional Phase 2.5)

**profile_screen.dart**
- User avatar, name, email, phone
- Booking history
- Favorites (saved barbers)
- Edit profile button
- Logout button

**settings_screen.dart**
- Notifications toggle
- App theme (light/dark)
- Language selection
- Privacy settings
- About & Version

---

### 3. Barber Screens

**barber_home_screen.dart**
- Barber status toggle (Online / Offline)
- Today's bookings timeline
- Queue overview (waiting customers)
- Quick actions: mark complete, call next, manage availability

**barber_availability_screen.dart**
- Weekly availability calendar
- Set working hours
- Block time slots
- Manage services and pricing

**queue_management_screen.dart**
- Real-time queue list
- Mark customer as "Called", "In Progress", "Completed"
- Estimated processing time per customer
- Customer contact info

**barber_profile_screen.dart**
- Profile photo & bio
- Services & pricing
- Rating & reviews
- Edit profile

**barber_settings_screen.dart**
- Notifications
- Payment method
- Salon info
- App preferences

---

## 🔀 Navigation Structure (GoRouter)

```
/ (root)
├── /splash
├── /login
├── /signup
├── /forgot-password
├── /home (customer/barber - determined by user type)
│   ├── /discovery
│   ├── /booking/:barberId
│   ├── /queue/:bookingId
│   ├── /booking-details/:bookingId
│   ├── /profile
│   ├── /settings
│   └── /edit-profile
├── /barber-home (barber only)
│   ├── /availability
│   ├── /queue-management
│   ├── /barber-profile
│   └── /barber-settings
```

---

## 🔗 Integration Points

### Real-time Features
1. **Queue Updates** — Firestore listener on `bookings` collection with `status = "queued"`
2. **Booking Changes** — Listen to user's bookings, update UI on any field change
3. **Barber Availability** — Real-time availability slots based on bookings & manual blocks
4. **Notifications** — FCM (Firebase Cloud Messaging) for booking confirmations, queue updates

### State Management (Provider)
- **AuthProvider** — Auth state, user role (Customer/Barber)
- **BarberProvider** — Fetched barber list, filters
- **BookingProvider** — Current booking, booking history, queue position
- **UIProvider** (new) — Loading states, error messages, navigation events

### Data Flow
1. User logs in → AuthService validates → AuthProvider updates state
2. Customer browses barbers → BarberProvider fetches from Firestore
3. Customer creates booking → BookingService inserts to Firestore → BookingProvider listens
4. Queue updates via Firestore listeners → UI re-renders in real-time
5. Firebase Cloud Functions (backend) trigger notifications on booking changes

---

## 📦 Dependencies (Already Installed)
- `go_router` (if not installed, will add)
- `provider` ✅
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging` ✅
- `image_picker`, `cached_network_image` ✅
- `intl` (for date formatting)
- `uuid` ✅

---

## 🎨 Design Guidelines

### Theme
- **Primary Color:** Blue (#1E88E5)
- **Secondary Color:** Teal (#00ACC1)
- **Accent Color:** Orange (#FF6F00)
- **Background:** Light Gray (#F5F5F5)
- **Text:** Dark Gray (#333333)

### Typography
- **Headlines:** 24sp, Bold
- **Body Text:** 16sp, Regular
- **Captions:** 12sp, Light

### Components
- Rounded corners (8dp radius)
- Shadows for elevation
- Consistent padding (16dp standard)
- Loading spinners, error messages, empty states

---

## ✅ Phase 2 Milestone Checklist

- [ ] GoRouter setup & navigation working
- [ ] Auth screens (Login, Signup, Splash) implemented & tested
- [ ] Customer home & discovery screens implemented
- [ ] Booking flow screens implemented
- [ ] Queue real-time updates working
- [ ] Profile & settings screens implemented
- [ ] Barber screens implemented (MVP)
- [ ] Reusable widgets created & tested
- [ ] Push notifications integrated
- [ ] Analytics events added
- [ ] Widget tests passing (>80% coverage)
- [ ] UI polished & responsive on multiple device sizes
- [ ] Ready for Phase 3 (Backend Cloud Functions, Advanced Features)

---

## 🚀 Next Immediate Steps

1. **Set up GoRouter** in `routes/app_routes.dart` with all routes
2. **Create app_shell.dart** with BottomNavigationBar structure
3. **Implement splash_screen.dart** → Auto-route based on auth state
4. **Implement login_screen.dart** → Core auth flow
5. **Create reusable widgets** in `lib/widgets/`

**Estimated Duration:** 2-3 weeks for full Phase 2 implementation

---

**Version:** 1.0  
**Date:** Dec 1, 2025  
**Author:** AI Assistant
