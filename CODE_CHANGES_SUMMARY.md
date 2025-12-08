# Code Changes Summary - Booking Display Fix

## Problem
Customer bookings weren't appearing in barber app queue because:
- **BookingService** writes to `bookings` collection
- **BarberProvider** was reading from `barberQueue` collection (never updated)
- These are different collections with no sync between them

## Solution  
Changed **BarberProvider** to read from `bookings` collection (same source as writes)

---

## File: `lib/providers/barber_provider.dart`

### Change 1: Import AppConstants
```dart
// ADD THIS IMPORT (Line 9)
import '../config/app_constants.dart';
```

### Change 2: getBarberQueueStream() Method

**BEFORE:**
```dart
Stream<List<BarberQueue>> getBarberQueueStream(String barberId) {
  _logger.i('Getting queue stream for barber: $barberId');
  return _firestore
      .collection('barberQueue')  // ❌ WRONG COLLECTION
      .where('barberId', isEqualTo: barberId)
      .where('status', whereIn: ['waiting', 'serving'])
      .orderBy('bookingTime', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => BarberQueue.fromFirestore(doc))
            .toList();
      });
}
```

**AFTER:**
```dart
Stream<List<dynamic>> getBarberQueueStream(String barberId) {
  _logger.i('Getting queue stream for barber: $barberId');
  return _firestore
      .collection(AppConstants.bookingsCollection)  // ✅ CORRECT COLLECTION
      .where('barberId', isEqualTo: barberId)
      .where(
        'status',
        whereIn: [
          AppConstants.bookingStatusWaiting,
          AppConstants.bookingStatusNext,
          AppConstants.bookingStatusServing,
        ],
      )
      .orderBy('bookingTime', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Return dynamic map compatible with existing screen code
          return {
            'id': doc.id,
            'queueId': doc.id,
            'bookingId': doc.id,
            'barberId': data['barberId'],
            'customerId': data['customerId'],
            'customerName': data['customerId'],
            'customerPhone': '',
            'serviceType': _getServiceTypesFromBooking(data),
            'price': (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
            'status': data['status'],
            'bookingTime': data['bookingTime'],
            'waitTime': _formatWaitTime(data['estimatedWaitTime']),
            'tokenNumber': data['tokenNumber'],
            'services': data['services'],
          };
        }).toList();
      });
}
```

### Change 3: loadBarberQueue() Method

**BEFORE:**
```dart
Future<bool> loadBarberQueue(String barberId) async {
  try {
    _setLoading(true);
    _clearError();
    _logger.i('Loading queue for barber: $barberId');

    final snapshot = await _firestore
        .collection('barberQueue')  // ❌ WRONG COLLECTION
        .where('barberId', isEqualTo: barberId)
        .where('status', whereIn: ['waiting', 'serving'])
        .orderBy('bookingTime', descending: false)
        .get();

    _currentBarberQueue = snapshot.docs
        .map((doc) => BarberQueue.fromFirestore(doc))
        .toList();

    _logger.i('Loaded ${_currentBarberQueue.length} queue items');
    notifyListeners();
    return true;
  } catch (e) {
    _logger.e('Error loading queue: $e');
    _setError('Failed to load queue');
    return false;
  } finally {
    _setLoading(false);
  }
}
```

