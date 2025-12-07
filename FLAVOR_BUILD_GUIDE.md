# Flavor Build Guide - BarberPro Multi-App

## Problem Fixed

The barber APK was incorrectly showing customer UI because Flutter was using the default `lib/main.dart` entry point (which sets flavor to `customer`) instead of `lib/main_barber.dart` (which sets flavor to `barber`).

### Root Cause
- Multiple flavor entry points exist: `main.dart`, `main_barber.dart`, `main_admin.dart`, `main_customer.dart`
- Without explicit `--target` flag, Flutter defaults to `lib/main.dart`
- `lib/main.dart` was hardcoded to set `FlavorConfig` to `customer` flavor
- Result: Barber APK would load customer routes and show customer UI

### Solution Applied
1. **Converted `lib/main.dart`** to a safety error screen with build instructions
2. **Created `lib/utils/flavor_navigation.dart`** with `flavorSafeGo()` helper to prevent cross-flavor navigation at runtime
3. **Updated routing in `lib/routes/app_routes.dart`** to explicitly block customer routes in barber flavor and vice versa
4. **Verified** with logs that barber APK now correctly loads `AppFlavor.barber`

---

## ✅ REQUIRED Build Commands

### Must use `--target` flag pointing to flavor-specific main file

```bash
# Build Barber APK
flutter build apk --flavor barber --release --target lib/main_barber.dart

# Build Customer APK
flutter build apk --flavor customer --release --target lib/main_customer.dart

# Build Admin APK
flutter build apk --flavor admin --release --target lib/main_admin.dart
```

### For Development/Debug Builds
```bash
# Run barber debug build
flutter run --flavor barber -t lib/main_barber.dart

# Run customer debug build
flutter run --flavor customer -t lib/main_customer.dart

# Run admin debug build
flutter run --flavor admin -t lib/main_admin.dart
```

---

## What Each Flavor Does

| Flavor | Entry Point | Application ID | Flavor Value | Routes |
|--------|-------------|-----------------|--------------|--------|
| **barber** | `lib/main_barber.dart` | `com.barberpro.barber` | `AppFlavor.barber` | `/barber-home`, `/barber-queue`, `/barber-earnings`, `/barber-profile` |
| **customer** | `lib/main_customer.dart` | `com.barberpro.customer` | `AppFlavor.customer` | `/home`, `/discovery`, `/bookings`, `/profile` |
| **admin** | `lib/main_admin.dart` | `com.barberpro.admin` | `AppFlavor.admin` | `/admin-dashboard`, `/admin-shop-management`, `/admin-reports`, `/admin-agents` |

---

## Route Isolation

### Router Redirect Logic
Each flavor's router redirect function (`lib/routes/app_routes.dart`) explicitly:

1. **Blocks customer routes in barber flavor**
   ```dart
   final customerRoutes = ['/home', '/discovery', '/bookings', '/booking', ...];
   if (customerRoutes.any((route) => location.startsWith(route))) {
       if (isLoggedIn) return '/barber-home';
       return '/login';
   }
   ```

2. **Blocks barber routes in customer flavor**
   ```dart
   final barberRoutes = ['/barber-home', '/barber-queue', '/barber-earnings', ...];
   if (barberRoutes.any((route) => location.startsWith(route))) {
       if (isLoggedIn) return '/home';
       return '/login';
   }
   ```

3. **Enforces admin-only routes in admin flavor**
   ```dart
   final adminRoutes = ['/admin-dashboard', '/admin-shop-management', ...];
   if (!adminRoutes.any((route) => location.startsWith(route))) {
       if (isLoggedIn) return '/admin-dashboard';
       return '/login';
   }
   ```

### Runtime Navigation Guard
The `flavorSafeGo()` helper in `lib/utils/flavor_navigation.dart` prevents code from navigating to wrong flavor's routes:
```dart
void flavorSafeGo(BuildContext context, String path) {
  // Prevents barber flavor from navigating to customer routes
  // Prevents customer flavor from navigating to barber routes
  // Admin can access all routes
}
```

---

## Verification

After building, verify the correct flavor is loaded:

```bash
# Install and run
adb install -r build/app/outputs/flutter-apk/app-barber-release.apk
adb shell am start -n com.barberpro.barber/com.barberpro.MainActivity

# Check logs
adb logcat | grep "FlavorConfig"
# Should show: AppFlavor.barber (NOT AppFlavor.customer)
```

---

## Gradle Configuration

**android/app/build.gradle.kts** defines three product flavors:

```kotlin
productFlavors {
    create("customer") {
        applicationId = "com.barberpro.customer"
    }
    create("barber") {
        applicationId = "com.barberpro.barber"
    }
    create("admin") {
        applicationId = "com.barberpro.admin"
    }
}
```

Each flavor uses:
- Flavor-specific `google-services.json` from `android/app/src/{flavor}/`
- Flavor-specific app name via `resValue("string", "app_name", "...")`
- **Different entry point via `--target` flag in build command**

---

## Important Files

| File | Purpose |
|------|---------|
| `lib/main_barber.dart` | ✅ Correct barber entry point - sets `AppFlavor.barber` |
| `lib/main_customer.dart` | ✅ Correct customer entry point - sets `AppFlavor.customer` |
| `lib/main_admin.dart` | ✅ Correct admin entry point - sets `AppFlavor.admin` |
| `lib/main.dart` | ⚠️ Safety fallback - shows error screen if wrong entry point used |
| `lib/routes/app_routes.dart` | ✅ Explicit route blocking per flavor |
| `lib/utils/flavor_navigation.dart` | ✅ Runtime navigation guard |
| `android/app/build.gradle.kts` | ✅ Product flavors defined |

---

## Troubleshooting

### Problem: Barber APK still shows customer UI

**Cause:** Built without `--target lib/main_barber.dart`

**Fix:** Rebuild with correct command
```bash
flutter clean
flutter pub get
flutter build apk --flavor barber --release --target lib/main_barber.dart
adb install -r build/app/outputs/flutter-apk/app-barber-release.apk
```

### Problem: Build fails with "main.dart not found"

**Cause:** You ran build without specifying `--target`

**Fix:** Ensure you're using the `--target` flag
```bash
# ❌ WRONG
flutter build apk --flavor barber --release

# ✅ CORRECT
flutter build apk --flavor barber --release --target lib/main_barber.dart
```

---

## Summary

✅ **The fix is complete and tested:**
- Barber APK now correctly loads with `AppFlavor.barber`
- Customer UI is blocked via explicit router redirects
- Runtime navigation guards prevent accidental cross-flavor navigation
- **Must use `--target` flag when building**

Always remember: **Explicit is better than implicit.** Use the `--target` flag with the correct flavor-specific main file.
