import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import '../models/barber_queue.dart';
import '../models/barber_income.dart';
import '../models/barber_shift.dart';
import '../services/index.dart';
import '../config/app_constants.dart';

/// Barber Provider - manages barber-related state
class BarberProvider extends ChangeNotifier {
  final BarberService _barberService = BarberService();
  final Logger _logger = Logger();

  // State
  List<Barber> _allBarbers = [];
  List<Barber> _filteredBarbers = [];
  Barber? _selectedBarber;
  List<Barber> _favoriteBarbers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'all'; // all, least-busy, top-rated

  // Queue & Earnings state
  List<dynamic> _currentBarberQueue = [];
  BarberIncome? _currentBarberIncome;
  BarberShift? _currentBarberShift;
  final Map<String, BarberIncome> _allBarberIncomes =
      {}; // shopId -> list of incomes
  bool _isBarberOnline = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  List<Barber> get allBarbers => _allBarbers;
  List<Barber> get filteredBarbers => _filteredBarbers;
  Barber? get selectedBarber => _selectedBarber;
  List<Barber> get favoriteBarbers => _favoriteBarbers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  // Queue & Earnings getters
  List<dynamic> get currentBarberQueue => _currentBarberQueue;
  BarberIncome? get currentBarberIncome => _currentBarberIncome;
  BarberShift? get currentBarberShift => _currentBarberShift;
  Map<String, BarberIncome> get allBarberIncomes => _allBarberIncomes;
  bool get isBarberOnline => _isBarberOnline;

  /// Load all barbers
  /// Note: Loads all barbers regardless of online status.
  /// Customers can see all registered barbers and check their status.
  /// Uses simple method to fetch directly from users collection.
  /// Has 10-second timeout to prevent app hanging.
  Future<bool> loadAllBarbers() async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading all barbers');

