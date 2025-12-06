import '../models/index.dart';

abstract class BaseUserService {
  Future<void> createOrUpdateUser(User user);

  Future<User?> getUserById(String userId);

  Stream<User?> getUserStream(String userId);

  Future<void> toggleFavoriteBarber(String userId, String barberId);

  Future<void> updateLastLogin(String userId);

  Future<void> deleteUser(String userId);

  Future<bool> userExists(String userId);

  Future<List<User>> getAllUsers();

  Future<List<User>> searchUsersByName(String query);

  /// Switch user role from customer to barber or vice versa
  Future<void> switchUserRole(String userId, String newRole);
}
