import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../config/app_constants.dart';
import '../models/index.dart';
import 'user_service_base.dart';

/// Firestore User Service for CRUD operations on users
class UserService implements BaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Create or update user in Firestore
  @override
  Future<void> createOrUpdateUser(User user) async {
    try {
      _logger.i('Creating/updating user: ${user.uid}');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));

      _logger.i('User ${user.uid} created/updated successfully');
    } catch (e) {
      _logger.e('Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  @override
  Future<User?> getUserById(String userId) async {
    try {
      _logger.i('Fetching user: $userId');

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        _logger.w('User $userId not found');
        return null;
      }

      _logger.i('User $userId fetched successfully');
      return User.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching user: $e');
      rethrow;
    }
  }

  /// Get user stream (for real-time updates)
  @override
  Stream<User?> getUserStream(String userId) {
    _logger.i('Listening to user stream: $userId');

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        _logger.w('User $userId not found in stream');
        return null;
      }
      return User.fromFirestore(doc);
    }).handleError((error) {
      _logger.e('Error in user stream: $error');
    });
  }

  /// Update user's favorite barbers
  @override
  Future<void> toggleFavoriteBarber(String userId, String barberId) async {
    try {
      _logger.i('Toggling favorite barber for user $userId');

      final userDoc = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      await userDoc.update({
        'favoriteBarbers': FieldValue.arrayUnion([barberId])
      }).then((_) {
        _logger.i('Added $barberId to favorites');
      }).catchError((_) async {
        // If arrayUnion fails, try arrayRemove
        await userDoc.update({
          'favoriteBarbers': FieldValue.arrayRemove([barberId])
        });
        _logger.i('Removed $barberId from favorites');
      });
    } catch (e) {
      _logger.e('Error toggling favorite barber: $e');
      rethrow;
    }
  }

  /// Update last login timestamp
  @override
  Future<void> updateLastLogin(String userId) async {
    try {
      _logger.i('Updating last login for user: $userId');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'lastLogin': Timestamp.now(),
      });

      _logger.i('Last login updated for user $userId');
    } catch (e) {
      _logger.e('Error updating last login: $e');
      rethrow;
    }
  }

  /// Delete user
  @override
  Future<void> deleteUser(String userId) async {
    try {
      _logger.i('Deleting user: $userId');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();

      _logger.i('User $userId deleted successfully');
    } catch (e) {
      _logger.e('Error deleting user: $e');
      rethrow;
    }
  }

  /// Check if user exists
  @override
  Future<bool> userExists(String userId) async {
    try {
      _logger.i('Checking if user exists: $userId');

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      _logger.e('Error checking user existence: $e');
      rethrow;
    }
  }

  /// Get all users (admin only - should be restricted in Firestore rules)
  @override
  Future<List<User>> getAllUsers() async {
    try {
      _logger.i('Fetching all users');

      final querySnapshot =
          await _firestore.collection(AppConstants.usersCollection).get();

      final users = querySnapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${users.length} users');
      return users;
    } catch (e) {
      _logger.e('Error fetching all users: $e');
      rethrow;
    }
  }

  /// Search users by name
  @override
  Future<List<User>> searchUsersByName(String query) async {
    try {
      _logger.i('Searching users with query: $query');

      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      final users = querySnapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();

      _logger.i('Found ${users.length} users matching query');
      return users;
    } catch (e) {
      _logger.e('Error searching users: $e');
      rethrow;
    }
  }

  /// Switch user role from customer to barber or vice versa
  @override
  Future<void> switchUserRole(String userId, String newRole) async {
    try {
      _logger.i('Switching role for user $userId to $newRole');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'userType': newRole,
        'updatedAt': Timestamp.now(),
      });

      _logger.i('User role switched successfully');
    } catch (e) {
      _logger.e('Error switching user role: $e');
      rethrow;
    }
  }
}
