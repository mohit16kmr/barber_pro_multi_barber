import 'dart:async';
import '../models/index.dart';
import 'user_service_base.dart';

class FakeUserService implements BaseUserService {
  final Map<String, User> _store = {};
  final StreamController<User?> _controller = StreamController<User?>.broadcast();

  @override
  Future<void> createOrUpdateUser(User user) async {
    _store[user.uid] = user;
    _controller.add(user);
  }

  @override
  Future<User?> getUserById(String userId) async {
    return _store[userId];
  }

  @override
  Stream<User?> getUserStream(String userId) {
    return _controller.stream.where((u) => u == null || u.uid == userId).map((u) => u);
  }

  @override
  Future<void> toggleFavoriteBarber(String userId, String barberId) async {
    final user = _store[userId];
    if (user == null) return;
    final favorites = List<String>.from(user.favoriteBarbers);
    if (favorites.contains(barberId)) {
      favorites.remove(barberId);
    } else {
      favorites.add(barberId);
    }
    _store[userId] = user.copyWith(favoriteBarbers: favorites);
    _controller.add(_store[userId]);
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    final user = _store[userId];
    if (user == null) return;
    _store[userId] = user.copyWith(lastLogin: DateTime.now());
    _controller.add(_store[userId]);
  }

  @override
  Future<void> deleteUser(String userId) async {
    _store.remove(userId);
    _controller.add(null);
  }

  @override
  Future<bool> userExists(String userId) async {
    return _store.containsKey(userId);
  }

  @override
  Future<List<User>> getAllUsers() async {
    return _store.values.toList();
  }

  @override
  Future<List<User>> searchUsersByName(String query) async {
    return _store.values.where((u) => u.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<void> switchUserRole(String userId, String newRole) async {
    final user = _store[userId];
    if (user == null) return;
    _store[userId] = user.copyWith(userType: newRole);
    _controller.add(_store[userId]);
  }
}
