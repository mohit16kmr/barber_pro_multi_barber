import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../config/app_constants.dart';
import '../models/index.dart';

/// Firestore Barber Service for managing barber shops and services
class BarberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Create a new barber shop with optional agent ID validation
  /// If agentId is provided:
  /// - Validates agent exists and is active
  /// - Ensures shop is not already registered with this agent
  /// - Registers shop to agent's list
  /// If agentId is null, creates shop without agent assignment
  Future<String> createBarberWithAgent({
    required Barber barber,
    String? referralCode,
  }) async {
    try {
      _logger.i('Creating barber shop with referralCode=$referralCode, shopName=${barber.shopName}');

      // Validate agent if provided
      if (referralCode != null && referralCode.isNotEmpty) {
        _logger.i('Validating referral code: $referralCode');

        // Check if agent exists
        final agentDoc = await _firestore
          .collection(AppConstants.agentsCollection)
          .doc(referralCode)
          .get();

        if (!agentDoc.exists) {
          throw Exception('Agent not found with code/id: $referralCode');
        }

        final agentData = agentDoc.data() as Map<String, dynamic>;
        final isActive = agentData['isActive'] as bool? ?? true;

        if (!isActive) {
          throw Exception('Agent is inactive and cannot register shops');
        }

        _logger.i('Agent validation successful: $referralCode');
      }

      // Create barber with referral code
      final barberWithAgent = barber.copyWith(referralCode: referralCode);

      final docRef = await _firestore
          .collection(AppConstants.barbersCollection)
          .add(barberWithAgent.toFirestore());

      final createdBarberId = docRef.id;

      // If agent ID provided, register shop to agent
      if (referralCode != null && referralCode.isNotEmpty) {
        _logger.i('Registering shop $createdBarberId to agent/referral $referralCode');

        await _firestore
            .collection(AppConstants.agentsCollection)
            .doc(referralCode)
            .update({
              'shopIds': FieldValue.arrayUnion([createdBarberId]),
              'shopsCount': FieldValue.increment(1),
              'updatedAt': Timestamp.now(),
            });

        _logger.i('Shop registered to agent/referral. Code: $referralCode, Shop: $createdBarberId');
      }

      _logger.i('Barber shop created with ID: $createdBarberId, referralCode: $referralCode');
      return createdBarberId;
    } catch (e) {
      _logger.e('Error creating barber with agent: $e');
      rethrow;
    }
  }

  /// Create a new barber shop (original method)
  Future<String> createBarber(Barber barber) async {
    try {
      _logger.i('Creating barber shop: ${barber.shopName}');

      final docRef = await _firestore
          .collection(AppConstants.barbersCollection)
          .add(barber.toFirestore());

      _logger.i('Barber shop created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating barber: $e');
      rethrow;
    }
  }

  /// Get barber by ID
  Future<Barber?> getBarberById(String barberId) async {
    try {
      _logger.i('Fetching barber: $barberId');

      final doc = await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        _logger.w('Barber $barberId not found');
        return null;
      }

      _logger.i('Barber $barberId fetched successfully');
      return Barber.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching barber: $e');
      rethrow;
    }
  }

  /// Get barber stream (for real-time updates)
  Stream<Barber?> getBarberStream(String barberId) {
    _logger.i('Listening to barber stream: $barberId');

    return _firestore
        .collection(AppConstants.barbersCollection)
        .doc(barberId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        _logger.w('Barber $barberId not found in stream');
        return null;
      }
      return Barber.fromFirestore(doc);
    }).handleError((error) {
      _logger.e('Error in barber stream: $error');
    });
  }

  /// Get all barbers
  /// Note: onlineOnly parameter allows filtering by online status if needed.
  /// Default is false to show all registered barbers.
  Future<List<Barber>> getAllBarbers({bool onlineOnly = false}) async {
    try {
      _logger.i('Fetching all barbers (onlineOnly: $onlineOnly)');

      Query query =
          _firestore.collection(AppConstants.barbersCollection);

      // Only filter by online status if explicitly requested
      if (onlineOnly) {
        query = query.where('isOnline', isEqualTo: true);
      }

      final querySnapshot = await query.get();

      final barbers = querySnapshot.docs
          .map((doc) => Barber.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${barbers.length} barbers (onlineOnly=$onlineOnly)');
      return barbers;
    } catch (e) {
      _logger.e('Error fetching barbers: $e');
      rethrow;
    }
  }

  /// Get barbers by referral code
  Future<List<Barber>> getBarbersByReferralCode(String referralCode) async {
    try {
      _logger.i('Fetching barbers for referralCode: $referralCode');

      final querySnapshot = await _firestore
          .collection(AppConstants.barbersCollection)
          .where('referralCode', isEqualTo: referralCode)
          .get();

      final barbers = querySnapshot.docs
          .map((doc) => Barber.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${barbers.length} barbers for referralCode $referralCode');
      return barbers;
    } catch (e) {
      _logger.e('Error fetching barbers by referralCode: $e');
      rethrow;
    }
  }

  /// Update barber shop information
  Future<void> updateBarber(String barberId, Barber barber) async {
    try {
      _logger.i('Updating barber: $barberId');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .set(barber.toFirestore(), SetOptions(merge: true));

      _logger.i('Barber $barberId updated successfully');
    } catch (e) {
      _logger.e('Error updating barber: $e');
      rethrow;
    }
  }

  /// Update barber online status
  Future<void> setBarberOnlineStatus(String barberId, bool isOnline) async {
    try {
      _logger.i('Setting barber $barberId online status to: $isOnline');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'isOnline': isOnline,
      });

      _logger.i('Barber online status updated');
    } catch (e) {
      _logger.e('Error updating barber online status: $e');
      rethrow;
    }
  }

  /// CRITICAL: Generate token number atomically using transactions
  /// This ensures no duplicate tokens are generated
  Future<int> generateTokenNumber(String barberId) async {
    try {
      _logger.i('Generating token number for barber: $barberId');

      // Use a transaction to ensure atomicity
      final token = await _firestore.runTransaction((transaction) async {
        final barberRef =
            _firestore.collection(AppConstants.barbersCollection).doc(barberId);
        final barberSnapshot = await transaction.get(barberRef);

        if (!barberSnapshot.exists) {
          throw Exception('Barber not found');
        }

        final currentToken = barberSnapshot['currentToken'] as int? ?? 0;
        final newToken = currentToken + 1;

        // Update the current token in the transaction
        transaction.update(barberRef, {'currentToken': newToken});

        _logger.i('Generated token: $newToken for barber $barberId');
        return newToken;
      });

      return token;
    } catch (e) {
      _logger.e('Error generating token: $e');
      rethrow;
    }
  }

  /// Reset daily token counter (should be run at midnight)
  Future<void> resetDailyTokenCounter(String barberId) async {
    try {
      _logger.i('Resetting daily token counter for barber: $barberId');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'currentToken': 0,
        'queue': [],
        'queueLength': 0,
      });

      _logger.i('Daily token counter reset for barber $barberId');
    } catch (e) {
      _logger.e('Error resetting daily token counter: $e');
      rethrow;
    }
  }

  /// Add booking to queue
  Future<void> addToQueue(String barberId, Map<String, dynamic> booking) async {
    try {
      _logger.i('Adding booking to queue for barber: $barberId');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'queue': FieldValue.arrayUnion([booking]),
        'queueLength': FieldValue.increment(1),
      });

      _logger.i('Booking added to queue');
    } catch (e) {
      _logger.e('Error adding to queue: $e');
      rethrow;
    }
  }

  /// Remove booking from queue
  Future<void> removeFromQueue(String barberId, Map<String, dynamic> booking) async {
    try {
      _logger.i('Removing booking from queue for barber: $barberId');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'queue': FieldValue.arrayRemove([booking]),
        'queueLength': FieldValue.increment(-1),
      });

      _logger.i('Booking removed from queue');
    } catch (e) {
      _logger.e('Error removing from queue: $e');
      rethrow;
    }
  }

  /// Update barber rating
  Future<void> updateBarberRating(String barberId, double rating) async {
    try {
      _logger.i('Updating barber rating: $barberId to $rating');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'rating': rating,
      });

      _logger.i('Barber rating updated');
    } catch (e) {
      _logger.e('Error updating barber rating: $e');
      rethrow;
    }
  }

  /// Update barber earnings
  Future<void> updateBarberEarnings(String barberId, double amount) async {
    try {
      _logger.i('Updating barber earnings: $barberId by $amount');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .update({
        'totalEarnings': FieldValue.increment(amount),
      });

      _logger.i('Barber earnings updated');
    } catch (e) {
      _logger.e('Error updating barber earnings: $e');
      rethrow;
    }
  }

  /// Search barbers by location
  Future<List<Barber>> searchBarbersByLocation(String location) async {
    try {
      _logger.i('Searching barbers by location: $location');

      final querySnapshot = await _firestore
          .collection(AppConstants.barbersCollection)
          .where('verified', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .get();

      // Filter locally by location (since Firestore doesn't support complex queries for location dropdowns)
      final barbers = querySnapshot.docs
          .map((doc) => Barber.fromFirestore(doc))
          .toList();

      _logger.i('Found ${barbers.length} barbers in location $location');
      return barbers;
    } catch (e) {
      _logger.e('Error searching barbers by location: $e');
      rethrow;
    }
  }

  /// Delete barber
  Future<void> deleteBarber(String barberId) async {
    try {
      _logger.i('Deleting barber: $barberId');

      await _firestore
          .collection(AppConstants.barbersCollection)
          .doc(barberId)
          .delete();

      _logger.i('Barber $barberId deleted successfully');
    } catch (e) {
      _logger.e('Error deleting barber: $e');
      rethrow;
    }
  }

  /// Get barbers sorted by least busy (lowest queue length)
  Future<List<Barber>> getLeastBusyBarbers({int limit = 5}) async {
    try {
      _logger.i('Fetching least busy barbers (limit: $limit)');

      final querySnapshot = await _firestore
          .collection(AppConstants.barbersCollection)
          .where('isOnline', isEqualTo: true)
          .where('verified', isEqualTo: true)
          .orderBy('queueLength', descending: false)
          .limit(limit)
          .get();

      final barbers = querySnapshot.docs
          .map((doc) => Barber.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${barbers.length} least busy barbers');
      return barbers;
    } catch (e) {
      _logger.e('Error fetching least busy barbers: $e');
      rethrow;
    }
  }

  /// Get top rated barbers
  Future<List<Barber>> getTopRatedBarbers({int limit = 5}) async {
    try {
      _logger.i('Fetching top rated barbers (limit: $limit)');

      final querySnapshot = await _firestore
          .collection(AppConstants.barbersCollection)
          .where('isOnline', isEqualTo: true)
          .where('verified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      final barbers = querySnapshot.docs
          .map((doc) => Barber.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${barbers.length} top rated barbers');
      return barbers;
    } catch (e) {
      _logger.e('Error fetching top rated barbers: $e');
      rethrow;
    }
  }
}
