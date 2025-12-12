import 'package:flutter_test/flutter_test.dart';
import 'package:barber_pro_multi_barber/config/app_constants.dart';

/// Test to verify the booking display fix constants are properly defined.
/// This test does NOT require Firebase initialization.
void main() {
  group('Booking Display Fix - Constants Validation', () {
    test('AppConstants has bookingsCollection set to "bookings"', () {
      // Verify that AppConstants has the correct collection name
      expect(AppConstants.bookingsCollection, equals('bookings'));
    });

    test('AppConstants has correct booking status values', () {
      // Verify that AppConstants has the correct status values
      expect(AppConstants.bookingStatusWaiting, equals('waiting'));
      expect(AppConstants.bookingStatusNext, equals('next'));
      expect(AppConstants.bookingStatusServing, equals('serving'));
      expect(AppConstants.bookingStatusCompleted, equals('completed'));
      expect(AppConstants.bookingStatusCancelled, equals('cancelled'));
      expect(AppConstants.bookingStatusSkipped, equals('skipped'));
    });

    test('Booking status constants are not empty', () {
      // Ensure constants are properly defined
      expect(AppConstants.bookingsCollection.isNotEmpty, true);
      expect(AppConstants.bookingStatusWaiting.isNotEmpty, true);
      expect(AppConstants.bookingStatusNext.isNotEmpty, true);
      expect(AppConstants.bookingStatusServing.isNotEmpty, true);
      expect(AppConstants.bookingStatusCompleted.isNotEmpty, true);
      expect(AppConstants.bookingStatusCancelled.isNotEmpty, true);
      expect(AppConstants.bookingStatusSkipped.isNotEmpty, true);
    });

    test('Booking status values are distinct', () {
      final statuses = {
        AppConstants.bookingStatusWaiting,
        AppConstants.bookingStatusNext,
        AppConstants.bookingStatusServing,
        AppConstants.bookingStatusCompleted,
        AppConstants.bookingStatusCancelled,
        AppConstants.bookingStatusSkipped,
      };
      expect(statuses.length, equals(6)); // All should be unique
    });

    test('bookingsCollection used instead of deprecated barberQueue', () {
      expect(AppConstants.bookingsCollection, 'bookings');
      expect(AppConstants.bookingsCollection, isNot('barberQueue'));
    });
  });
}
