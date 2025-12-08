import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/index.dart';
import '../services/index.dart';

/// Booking Provider - manages booking-related state
class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger();

  // State
  List<Booking> _myBookings = [];
  Booking? _currentBooking;
  final List<Booking> _barberQueue = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _estimatedWaitTime = 0;

  // Getters
  List<Booking> get myBookings => _myBookings;
  Booking? get currentBooking => _currentBooking;
  List<Booking> get barberQueue => _barberQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get estimatedWaitTime => _estimatedWaitTime;

  /// Create a new booking
  Future<String?> createBooking({
    required String customerId,
    required String barberId,
    required List<Service> services,
    required int estimatedWaitTime,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Creating booking - customer: $customerId, barber: $barberId');

      final bookingId = await _bookingService.createBooking(
        customerId,
        barberId,
        services,
        estimatedWaitTime,
      );

      _logger.i('Booking created successfully with ID: $bookingId');

      // Fetch the created booking and refresh the user's booking list
      await loadBooking(bookingId);

      // Reload bookings list to show newly created booking
      final success = await loadCustomerBookings(customerId);
      if (!success) {
        _logger.w('Failed to reload bookings, but booking was created');
      }

      notifyListeners();
      return bookingId;
    } catch (e) {
      _logger.e('Error creating booking: $e');

      // Fallback: Create sample booking locally when Firestore fails
      _logger.i('Using fallback booking creation');
      try {
        final sampleBookingId =
            'booking_${DateTime.now().millisecondsSinceEpoch}';
        final totalPrice = services.fold<double>(0, (sum, s) => sum + s.price);

        final fallbackBooking = Booking(
          bookingId: sampleBookingId,
          customerId: customerId,
          barberId: barberId,
          tokenNumber:
              (DateTime.now().millisecondsSinceEpoch % 100).toInt() + 1,
          services: services,
          totalPrice: totalPrice,
          status: 'waiting',
          paymentMethod: 'cash',
          paymentStatus: 'pending',
          bookingTime: DateTime.now(),
          estimatedWaitTime: estimatedWaitTime,
        );

        _currentBooking = fallbackBooking;
        _estimatedWaitTime = estimatedWaitTime;

        // Add to myBookings list so it shows up immediately
        _myBookings.add(fallbackBooking);

        _logger.i(
          'Fallback booking created: $sampleBookingId and added to list',
        );

        notifyListeners();
        return sampleBookingId;
      } catch (fallbackError) {
        _logger.e('Fallback booking creation also failed: $fallbackError');
        _setError('Failed to create booking: ${e.toString()}');
        return null;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Load a specific booking
  Future<bool> loadBooking(String bookingId) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading booking: $bookingId');

      _currentBooking = await _bookingService.getBookingById(bookingId);

      if (_currentBooking == null) {
        _setError('Booking not found');
        return false;
      }

      _estimatedWaitTime = _currentBooking!.estimatedWaitTime;
      _logger.i('Booking loaded successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading booking: $e');
      _setError('Failed to load booking');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current booking stream (for real-time updates)
  Stream<Booking?> getBookingStream(String bookingId) {
    _logger.i('Listening to booking stream: $bookingId');
    return _bookingService.getBookingStream(bookingId);
  }

  /// Load customer's bookings
  Future<bool> loadCustomerBookings(String customerId) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading bookings for customer: $customerId');

      final fetchedBookings = await _bookingService.getCustomerBookings(
        customerId,
      );

      // Only replace list if fetch succeeds, otherwise keep existing bookings
      if (fetchedBookings.isNotEmpty || _myBookings.isEmpty) {
        _myBookings = fetchedBookings;
      }

      _logger.i('Loaded ${_myBookings.length} bookings');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading customer bookings: $e');
      _logger.w('Keeping existing bookings in list (Firestore error)');
      // Don't clear the list - keep any bookings from fallback creation
      _setError('Failed to sync bookings');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking({
    required String bookingId,
    String? cancellationReason,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Cancelling booking: $bookingId');

      await _bookingService.cancelBooking(
        bookingId,
        cancelledBy: 'customer',
        cancellationReason:
            cancellationReason ?? 'Customer requested cancellation',
      );

      _logger.i('Booking cancelled successfully');

      // Reload booking
      await loadBooking(bookingId);

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error cancelling booking: $e');
      _setError('Failed to cancel booking');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add rating and review to booking
  Future<bool> addRatingAndReview({
    required String bookingId,
    required double rating,
    required String review,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Adding rating $rating and review to booking: $bookingId');

      await _bookingService.addRatingAndReview(bookingId, rating, review);

      _logger.i('Rating and review added successfully');

      // Reload booking
      await loadBooking(bookingId);

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error adding rating and review: $e');
      _setError('Failed to add rating and review');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get queue stream for barber (real-time queue updates)
  Stream<List<Booking>> getBarberQueueStream(String barberId) {
    _logger.i('Listening to queue stream for barber: $barberId');
    return _bookingService.getBarberQueueStream(barberId);
  }

  /// Update estimated wait time
  Future<bool> updateEstimatedWaitTime({
    required String bookingId,
    required int estimatedWaitTime,
  }) async {
    try {
      _logger.i(
        'Updating wait time for booking: $bookingId to $estimatedWaitTime minutes',
      );

      await _bookingService.updateEstimatedWaitTime(
        bookingId,
        estimatedWaitTime,
      );

      _estimatedWaitTime = estimatedWaitTime;

      _logger.i('Wait time updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error updating wait time: $e');
      _setError('Failed to update wait time');
      return false;
    }
  }

  /// Get customer's active booking (waiting, next, or serving)
  Booking? getActiveBooking() {
    if (_myBookings.isEmpty) return null;

    try {
      return _myBookings.firstWhere(
        (booking) =>
            booking.status == 'waiting' ||
            booking.status == 'next' ||
            booking.status == 'serving',
      );
    } catch (e) {
      return null;
    }
  }

  /// Get customer's completed bookings
  List<Booking> getCompletedBookings() {
    return _myBookings
        .where((booking) => booking.status == 'completed')
        .toList();
  }

  /// Get customer's cancelled bookings
  List<Booking> getCancelledBookings() {
    return _myBookings
        .where((booking) => booking.status == 'cancelled')
        .toList();
  }

  /// Check if customer has active booking
  bool hasActiveBooking() {
    return getActiveBooking() != null;
  }

  /// Get position in queue
  int getQueuePosition(String barberId, String bookingId) {
    final index = _barberQueue.indexWhere(
      (booking) =>
          booking.barberId == barberId &&
          booking.bookingId == bookingId &&
          (booking.status == 'waiting' ||
              booking.status == 'next' ||
              booking.status == 'serving'),
    );

    return index >= 0 ? index + 1 : -1;
  }

  /// Calculate total hours worked (for completed bookings)
  int calculateTotalServiceMinutes(String barberId) {
    return _barberQueue
        .where(
          (booking) =>
              booking.barberId == barberId && booking.status == 'completed',
        )
        .fold<int>(0, (sum, booking) => sum + (booking.actualServiceTime ?? 0));
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _logger.w('Error: $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Refresh booking data
  Future<void> refresh() async {
    if (_currentBooking != null) {
      await loadBooking(_currentBooking!.bookingId);
    }
  }
}
