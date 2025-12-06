import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import '../models/index.dart';

/// Firestore Booking Service for managing bookings
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  static final Uuid _uuid = Uuid();

  /// Create a new booking with atomic token generation
  /// Uses transaction to ensure consistency
  Future<String> createBooking(
    String customerId,
    String barberId,
    List<Service> services,
    int estimatedWaitTime,
  ) async {
    try {
      _logger.i('Creating booking for customer: $customerId at barber: $barberId');

      final bookingId = _uuid.v4();
      final now = DateTime.now();
      final totalPrice =
          services.fold<double>(0, (total, service) => total + service.price);

      // Use transaction for atomicity with token generation
      await _firestore.runTransaction((transaction) async {
        // Get barber reference and current token
        final barberRef =
            _firestore.collection(AppConstants.barbersCollection).doc(barberId);
        final barberSnapshot = await transaction.get(barberRef);

        if (!barberSnapshot.exists) {
          throw Exception('Barber not found');
        }

        final currentToken =
            (barberSnapshot['currentToken'] as int?) ?? 0;
        final newToken = currentToken + 1;

        // Create booking with generated token
        final booking = Booking(
          bookingId: bookingId,
          customerId: customerId,
          barberId: barberId,
          tokenNumber: newToken,
          services: services,
          totalPrice: totalPrice,
          status: AppConstants.bookingStatusWaiting,
          paymentMethod: AppConstants.paymentMethodCash,
          paymentStatus: AppConstants.paymentStatusPending,
          bookingTime: now,
          estimatedWaitTime: estimatedWaitTime,
        );

        // Add booking to bookings collection
        transaction.set(
          _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId),
          booking.toFirestore(),
        );

        // Update barber's currentToken and queue
        transaction.update(barberRef, {
          'currentToken': newToken,
          'queue': FieldValue.arrayUnion([
            {
              'bookingId': bookingId,
              'tokenNumber': newToken,
              'customerId': customerId,
              'status': AppConstants.bookingStatusWaiting,
            }
          ]),
          'queueLength': FieldValue.increment(1),
        });

        _logger.i('Booking created successfully with token: $newToken');
      });

      return bookingId;
    } catch (e) {
      _logger.e('Error creating booking: $e');
      rethrow;
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      _logger.i('Fetching booking: $bookingId');

      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        _logger.w('Booking $bookingId not found');
        return null;
      }

      _logger.i('Booking $bookingId fetched successfully');
      return Booking.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching booking: $e');
      rethrow;
    }
  }

  /// Get booking stream (for real-time updates)
  Stream<Booking?> getBookingStream(String bookingId) {
    _logger.i('Listening to booking stream: $bookingId');

    return _firestore
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        _logger.w('Booking $bookingId not found in stream');
        return null;
      }
      return Booking.fromFirestore(doc);
    }).handleError((error) {
      _logger.e('Error in booking stream: $error');
    });
  }

  /// Get customer's bookings
  Future<List<Booking>> getCustomerBookings(String customerId) async {
    try {
      _logger.i('Fetching bookings for customer: $customerId');

      final querySnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('bookingTime', descending: true)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${bookings.length} bookings for customer');
      return bookings;
    } catch (e) {
      _logger.e('Error fetching customer bookings: $e');
      rethrow;
    }
  }

  /// Get barber's bookings for a specific date
  Future<List<Booking>> getBarberBookingsByDate(
    String barberId,
    DateTime date,
  ) async {
    try {
      _logger.i('Fetching bookings for barber: $barberId on date: $date');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('barberId', isEqualTo: barberId)
          .where('bookingTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('bookingTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('bookingTime', descending: false)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${bookings.length} bookings for barber on date');
      return bookings;
    } catch (e) {
      _logger.e('Error fetching barber bookings by date: $e');
      rethrow;
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    String newStatus,
  ) async {
    try {
      _logger.i('Updating booking $bookingId status to: $newStatus');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': newStatus,
      });

      _logger.i('Booking status updated successfully');
    } catch (e) {
      _logger.e('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Update estimated wait time
  Future<void> updateEstimatedWaitTime(
    String bookingId,
    int estimatedWaitTime,
  ) async {
    try {
      _logger.i('Updating booking $bookingId wait time to: $estimatedWaitTime minutes');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'estimatedWaitTime': estimatedWaitTime,
      });

      _logger.i('Estimated wait time updated');
    } catch (e) {
      _logger.e('Error updating estimated wait time: $e');
      rethrow;
    }
  }

  /// Complete booking
  Future<void> completeBooking(
    String bookingId, {
    int? actualServiceTime,
  }) async {
    try {
      _logger.i('Completing booking: $bookingId');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': AppConstants.bookingStatusCompleted,
        'paymentStatus': AppConstants.paymentStatusCompleted,
        'completionTime': Timestamp.now(),
        'actualServiceTime': actualServiceTime,
      });

      _logger.i('Booking completed successfully');
    } catch (e) {
      _logger.e('Error completing booking: $e');
      rethrow;
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(
    String bookingId, {
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      _logger.i('Cancelling booking: $bookingId by $cancelledBy');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': AppConstants.bookingStatusCancelled,
        'cancelledBy': cancelledBy,
        'cancellationReason': cancellationReason,
        'completionTime': Timestamp.now(),
      });

      _logger.i('Booking cancelled successfully');
    } catch (e) {
      _logger.e('Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Skip booking (5-minute auto-skip)
  Future<void> skipBooking(String bookingId) async {
    try {
      _logger.i('Skipping booking: $bookingId');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': AppConstants.bookingStatusSkipped,
        'completionTime': Timestamp.now(),
      });

      _logger.i('Booking skipped successfully');
    } catch (e) {
      _logger.e('Error skipping booking: $e');
      rethrow;
    }
  }

  /// Add rating and review to booking
  Future<void> addRatingAndReview(
    String bookingId,
    double rating,
    String review,
  ) async {
    try {
      _logger.i('Adding rating $rating and review to booking: $bookingId');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'rating': rating,
        'review': review,
      });

      _logger.i('Rating and review added successfully');
    } catch (e) {
      _logger.e('Error adding rating and review: $e');
      rethrow;
    }
  }

  /// Get completed bookings for a barber (for earnings calculation)
  Future<List<Booking>> getCompletedBookingsForPeriod(
    String barberId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _logger.i(
        'Fetching completed bookings for barber: $barberId from $startDate to $endDate',
      );

      final querySnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('barberId', isEqualTo: barberId)
          .where('status', isEqualTo: AppConstants.bookingStatusCompleted)
          .where('completionTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completionTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('completionTime', descending: true)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${bookings.length} completed bookings for period');
      return bookings;
    } catch (e) {
      _logger.e('Error fetching completed bookings: $e');
      rethrow;
    }
  }

  /// Delete booking (admin only)
  Future<void> deleteBooking(String bookingId) async {
    try {
      _logger.i('Deleting booking: $bookingId');

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .delete();

      _logger.i('Booking deleted successfully');
    } catch (e) {
      _logger.e('Error deleting booking: $e');
      rethrow;
    }
  }

  /// Get queue for a barber (active bookings)
  Stream<List<Booking>> getBarberQueueStream(String barberId) {
    _logger.i('Listening to queue stream for barber: $barberId');

    return _firestore
        .collection(AppConstants.bookingsCollection)
        .where('barberId', isEqualTo: barberId)
        .where('status',
            whereIn: [
              AppConstants.bookingStatusWaiting,
              AppConstants.bookingStatusNext,
              AppConstants.bookingStatusServing,
            ])
        .orderBy('bookingTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList())
        .handleError((error) {
      _logger.e('Error in queue stream: $error');
    });
  }
}
