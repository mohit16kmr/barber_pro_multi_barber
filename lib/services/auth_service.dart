import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import '../config/app_constants.dart';
import '../models/index.dart';
import 'auth_service_base.dart';

/// Authentication Service for handling Firebase Auth operations
class AuthService implements BaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  // Initialize GoogleSignIn with proper scopes and server client ID for OAuth
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '612832799916-62rrkmddvjr6k9n482f89i5cm3g6khs9.apps.googleusercontent.com',
  );
  final Logger _logger = Logger();

  // Get current user
  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  // Listen to auth state changes
  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Get current user ID
  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Google Sign In for Customer/Barber
  /// [userType]: 'customer' or 'barber'
  /// Returns [User] model if successful
  @override
  Future<User?> signInWithGoogle({required String userType}) async {
    try {
      _logger.i('Starting Google Sign-In for userType: $userType');
      _logger.d(
        'GoogleSignIn configuration: scopes=[email, profile], serverClientId configured',
      );

      // Use a fresh GoogleSignIn instance for each sign-in attempt to avoid
      // reusing cached/native state that may cause platform-channel mismatches.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '612832799916-62rrkmddvjr6k9n482f89i5cm3g6khs9.apps.googleusercontent.com',
      );

      GoogleSignInAccount? googleUser;
      try {
        _logger.d('Calling googleSignIn.signIn()...');
        googleUser = await googleSignIn.signIn();
        _logger.d('googleSignIn.signIn() completed. googleUser=$googleUser');
      } catch (e) {
        _logger.e('Exception during googleSignIn.signIn(): $e');
        // Handle Pigeon/platform channel casting errors
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains("type 'List<Object?>") ||
            e.toString().contains('is not a subtype')) {
          _logger.e('Pigeon platform channel error during signIn: $e');
          _logger.i('Attempting to recover from Pigeon error...');
          // Retry once by disconnecting the local GoogleSignIn instance and retrying
          try {
            try {
              await googleSignIn.disconnect();
              _logger.i(
                'Disconnected local GoogleSignIn instance, retrying...',
              );
            } catch (disconnectErr) {
              _logger.w(
                'Local GoogleSignIn.disconnect() failed during recovery: $disconnectErr',
              );
            }
            googleUser = await googleSignIn.signIn();
            _logger.d('Retry successful. googleUser=$googleUser');
          } catch (retryError) {
            _logger.e('Retry after Pigeon error also failed: $retryError');
            rethrow;
          }
        } else {
          _logger.e('Non-Pigeon error, rethrowing: $e');
          rethrow;
        }
      }

      if (googleUser == null) {
        _logger.w('Google Sign-In was cancelled by user or returned null');
        return null;
      }

      _logger.i('GoogleSignIn successful. User: ${googleUser.email}');
      _logger.d('Getting authentication tokens...');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      _logger.d('Got authentication tokens. Creating Firebase credential...');

      final firebase_auth.OAuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

      _logger.d('Signing in to Firebase with OAuth credential...');

      late firebase_auth.UserCredential userCredential;
      int attempt = 0;
      const int maxAttempts = 3;
      dynamic lastError;

      while (attempt < maxAttempts) {
        attempt++;
        try {
          _logger.d(
            '=== PAYLOAD CAPTURE: About to call signInWithCredential (attempt $attempt/$maxAttempts) ===',
          );
          _logger.d('Credential type: ${credential.runtimeType}');
          userCredential = await _firebaseAuth.signInWithCredential(credential);
          _logger.d('=== PAYLOAD CAPTURE: signInWithCredential succeeded ===');
          _logger.d('UserCredential.user: ${userCredential.user}');
          break; // Success, exit loop
        } catch (e) {
          lastError = e;
          _logger.e(
            '=== PAYLOAD CAPTURE: Error during signInWithCredential (attempt $attempt) ===',
          );
          _logger.e('Error type: ${e.runtimeType}');
          _logger.e('Error toString: $e');
          if (e is TypeError) {
            _logger.e('TypeError details: ${e.toString()}');
            _logger.e('TypeError stackTrace: ${e.stackTrace}');
          }

          // If Pigeon error and not last attempt, wait briefly then retry
          if ((e.toString().contains('Pigeon') ||
                  e.toString().contains("type 'List<Object?>") ||
                  e.toString().contains('is not a subtype')) &&
              attempt < maxAttempts) {
            _logger.w(
              'Detected Pigeon cast error; retrying after brief delay...',
            );
            await Future.delayed(
              Duration(milliseconds: 500 * attempt),
            ); // Exponential backoff
            continue; // Retry
          }
          // If different error, rethrow immediately
          if (!e.toString().contains('Pigeon') &&
              !e.toString().contains("type 'List<Object?>") &&
              !e.toString().contains('is not a subtype')) {
            rethrow;
          }
        }
      }

      if (lastError != null && attempt >= maxAttempts) {
        _logger.e(
          'All credential sign-in attempts failed after $maxAttempts tries',
        );
        throw lastError;
      }

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _logger.e('Firebase user is null after Google Sign-In');
        return null;
      }

      _logger.i('Google Sign-In successful for ${firebaseUser.email}');

      // Convert Firebase User to our User model
      return User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'User',
        phone: firebaseUser.phoneNumber,
        userType: userType,
        photoUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during Google Sign-In: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      _logger.e('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Admin Sign In with Email and Password
  /// Returns [FirebaseUser] if successful
  @override
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Starting email/password sign-in for: $email');

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(
            firebase_auth.EmailAuthProvider.credential(
              email: email,
              password: password,
            ),
          );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _logger.e('Firebase user is null after email/password sign-in');
        return null;
      }

      _logger.i('Email/password sign-in successful for $email');

      // For admin users, we assume they exist in Firestore with role
      return User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'Admin',
        userType: AppConstants.userTypeAdmin,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during email/password sign-in: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      _logger.e('Error during email/password sign-in: $e');
      rethrow;
    }
  }

  /// Create Admin Account (only for initial setup - should be restricted in real app)
  /// This requires admin privileges in Firestore rules
  @override
  Future<User?> createAdminAccount({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Creating admin account for: $email');

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _logger.e('Firebase user is null after admin account creation');
        return null;
      }

      _logger.i('Admin account created successfully for $email');

      return User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: email.split('@')[0],
        userType: AppConstants.userTypeAdmin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during admin creation: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      _logger.e('Error creating admin account: $e');
      rethrow;
    }
  }

  /// Update User Profile
  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _logger.i('Updating user profile');

      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);

      _logger.i('User profile updated successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception updating profile: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Sign Out
  @override
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google Sign-In
      try {
        await _googleSignIn.signOut();
        // Also disconnect to ensure the account is fully cleared from the plugin
        await _googleSignIn.disconnect();
      } catch (e) {
        _logger.w('GoogleSignIn signOut/disconnect had an issue: $e');
      }

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error during sign out: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  @override
  bool isAuthenticated() {
    return _firebaseAuth.currentUser != null;
  }

  /// Get ID Token
  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      _logger.e('Error getting ID token: $e');
      return null;
    }
  }

  /// Verify Email
  Future<void> sendEmailVerification() async {
    try {
      _logger.i('Sending email verification');
      await _firebaseAuth.currentUser?.sendEmailVerification();
      _logger.i('Email verification sent');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception sending email verification: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception sending password reset: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Login with email and password (Customer/Barber)
  @override
  Future<firebase_auth.User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Logging in with email: $email');

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      _logger.i('Login successful for: $email');
      return userCredential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during login: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Signup with email and password (Customer/Barber)
  @override
  Future<firebase_auth.User?> signupWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Signing up new user with email: $email');

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      _logger.i('Signup successful for: $email');
      return userCredential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during signup: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Reset password via email
  @override
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Resetting password for: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception during password reset: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Delete Account
  @override
  Future<void> deleteAccount() async {
    try {
      _logger.i('Deleting user account');
      await _firebaseAuth.currentUser?.delete();
      _logger.i('User account deleted');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e(
        'Firebase Auth Exception deleting account: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }
}
