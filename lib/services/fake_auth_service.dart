import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import 'auth_service_base.dart';

class _FakeUser {
  final String uid;
  final String? email;
  _FakeUser({required this.uid, this.email});
}

/// Simple in-memory fake auth service for local UI testing
class FakeAuthService implements BaseAuthService {
  final _uuid = const Uuid();
  final Map<String, String> _usersByEmail = {}; // email -> uid
  final Map<String, _FakeUser> _users = {};
  _FakeUser? _signedInUser;

  final StreamController<dynamic> _authStateController = StreamController<dynamic>.broadcast();

  @override
  dynamic get currentUser => _signedInUser;

  @override
  Stream<dynamic> get authStateChanges => _authStateController.stream;

  @override
  String? get currentUserId => _signedInUser?.uid;

  @override
  Future<dynamic> signInWithGoogle({required String userType}) async {
    // Simulate user picking a google account and return a full User model
    await Future.delayed(const Duration(milliseconds: 300));
    final uid = _uuid.v4();
    final email = 'google_user_${uid.substring(0, 6)}@example.test';

    // Create a User model that the rest of the app expects
    final now = DateTime.now();
    final userModel = User(
      uid: uid,
      email: email,
      name: 'Google User',
      userType: userType,
      createdAt: now,
      lastLogin: now,
    );

    // Keep internal fake auth records for other flows
    final fake = _FakeUser(uid: uid, email: email);
    _usersByEmail[email] = uid;
    _users[uid] = fake;
    _signedInUser = fake;
    _authStateController.add(_signedInUser);

    // Return the User model so AuthProvider can pass it to the UserService
    return userModel;
  }

  @override
  Future<dynamic> signInWithEmailPassword({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final uid = _usersByEmail[email];
    if (uid == null) return null;
    _signedInUser = _users[uid];
    _authStateController.add(_signedInUser);
    return _signedInUser;
  }

  @override
  Future<dynamic> createAdminAccount({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_usersByEmail.containsKey(email)) return null;
    final uid = _uuid.v4();
    final user = _FakeUser(uid: uid, email: email);
    _usersByEmail[email] = uid;
    _users[uid] = user;
    _signedInUser = user;
    _authStateController.add(_signedInUser);
    return _signedInUser;
  }

  @override
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    // no-op for fake
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _signedInUser = null;
    _authStateController.add(null);
  }

  @override
  bool isAuthenticated() => _signedInUser != null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return 'fake-token-${_signedInUser?.uid ?? 'none'}';
  }

  @override
  Future<dynamic> loginWithEmail({required String email, required String password}) => signInWithEmailPassword(email: email, password: password);

  @override
  Future<dynamic> signupWithEmail({required String email, required String password}) async {
    if (_usersByEmail.containsKey(email)) {
      // mimic Firebase behavior: throw an error could be handled by provider
      throw Exception('email-already-in-use');
    }
    final uid = _uuid.v4();
    final user = _FakeUser(uid: uid, email: email);
    _usersByEmail[email] = uid;
    _users[uid] = user;
    _signedInUser = user;
    _authStateController.add(_signedInUser);
    return _signedInUser;
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // no-op for fake
  }

  @override
  Future<void> deleteAccount() async {
    if (_signedInUser != null) {
      _users.remove(_signedInUser!.uid);
    }
    _signedInUser = null;
    _authStateController.add(null);
  }
}