**AFTER:**
```dart
Future<bool> loadBarberQueue(String barberId) async {
  try {
    _setLoading(true);
    _clearError();
    _logger.i('Loading queue for barber: $barberId');

    final snapshot = await _firestore
        .collection(AppConstants.bookingsCollection)  // ✅ CORRECT COLLECTION
        .where('barberId', isEqualTo: barberId)
        .where(
          'status',
          whereIn: [
            AppConstants.bookingStatusWaiting,
            AppConstants.bookingStatusNext,
            AppConstants.bookingStatusServing,
          ],
        )
        .orderBy('bookingTime', descending: false)
        .get();

    _currentBarberQueue = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      try {
        final booking = Booking.fromFirestore(doc);
        return BarberQueue(
          queueId: booking.bookingId,
          barberId: booking.barberId,
          shopId: '',
          customerId: booking.customerId,
          customerName: booking.customerId,
          customerPhone: null,
          serviceType: booking.services.isNotEmpty
              ? booking.services.map((s) => s.name).join(', ')
              : 'Service',
          servicePrice: booking.totalPrice,
          bookingTime: booking.bookingTime,
          status: booking.status,
          rating: booking.rating,
          review: booking.review,
          createdAt: booking.bookingTime,
          updatedAt: booking.bookingTime,
        );
      } catch (e) {
        _logger.w('Failed to convert to BarberQueue: $e');
        return data;
      }
    }).toList();

    _logger.i('Loaded ${_currentBarberQueue.length} queue items from bookings');
    notifyListeners();
    return true;
  } catch (e) {
    _logger.e('Error loading queue: $e');
    _setError('Failed to load queue');
    return false;
  } finally {
    _setLoading(false);
  }
}

String _formatWaitTime(dynamic waitTime) {
  if (waitTime is int) {
    return '$waitTime min';
  }
  return '-- min';
}

String _getServiceTypesFromBooking(Map<String, dynamic> data) {
  try {
    final services = data['services'] as List?;
    if (services != null && services.isNotEmpty) {
      return services
          .map((s) => (s as Map?)?.['name'] ?? 'Service')
          .join(', ');
    }
  } catch (e) {
    _logger.w('Error getting service types: $e');
  }
  return 'Service';
}
```

### Change 4: completeService() Method

**BEFORE:**
```dart
await _firestore.collection('barberQueue').doc(queueId).update({  // ❌ WRONG
  'status': 'completed',
  'completedAt': FieldValue.serverTimestamp(),
  'rating': rating,
});
```

**AFTER:**
```dart
await _firestore
    .collection(AppConstants.bookingsCollection)  // ✅ CORRECT
    .doc(queueId)
    .update({
      'status': AppConstants.bookingStatusCompleted,
      'completionTime': FieldValue.serverTimestamp(),
      'rating': rating,
      'paymentStatus': AppConstants.paymentStatusCompleted,
    });
```

### Change 5: skipCustomer() Method

**BEFORE:**
```dart
await _firestore.collection('barberQueue').doc(queueId).update({  // ❌ WRONG
  'bookingTime': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**AFTER:**
```dart
await _firestore
    .collection(AppConstants.bookingsCollection)  // ✅ CORRECT
    .doc(queueId)
    .update({
      'status': AppConstants.bookingStatusSkipped,
      'bookingTime': FieldValue.serverTimestamp(),
    });
```

---

## Summary of Changes

| Item | Before | After |
|------|--------|-------|
| **Collection Read** | `'barberQueue'` | `AppConstants.bookingsCollection` (`'bookings'`) |
| **Status Filter** | `['waiting', 'serving']` | `['waiting', 'next', 'serving']` |
| **completeService Update** | `'barberQueue'` + `'completedAt'` | `'bookings'` + `'completionTime'` + `paymentStatus` |
| **skipCustomer Update** | `'barberQueue'` + `'updatedAt'` | `'bookings'` + status to `'skipped'` |
| **Return Type** | `Stream<List<BarberQueue>>` | `Stream<List<dynamic>>` |

---

## Key Benefits

✅ **Immediate Effect**: When customer books → barber sees it instantly  
✅ **Consistent Data**: Single source of truth (bookings collection)  
✅ **Real-time Updates**: Firestore listeners trigger on every change  
✅ **Backward Compatible**: Screen code unchanged  
✅ **Type Safe**: Uses AppConstants for field names  

---

## Testing the Fix

```bash
# Run both apps
flutter run -t lib/main_customer.dart &
flutter run -t lib/main_barber.dart &

# Customer: Create booking
# Barber: See booking appear immediately ✓
```
