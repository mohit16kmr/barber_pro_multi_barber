abstract class BaseAuthService {
  dynamic get currentUser;

  Stream<dynamic> get authStateChanges;

  String? get currentUserId;

  Future<dynamic> signInWithGoogle({required String userType});

  Future<dynamic> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<dynamic> createAdminAccount({
    required String email,
    required String password,
  });

  Future<void> updateUserProfile({String? displayName, String? photoURL});

  Future<void> signOut();

  bool isAuthenticated();

  Future<String?> getIdToken({bool forceRefresh = false});

  Future<dynamic> loginWithEmail({
    required String email,
    required String password,
  });

  Future<dynamic> signupWithEmail({
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);

  Future<void> deleteAccount();
}
