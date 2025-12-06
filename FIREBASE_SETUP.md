# Firebase Configuration Setup

## ✅ Current Firebase Integration Status

### Firebase Dependencies (pubspec.yaml)
- ✅ `firebase_core: ^2.24.0`
- ✅ `firebase_auth: ^4.15.0`
- ✅ `cloud_firestore: ^4.17.5`
- ✅ `firebase_storage: ^11.6.0`
- ✅ `firebase_messaging: ^14.7.0`
- ✅ `google_sign_in: ^6.2.0`

### Firebase Initialization (main.dart)
- ✅ `Firebase.initializeApp()` called with `DefaultFirebaseOptions.currentPlatform`
- ✅ Error handling in place for initialization failures

### Firebase Configuration Files
- ✅ `lib/firebase_options.dart` - Contains platform-specific Firebase credentials
- ✅ `android/app/google-services.json` - Android Firebase configuration
- ⚠️ `ios/Runner/GoogleService-Info.plist` - Needs verification/creation

### Firebase Services Integration
- ✅ **AuthService** (`lib/services/auth_service.dart`)
  - Google Sign-In implemented
  - Email/Password authentication implemented
  - Phone number authentication available
  
- ✅ **BarberService** (`lib/services/barber_service.dart`)
  - Firestore connection via `FirebaseFirestore.instance`
  - CRUD operations for barber shops
  - Real-time streams implemented
  
- ✅ **BookingService** (`lib/services/booking_service.dart`)
  - Firestore bookings collection
  - Atomic transactions for token generation
  - Queue management in Firestore
  
- ✅ **UserService** (`lib/services/user_service.dart`)
  - User profile management in Firestore
  - Role-based data storage

## 🔧 Firebase Projects Connected

### Project 1: "book-your-barber" (Web)
- Project ID: `book-your-barber-cd1f8`
- Region: Firebase hosting enabled
- Auth: Google Sign-In configured

### Project 2: "barber-pro" (Android)
- Project ID: `barber-pro-20d4b`
- Package: `com.example.barberpro`
- Android API Key configured

## 📋 Firestore Collections Structure

```
barbers/ (Barber shops)
├── shopName
├── ownerEmail
├── phone
├── address
├── isOnline
├── rating
├── services[] (array of Service objects)
└── queue[] (array of booking entries)

bookings/ (Customer bookings)
├── customerId
├── barberId
├── tokenNumber
├── services[]
├── status (waiting, in_progress, completed, cancelled)
├── bookingTime
└── estimatedWaitTime

users/ (User profiles)
├── email
├── name
├── phone
├── userType (customer/barber/admin)
├── photoUrl
└── preferences{}

barber_income/ (Earnings tracking)
├── barberId
├── totalEarnings
├── dailyEarnings
└── bookingsCompleted
```

## 🚀 How to Verify Firebase Connection

### 1. **Check Firebase Initialization**
```dart
// In main.dart, Firebase is initialized:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 2. **Test Authentication Flow**
- Launch app → Login Screen → Google Sign-In
- User should authenticate via Firebase Auth
- User record created in Firestore `users/` collection

### 3. **Test Firestore Operations**
- Navigate to Barber Management (barber flavor)
- Add a new barber
- Verify barber appears in `barbers/` collection in Firebase Console

### 4. **Test Real-time Streams**
- Create a booking
- Queue updates should flow in real-time via:
  - `BookingService.getBarberQueueStream()`
  - `BarberService.getBarberStream()`

### 5. **Monitor Firebase Console**
- Go to https://console.firebase.google.com
- Select project: "barber-pro-20d4b"
- Monitor:
  - Authentication → Sign-in method (Google enabled?)
  - Firestore Database → Collections
  - Storage → Upload test images

## ⚙️ Firebase Emulator Setup (Optional for Local Development)

To use Firebase Emulator Suite for local testing:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulator
firebase emulators:start

# In Flutter, connect to emulator:
# (Uncomment in main.dart when testing locally)
# await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
# FirebaseFirestore.instance.settings = const Settings(
#   host: 'localhost:8080',
#   sslEnabled: false,
#   persistenceEnabled: false,
# );
```

## 🔐 Security Rules (Firestore)

Recommended rules to set in Firebase Console:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Barbers collection - readable by all, writable by barber owner
    match /barbers/{barberId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.ownerId;
    }
    
    // Bookings - readable by involved parties
    match /bookings/{bookingId} {
      allow read: if request.auth.uid == resource.data.customerId || 
                     request.auth.uid == resource.data.barberId;
      allow create: if request.auth.uid == request.resource.data.customerId;
    }
  }
}
```

## 📦 Next Steps

1. ✅ Firebase already initialized
2. ✅ Services already connected
3. ⏳ Set Firestore security rules in Firebase Console
4. ⏳ Download and add `GoogleService-Info.plist` for iOS
5. ⏳ Test authentication and data persistence
6. ⏳ Enable Analytics in Firebase Console (optional)

## 🐛 Troubleshooting

### Issue: "MissingPluginException" for Firebase
**Solution:** Run `flutter pub get` and rebuild the app

### Issue: "Platform not initialized" in BarberService
**Solution:** Ensure `Firebase.initializeApp()` completes before providers initialize

### Issue: Firestore queries return empty
**Solution:** Check Firestore security rules allow read access

### Issue: Google Sign-In fails
**Solution:** Verify SHA-1 certificate hash in `android/app/google-services.json` matches your local keystore

---

**Last Updated:** December 3, 2025
**Firebase Projects:** 2 connected (Web + Android)
**Status:** ✅ Ready for production testing
