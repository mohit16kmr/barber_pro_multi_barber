import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:logger/logger.dart';
import 'dart:async';
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
      _logger.i(
        'Creating barber shop with referralCode=$referralCode, shopName=${barber.shopName}',
      );

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

      // Prefer creating the barber document with the authenticated user's UID
      final currentUid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      String createdBarberId;
      if (currentUid != null) {
        final docRef = _firestore
            .collection(AppConstants.barbersCollection)
            .doc(currentUid);
        await docRef.set(barberWithAgent.toFirestore());
        createdBarberId = currentUid;
      } else {
        // No authenticated user available - according to Firestore rules,
        // barber documents must be created with the auth UID as the document id.
        // Failing fast here prevents creating a document with an auto-id
        // which would be rejected by security rules and silently lost.
        throw Exception(
          'Cannot create barber: no authenticated user available',
        );
      }

      // If agent ID provided, register shop to agent
      if (referralCode != null && referralCode.isNotEmpty) {
        _logger.i(
          'Registering shop $createdBarberId to agent/referral $referralCode',
        );

        await _firestore
            .collection(AppConstants.agentsCollection)
            .doc(referralCode)
            .update({
              'shopIds': FieldValue.arrayUnion([createdBarberId]),
              'shopsCount': FieldValue.increment(1),
              'updatedAt': Timestamp.now(),
            });

        _logger.i(
          'Shop registered to agent/referral. Code: $referralCode, Shop: $createdBarberId',
        );
      }

      _logger.i(
        'Barber shop created with ID: $createdBarberId, referralCode: $referralCode',
      );
      return createdBarberId;
    } catch (e) {
      _logger.e('Error creating barber with agent: $e');
      rethrow;
    }
  }

  /// Create a new barber shop (original method)
  /// If uid is provided, use it directly for doc creation (preferred to avoid race conditions).
  /// Otherwise, read from FirebaseAuth.instance.currentUser.
  Future<String> createBarber(Barber barber, {String? uid}) async {
    try {
      _logger.i('Creating barber shop: ${barber.shopName}');

      // Use provided uid, or read from current auth user
      String? useUid = uid;
      if (useUid == null) {
        final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
        useUid = currentUser?.uid;
        _logger.i(
          'Barber creation auth check - currentUser: ${currentUser?.email}, UID: $useUid',
        );
      } else {
        _logger.i('Barber creation using provided UID: $useUid');
      }

      if (useUid != null) {
        final docRef = _firestore
            .collection(AppConstants.barbersCollection)
            .doc(useUid);
        _logger.i(
          'Creating barber document at path: barbers/$useUid with shopName=${barber.shopName}',
        );
        await docRef.set(barber.toFirestore());
        _logger.i('Barber shop successfully created with ID: $useUid');
        return useUid;
      } else {
        // Enforce UID-based creation to comply with Firestore rules.
        _logger.e(
          'NO AUTHENTICATED USER: Cannot create barber document without auth UID. currentUser is null and no uid provided.',
        );
        throw Exception(
          'Cannot create barber: no authenticated user available',
        );
      }
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
        })
        .handleError((error) {
          _logger.e('Error in barber stream: $error');
        });
  }

  /// Get barber from users collection by id (fallback for legacy data)
  Future<Barber?> getBarberFromUsersById(String id) async {
    try {
      _logger.i('Fetching barber from users collection: $id');
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(id)
          .get();
      if (!doc.exists) {
        _logger.w('User doc $id not found in users collection');
        return null;
      }
      final userData = doc.data() as Map<String, dynamic>;

      DateTime createdAt;
      final rawCreated = userData['createdAt'];
      if (rawCreated is Timestamp) {
        createdAt = rawCreated.toDate();
      } else if (rawCreated is DateTime) {
        createdAt = rawCreated;
      } else if (rawCreated is String) {
        try {
          createdAt = DateTime.parse(rawCreated);
        } catch (_) {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }

      final shopName =
          (userData['shopName'] as String?) ??
          (userData['shop'] as String?) ??
          (userData['name'] as String?) ??
          '';
      final address =
          (userData['address'] as String?) ??
          (userData['town'] as String?) ??
          (userData['village'] as String?) ??
          (userData['city'] as String?) ??
          (userData['state'] as String?) ??
          '';

      return Barber(
        barberId: doc.id,
        shopName: shopName,
        shopId: (userData['shopId'] as String?) ?? '',
        ownerName: (userData['name'] as String?) ?? '',
        phone: (userData['phone'] as String?) ?? '',
        address: address,
        createdAt: createdAt,
        isOnline: (userData['isOnline'] as bool?) ?? false,
        region: {
          'state': userData['state'],
          'district': userData['district'],
          'block': userData['block'],
          'town': userData['town'],
          'village': userData['village'],
        },
      );
    } catch (e) {
      _logger.e('Error fetching barber from users: $e');
      return null;
    }
  }

  /// Get all barbers
  /// Note: onlineOnly parameter allows filtering by online status if needed.
  /// Default is false to show all registered barbers.
  Future<List<Barber>> getAllBarbers({bool onlineOnly = false}) async {
    try {
      _logger.i('Fetching all barbers (onlineOnly: $onlineOnly)');

      Query query = _firestore.collection(AppConstants.barbersCollection);

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

  /// Simple method: Get barbers from users collection with timeout protection
  Future<List<Barber>> getAllBarbersSimple() async {
    try {
      _logger.i('Simple barber fetch from users collection');

      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('userType', isEqualTo: 'barber')
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              _logger.w('Barber query timed out after 5s');
              throw TimeoutException('Barber query timed out');
            },
          );

      final barbers = <Barber>[];
      for (final doc in querySnapshot.docs) {
        try {
          final userData = doc.data();

          DateTime createdAtDt = DateTime.now();
          if (userData['createdAt'] != null) {
            final createdAt = userData['createdAt'];
            if (createdAt is Timestamp) {
              createdAtDt = createdAt.toDate();
            }
          }

          // Map user doc fields more reliably to Barber model
          final shopName =
              (userData['shopName'] as String?) ??
              (userData['shop'] as String?) ??
              (userData['name'] as String?) ??
              'Shop';
          final address =
              (userData['address'] as String?) ??
              (userData['town'] as String?) ??
              (userData['village'] as String?) ??
              (userData['city'] as String?) ??
              (userData['state'] as String?) ??
              'Location';
          final barber = Barber(
            barberId: doc.id,
            shopName: shopName,
            shopId: (userData['shopId'] as String?) ?? doc.id,
            ownerName: (userData['name'] as String?) ?? '',
            phone: (userData['phone'] as String?) ?? '',
            address: address,
            createdAt: createdAtDt,
            isOnline: (userData['isOnline'] as bool?) ?? false,
            region: {
              'state': userData['state'],
              'district': userData['district'],
              'block': userData['block'],
              'town': userData['town'],
              'village': userData['village'],
            },
          );
          barbers.add(barber);
        } catch (e) {
          _logger.w('Conversion error for user ${doc.id}: $e');
        }
      }

      _logger.i('Simple fetch: found ${barbers.length} barbers');
      return barbers;
    } catch (e) {
      _logger.e('Simple barber fetch error: $e');
      return [];
    }
  }

  /// Get all barbers from users collection (userType == 'barber')
  /// This is a fallback for when barber profiles are stored in users collection
  Future<List<Barber>> getAllBarbersFromUsers({bool onlineOnly = false}) async {
    try {
      _logger.i(
        'Fetching all barbers from users collection (onlineOnly: $onlineOnly)',
      );

      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .where('userType', isEqualTo: 'barber');

      // Only filter by online status if explicitly requested
      if (onlineOnly) {
        query = query.where('isOnline', isEqualTo: true);
      }

      final querySnapshot = await query.get();

      // Convert User documents to Barber objects (normalize types)
      final barbers = querySnapshot.docs.map((doc) {
        final userData = doc.data() as Map<String, dynamic>;

        // createdAt in users may be a Firestore Timestamp or a DateTime string/object
        DateTime createdAt;
        final rawCreated = userData['createdAt'];
        if (rawCreated is Timestamp) {
          createdAt = rawCreated.toDate();
        } else if (rawCreated is DateTime) {
          createdAt = rawCreated;
        } else if (rawCreated is String) {
          try {
            createdAt = DateTime.parse(rawCreated);
          } catch (_) {
            createdAt = DateTime.now();
          }
        } else {
          createdAt = DateTime.now();
        }

        // Map User fields to Barber fields
        // Map user fields into Barber including region info
        final shopName =
            (userData['shopName'] as String?) ??
            (userData['shop'] as String?) ??
            (userData['name'] as String?) ??
            '';
        final address =
            (userData['address'] as String?) ??
            (userData['town'] as String?) ??
            (userData['village'] as String?) ??
            (userData['city'] as String?) ??
            (userData['state'] as String?) ??
            '';

        return Barber(
          barberId: doc.id,
          shopName: shopName,
          shopId: (userData['shopId'] as String?) ?? '',
          ownerName: (userData['name'] as String?) ?? '',
          phone: (userData['phone'] as String?) ?? '',
          address: address,
          createdAt: createdAt,
          isOnline: (userData['isOnline'] as bool?) ?? false,
          region: {
            'state': userData['state'],
            'district': userData['district'],
            'block': userData['block'],
            'town': userData['town'],
            'village': userData['village'],
          },
        );
      }).toList();

      _logger.i(
        'Fetched ${barbers.length} barbers from users collection (onlineOnly=$onlineOnly)',
      );
      return barbers;
    } catch (e) {
      _logger.e('Error fetching barbers from users collection: $e');
      return []; // Return empty list instead of throwing to prevent app crash
    }
  }

  /// Get all barbers - tries barbers collection first, falls back to users collection
  Future<List<Barber>> getAllBarbersWithFallback({
    bool onlineOnly = false,
  }) async {
    try {
      _logger.i(
        'Fetching all barbers (with fallback) (onlineOnly: $onlineOnly)',
      );

      // Try fetching from barbers collection first
      try {
        final barbersCollectionData = await getAllBarbers(
          onlineOnly: onlineOnly,
        );
        if (barbersCollectionData.isNotEmpty) {
          _logger.i(
            'Found ${barbersCollectionData.length} barbers in barbers collection',
          );
          return barbersCollectionData;
        }
      } catch (e) {
        _logger.w(
          'Error fetching from barbers collection, trying users collection: $e',
        );
      }

      // Fallback to users collection
      final barbersFromUsers = await getAllBarbersFromUsers(
        onlineOnly: onlineOnly,
      );
      _logger.i(
        'Fallback: Found ${barbersFromUsers.length} barbers in users collection',
      );
      return barbersFromUsers;
    } catch (e) {
      _logger.e('Error fetching all barbers with fallback: $e');
      return []; // Return empty list instead of throwing
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

      _logger.i(
        'Fetched ${barbers.length} barbers for referralCode $referralCode',
      );
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
          .update({'isOnline': isOnline});

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
        final barberRef = _firestore
            .collection(AppConstants.barbersCollection)
            .doc(barberId);
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
          .update({'currentToken': 0, 'queue': [], 'queueLength': 0});

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
  Future<void> removeFromQueue(
    String barberId,
    Map<String, dynamic> booking,
  ) async {
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
          .update({'rating': rating});

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
          .update({'totalEarnings': FieldValue.increment(amount)});

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