      // Use simple method that queries users collection directly
      // With timeout protection
      final Future<List<Barber>> barbersFuture = _barberService
          .getAllBarbersSimple();
      _allBarbers = await barbersFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w('Barber loading timed out after 10s');
          _setError('Barber loading took too long');
          return [];
        },
      );
      _filteredBarbers = _allBarbers;

      _logger.i('Loaded ${_allBarbers.length} barbers');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading barbers: $e');
      _setError('Failed to load barbers');
      _allBarbers = [];
      _filteredBarbers = [];
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load least busy barbers
  Future<bool> loadLeastBusyBarbers({int limit = 5}) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading least busy barbers');

      _currentFilter = 'least-busy';
      _filteredBarbers = await _barberService.getLeastBusyBarbers(limit: limit);

      _logger.i('Loaded ${_filteredBarbers.length} least busy barbers');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading least busy barbers: $e');
      _setError('Failed to load least busy barbers');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load top rated barbers
  Future<bool> loadTopRatedBarbers({int limit = 5}) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading top rated barbers');

      _currentFilter = 'top-rated';
      _filteredBarbers = await _barberService.getTopRatedBarbers(limit: limit);

      _logger.i('Loaded ${_filteredBarbers.length} top rated barbers');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading top rated barbers: $e');
      _setError('Failed to load top rated barbers');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load barbers by location
  Future<bool> loadBarbersByLocation(String location) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading barbers for location: $location');

      _filteredBarbers = await _barberService.searchBarbersByLocation(location);

      _logger.i('Loaded ${_filteredBarbers.length} barbers in location');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading barbers by location: $e');
      _setError('Failed to load barbers for this location');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Select a barber to view details
  void selectBarber(Barber barber) {
    _selectedBarber = barber;
    _logger.i('Selected barber: ${barber.shopName}');
    notifyListeners();
  }

  /// Clear selected barber
  void clearSelectedBarber() {
    _selectedBarber = null;
    _logger.i('Cleared selected barber');
    notifyListeners();
  }

  /// Search barbers by name
  void searchBarbersByName(String query) {
    _logger.i('Searching barbers with query: $query');

    if (query.isEmpty) {
      _filteredBarbers = _allBarbers;
    } else {
      _filteredBarbers = _allBarbers
          .where(
            (barber) =>
                barber.shopName.toLowerCase().contains(query.toLowerCase()) ||
                barber.ownerName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    _logger.i('Found ${_filteredBarbers.length} matching barbers');
    notifyListeners();
  }

  /// Sort barbers by queue length (least busy first)
  void sortByQueueLength() {
    _currentFilter = 'least-busy';
    _filteredBarbers.sort((a, b) => a.queueLength.compareTo(b.queueLength));
    _logger.i('Sorted barbers by queue length');
    notifyListeners();
  }

  /// Sort barbers by rating (highest first)
  void sortByRating() {
    _currentFilter = 'top-rated';
    _filteredBarbers.sort((a, b) => b.rating.compareTo(a.rating));
    _logger.i('Sorted barbers by rating');
    notifyListeners();
  }

  /// Sort barbers by name (A-Z)
  void sortByName() {
    _filteredBarbers.sort((a, b) => a.shopName.compareTo(b.shopName));
    _logger.i('Sorted barbers by name');
    notifyListeners();
  }

  /// Get barber details with real-time updates
  Stream<Barber?> getBarberStream(String barberId) {
    _logger.i('Getting barber stream for: $barberId');
    return _barberService.getBarberStream(barberId);
  }

  /// Toggle favorite barber status (handled by AuthProvider, but can refresh list)
  void updateFavoriteBarbers(List<String> favoriteIds) {
    _favoriteBarbers = _allBarbers
        .where((barber) => favoriteIds.contains(barber.barberId))
        .toList();
    _logger.i('Updated favorite barbers list');
    notifyListeners();
  }

  /// Get barber by ID
  Future<Barber?> getBarberById(String barberId) async {
    try {
      _logger.i('Fetching barber: $barberId');
      final fromBarbers = await _barberService.getBarberById(barberId);
      if (fromBarbers != null) return fromBarbers;

      // Fallback: some barbers may be stored in `users/{id}`
      final fromUsers = await _barberService.getBarberFromUsersById(barberId);
      if (fromUsers != null) {
        _logger.i('Barber found in users collection as fallback: $barberId');
        return fromUsers;
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching barber: $e');
      return null;
    }
  }

  /// Add a new barber to the shop
  /// Returns the created barber document ID on success, or null on failure
  Future<String?> addBarber({
    required String name,
    required String phone,
    String? address,
    String? shopId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Adding new barber: $name');

      final barber = Barber(
        barberId: '',
        shopName: '',
        shopId: shopId,
        ownerName: name,
        phone: phone,
        address: address ?? '',
        createdAt: DateTime.now(),
      );

      final id = await _barberService.createBarber(barber);

      // Refresh local list
      await loadAllBarbers();

      _logger.i('Barber added with id: $id');
      return id;
    } catch (e) {
      _logger.e('Error adding barber: $e');
      _setError('Failed to add barber');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get average rating from completed bookings
  double getBarberAverageRating(Barber barber) {
    // This would be calculated from bookings in BookingService
    return barber.rating;
  }

  /// Check if barber is on break
  bool isBarberOnBreak(Barber barber) {
    final now = DateTime.now();
    for (final breakTime in barber.breakTimes) {
      final start = DateTime.parse(breakTime['startTime'] as String);
      final end = DateTime.parse(breakTime['endTime'] as String);
      if (now.isAfter(start) && now.isBefore(end)) {
        return true;
      }
    }
    return false;
  }

  /// Check if barber is on holiday
  bool isBarberOnHoliday(Barber barber) {
    final today = DateTime.now();
    return barber.holidays.any(
      (holiday) =>
          holiday.year == today.year &&
          holiday.month == today.month &&
          holiday.day == today.day,
    );
  }

  // ==================== Queue & Earnings Methods ====================

  /// Get current barber's queue (real-time stream)
  /// Now reads from 'bookings' collection (single source of truth)
  Stream<List<dynamic>> getBarberQueueStream(String barberId) {
    _logger.i('Getting queue stream for barber: $barberId');
    return _firestore
        .collection(AppConstants.bookingsCollection)
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
            final data = doc.data();
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

  /// Load barber's current queue (one-time fetch)
  /// Now reads from 'bookings' collection (single source of truth)
  Future<bool> loadBarberQueue(String barberId) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading queue for barber: $barberId');

      final snapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
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
        final data = doc.data();
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

  /// Helper: Format estimated wait time
  String _formatWaitTime(dynamic waitTime) {
    if (waitTime is int) {
      return '$waitTime min';
    }
    return '-- min';
  }

  /// Helper: Get service types from booking services list
  String _getServiceTypesFromBooking(dynamic data) {
    try {
      final services = (data is Map && data.containsKey('services')) ? data['services'] : null;
      if (services is List && services.isNotEmpty) {
        return services.map((s) {
          if (s is Map && s.containsKey('name')) {
            final name = s['name'];
            return name != null ? name.toString() : 'Service';
          }
          return 'Service';
        }).join(', ');
      }
    } catch (e) {
      _logger.w('Error getting service types: $e');
    }
    return 'Service';
  }

  /// Get barber's earnings for a specific period
  Future<BarberIncome?> getBarberIncome(String barberId, DateTime date) async {
    try {
      _logger.i('Fetching income for barber: $barberId on $date');

      final snapshot = await _firestore
          .collection('barberIncome')
          .where('barberId', isEqualTo: barberId)
          .where(
            'date',
            isEqualTo: DateTime(date.year, date.month, date.day).toString(),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _logger.w('No income record found for barber: $barberId');
        return null;
      }

      _currentBarberIncome = BarberIncome.fromFirestore(snapshot.docs.first);
      notifyListeners();
      return _currentBarberIncome;
    } catch (e) {
      _logger.e('Error fetching income: $e');
      return null;
    }
  }

  /// Get all barbers' earnings for a shop (for dashboard)
  Future<bool> loadShopEarnings(String shopId) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Loading earnings for shop: $shopId');

      final snapshot = await _firestore
          .collection('barberIncome')
          .where('shopId', isEqualTo: shopId)
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      _allBarberIncomes.clear();
      for (var doc in snapshot.docs) {
        final income = BarberIncome.fromFirestore(doc);
        _allBarberIncomes[income.barberId] = income;
      }

      _logger.i('Loaded earnings for ${_allBarberIncomes.length} barbers');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error loading shop earnings: $e');
      _setError('Failed to load earnings');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get barber's earnings stream (real-time)
  Stream<BarberIncome?> getBarberIncomeStream(String barberId, DateTime date) {
    _logger.i('Getting income stream for barber: $barberId');
    return _firestore
        .collection('barberIncome')
        .where('barberId', isEqualTo: barberId)
        .where(
          'date',
          isEqualTo: DateTime(date.year, date.month, date.day).toString(),
        )
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return BarberIncome.fromFirestore(snapshot.docs.first);
        });
  }

  /// Get barber's shift status
  Future<BarberShift?> getBarberShift(String barberId) async {
    try {
      _logger.i('Fetching shift for barber: $barberId');

      // Get today's shift
      final today = DateTime.now();
      final snapshot = await _firestore
          .collection('barberShift')
          .where('barberId', isEqualTo: barberId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: DateTime(
              today.year,
              today.month,
              today.day,
            ).toString(),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _logger.w('No active shift for barber: $barberId');
        return null;
      }

      _currentBarberShift = BarberShift.fromFirestore(snapshot.docs.first);
      _isBarberOnline = _currentBarberShift?.isOnline ?? false;
      notifyListeners();
      return _currentBarberShift;
    } catch (e) {
      _logger.e('Error fetching shift: $e');
      return null;
    }
  }

  /// Toggle barber online/offline status
  Future<bool> toggleBarberOnlineStatus(String barberId, bool isOnline) async {
    try {
      _logger.i('Toggling barber online status: $isOnline');

      if (_currentBarberShift == null) {
        _logger.w('No active shift to update');
        return false;
      }

      await _firestore
          .collection('barberShift')
          .doc(_currentBarberShift!.shiftId)
          .update({
            'isOnline': isOnline,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _isBarberOnline = isOnline;
      _currentBarberShift = _currentBarberShift!.copyWith(isOnline: isOnline);
      notifyListeners();

      _logger.i('Updated barber online status to: $isOnline');
      return true;
    } catch (e) {
      _logger.e('Error updating online status: $e');
      _setError('Failed to update status');
      return false;
    }
  }

  /// Complete a service (update queue and earnings)
  Future<bool> completeService(
    String queueId,
    double amount,
    double rating,
  ) async {
    try {
      _logger.i('Completing service: $queueId');

      // Update booking item in bookings collection
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(queueId)
          .update({
            'status': AppConstants.bookingStatusCompleted,
            'completionTime': FieldValue.serverTimestamp(),
            'rating': rating,
            'paymentStatus': AppConstants.paymentStatusCompleted,
          });

      // Update shift earnings
      if (_currentBarberShift != null) {
        final newEarnings = (_currentBarberShift!.totalEarnings) + amount;
        final newCount = (_currentBarberShift!.totalCustomersServed) + 1;

        await _firestore
            .collection('barberShift')
            .doc(_currentBarberShift!.shiftId)
            .update({
              'totalEarnings': newEarnings,
              'totalCustomersServed': newCount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Reload queue
      if (_currentBarberShift != null) {
        await loadBarberQueue(_currentBarberShift!.barberId);
      }

      _logger.i('Service completed successfully');
      return true;
    } catch (e) {
      _logger.e('Error completing service: $e');
      _setError('Failed to complete service');
      return false;
    }
  }

  /// Skip a customer in queue (move to end)
  Future<bool> skipCustomer(String queueId) async {
    try {
      _logger.i('Skipping customer in queue: $queueId');

      // Update booking to skipped status
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(queueId)
          .update({
            'status': AppConstants.bookingStatusSkipped,
            'bookingTime': FieldValue.serverTimestamp(),
          });

      // Reload queue
      if (_currentBarberShift != null) {
        await loadBarberQueue(_currentBarberShift!.barberId);
      }

      _logger.i('Customer skipped');
      return true;
    } catch (e) {
      _logger.e('Error skipping customer: $e');
      _setError('Failed to skip customer');
      return false;
    }
  }

  /// Calculate total shop earnings from all barbers
  double calculateTotalShopEarnings() {
    double total = 0;
    for (var income in _allBarberIncomes.values) {
      total += income.dailyEarnings;
    }
    return total;
  }

  /// Calculate average earnings per barber
  double calculateAverageBarberEarnings() {
    if (_allBarberIncomes.isEmpty) return 0;
    final total = calculateTotalShopEarnings();
    return total / _allBarberIncomes.length;
  }

  /// Get top performing barber
  String? getTopPerformingBarber() {
    if (_allBarberIncomes.isEmpty) return null;
    var topBarber = _allBarberIncomes.entries.first;
    for (var entry in _allBarberIncomes.entries) {
      if ((entry.value.dailyEarnings) > (topBarber.value.dailyEarnings)) {
        topBarber = entry;
      }
    }
    return topBarber.key;
  }

  // ==================== End Queue & Earnings Methods ====================

  void _setLoading(bool value) {
    _isLoading = value;
    // Defer notifications until after the current frame to avoid
    // "setState() called during build" when this is invoked from initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  void _setError(String message) {
    _errorMessage = message;
    _logger.w('Error: $message');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  void _clearError() {
    _errorMessage = null;
  }
}
