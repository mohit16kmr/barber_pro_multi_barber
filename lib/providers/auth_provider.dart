import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';
import '../models/index.dart';
import '../services/index.dart';

/// Auth Provider - manages authentication state
class AuthProvider extends ChangeNotifier {
  late final BaseAuthService _authService;
  final BaseUserService _userService;
  final BarberService _barberService;
  final Logger _logger = Logger();

  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _needsRegistration = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userType => _currentUser?.userType;
  String? get userRole => _currentUser?.userType;
  bool get needsRegistration => _needsRegistration;

  AuthProvider({
    BaseAuthService? authService,
    BaseUserService? userService,
    BarberService? barberService,
  }) : _authService = authService ?? AuthService(),
       _userService = userService ?? UserService(),
       _barberService = barberService ?? BarberService();

  /// Expose underlying auth state change stream so routing can listen
  Stream<firebase_auth.User?> get authStateChanges =>
      _authService.authStateChanges as Stream<firebase_auth.User?>;

  /// Initialize auth state from Firebase or fake service
  Future<void> initializeAuth() async {
    try {
      _setLoading(true);
      _logger.i('Initializing auth...');

      final firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
        _currentUser = await _userService.getUserById(firebaseUser.uid);

        // If Firestore profile exists, mark authenticated and update last login.
        if (_currentUser != null) {
          _isAuthenticated = true;
          _logger.i('Auth initialized with user: ${_currentUser!.email}');
          await _userService.updateLastLogin(_currentUser!.uid);
        } else {
          // Authenticated at Firebase but no Firestore profile yet.
          // Mark needsRegistration so UI/routes can send user to complete profile
          // instead of assuming a non-null profile (prevents Home/Profile hang).
          _isAuthenticated = true;
          _needsRegistration = true;
          _logger.w(
            'Firebase user ${firebaseUser.uid} has no Firestore profile; needs registration',
          );
        }
      } else {
        _isAuthenticated = false;
        _logger.i('No authenticated user found');
      }
    } catch (e) {
      _logger.e('Error initializing auth: $e');
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  /// Google Sign In for Customer or Barber
  Future<bool> signInWithGoogle({required String userType}) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Signing in with Google as $userType');

      final user = await _authService.signInWithGoogle(userType: userType);

      if (user == null) {
        _setError('Google sign-in was cancelled');
        return false;
      }

      // Determine if this Firebase user already has a Firestore profile.
      try {
        final exists = await _userService.userExists(user.uid);
        _logger.i(
          'Firestore profile check for uid ${user.uid}: exists=$exists',
        );

        if (exists) {
          // Persist/update and load full profile
          try {
            await _userService.createOrUpdateUser(user);
          } catch (e, st) {
            _logger.e('Error persisting user after Google sign-in: $e');
            _logger.d(st);
            final msg = e.toString();
            if (!(msg.contains('Pigeon') ||
                msg.contains("type 'List") ||
                msg.contains('is not a subtype'))) {
              rethrow;
            }
          }

          _currentUser = await _userService.getUserById(user.uid);
          _needsRegistration = false;
          _logger.i(
            'Existing user loaded from Firestore: ${_currentUser?.email} (role=${_currentUser?.userType})',
          );
        } else {
          // New user: do not create a full profile yet; indicate registration needed
          _currentUser = user;
          _needsRegistration = true;
          _logger.i(
            'New user detected (no Firestore profile yet): ${user.email}. Will route to registration.',
          );
        }

        _isAuthenticated = true;
        _logger.i(
          'Successfully signed in with Google (needsRegistration=$_needsRegistration)',
        );
        notifyListeners();
        return true;
      } catch (e) {
        _logger.e('Error checking/creating user after Google sign-in: $e');
        _setError('Failed to complete Google sign-in: ${e.toString()}');
        return false;
      }
    } catch (e) {
      _logger.e('Error signing in with Google: $e');
      _setError('Failed to sign in with Google: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch user role (e.g., from customer to barber or vice versa)
  Future<bool> switchUserRole({required String newRole}) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        _setError('No user is currently logged in');
        return false;
      }

      _logger.i('Switching user role to $newRole');

      // Update role in Firestore
      await _userService.switchUserRole(_currentUser!.uid, newRole);

      // Update local user object
      _currentUser = _currentUser!.copyWith(userType: newRole);

      _logger.i('User role switched successfully to $newRole');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error switching user role: $e');
      _setError('Failed to switch role: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Admin Sign In with Email and Password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Signing in admin with email: $email');

      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        _setError('Email/password sign-in failed');
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      _logger.i('Successfully signed in admin');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error signing in with email/password: $e');
      _setError('Failed to sign in: Invalid email or password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create Admin Account
  Future<bool> createAdminAccount({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Creating admin account for: $email');

      final user = await _authService.createAdminAccount(
        email: email,
        password: password,
      );

      if (user == null) {
        _setError('Failed to create admin account');
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      _logger.i('Admin account created successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error creating admin account: $e');
      _setError('Failed to create admin account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _logger.i('Signing out...');

      await _authService.signOut();

      _currentUser = null;
      _isAuthenticated = false;

      _logger.i('Successfully signed out');

      notifyListeners();
    } catch (e) {
      _logger.e('Error signing out: $e');
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password (Customer/Barber)
  Future<bool> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Logging in with email: $email');

      final firebaseUser = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (firebaseUser == null) {
        _setError('Login failed: Invalid credentials');
        return false;
      }

      _currentUser = await _userService.getUserById(firebaseUser.uid);
      if (_currentUser == null) {
        _setError('User profile not found');
        return false;
      }

      _isAuthenticated = true;
      _logger.i('Successfully logged in: ${_currentUser!.email}');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error logging in: $e');
      _setError('Failed to login: Invalid email or password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signup with email and password
  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    required String userRole, // 'customer' or 'barber'
    String? referralCode,
    // Barber-specific fields
    String? phone,
    String? address,
    String? shopName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Signing up new user: $email as $userRole');
      // Step 1: create firebase auth user
      firebase_auth.User? firebaseUser;
      try {
        firebaseUser = await _authService.signupWithEmail(
          email: email,
          password: password,
        );
      } catch (e, st) {
        _logger.e('Error creating firebase user during signup: $e');
        _logger.d(st);
        _setError('Signup failed: ${e.toString()}');
        return false;
      }

      if (firebaseUser == null) {
        _setError('Signup failed');
        return false;
      }

      // Create user profile object to persist in Firestore
      final newUser = User(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        userType: userRole,
        referralCode: referralCode,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Step 2: try to persist user profile; make this resilient to
      // unexpected platform/pigeon casting issues (some plugin may return
      // an unexpected structure that causes a TypeError). If persisting
      // fails with a cast error coming from Pigeon-generated code, log
      // details and continue since the Firebase Auth user was created.
      try {
        await _userService.createOrUpdateUser(newUser);
      } catch (e, st) {
        _logger.e('Error persisting user profile: $e');
        _logger.d(st);
        // Handle pigeon cast mismatch gracefully so signup doesn't fail
        // completely when a platform API returns a List where an object
        // is expected. Detect common pattern in the error message.
        final msg = e.toString();
        if (msg.contains('Pigeon') ||
            msg.contains('type \'List') ||
            msg.contains('is not a subtype')) {
          _logger.w(
            'Detected Pigeon/platform casting issue while creating user — continuing since Firebase user exists.',
          );
        } else {
          _setError('Failed to create user profile: ${e.toString()}');
          return false;
        }
      }

      // Step 3: If barber signup, create Barber record with provided details
      if (userRole == 'barber' &&
          (phone != null || address != null || shopName != null)) {
        try {
          _logger.i(
            'Creating Barber record for new barber signup: ${firebaseUser.uid}',
          );

          final barber = Barber(
            barberId: '', // Will be set by Firestore
            shopName: shopName ?? '',
            shopId: shopName ?? '', // Use shop name as initial shopId
            ownerName: name,
            phone: phone ?? '',
            address: address ?? '',
            createdAt: DateTime.now(),
          );

          if (referralCode != null && referralCode.isNotEmpty) {
            // Create barber with referral code validation
            // Pass firebaseUser.uid directly to avoid race condition with FirebaseAuth.instance.currentUser
            await _barberService.createBarberWithAgent(
              barber: barber,
              referralCode: referralCode,
            );
          } else {
            // Create barber without referral code
            // Pass firebaseUser.uid directly to avoid race condition with FirebaseAuth.instance.currentUser
            await _barberService.createBarber(barber, uid: firebaseUser.uid);
          }

          _logger.i('Barber record created successfully');
        } catch (e, st) {
          _logger.e('Error creating barber record: $e');
          _logger.d(st);
          // Surface this error so UI can show a visible message instead of failing silently
          final msg = 'Failed to create barber profile: ${e.toString()}';
          try {
            _setError(msg);
          } catch (_) {
            _logger.w('Unable to set provider error state');
          }
          // Also log a warning for developers
          _logger.w(
            'Barber record creation failed, but user account exists. User can complete profile later. Error surfaced to UI.',
          );
        }
      }

      // Finalize auth state locally
      _currentUser = newUser;
      _isAuthenticated = true;
      _logger.i('Successfully signed up: $email');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error signing up: $e');
      _setError('Failed to signup: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete registration for a user who authenticated via external provider
  /// (e.g., Google) but does not yet have a Firestore profile. This will
  /// persist the provided profile fields into Firestore and load the full
  /// profile into the provider.
  /// 
  /// For barber users: if shopName and address are provided, also creates
  /// a Barber document in the barbers collection to enable service editing.
  Future<bool> completeRegistrationForCurrentUser({
    required String name,
    required String userRole,
    String? phone,
    String? city,
    String? shopId,
    String? referralCode,
    String? shopName,
    String? address,
    String? country,
    String? state,
    String? district,
    String? block,
    String? village,
    String? street,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null || !_isAuthenticated) {
        _setError('No authenticated user to complete registration');
        return false;
      }

      // Build a User model from the existing _currentUser info, merging provided fields
      final newUser = _currentUser!.copyWith(
        name: name,
        userType: userRole,
        phone: phone,
        city: city,
        shopId: shopId,
        referralCode: referralCode,
        country: country,
        state: state,
        district: district,
        block: block,
        village: village,
        street: street,
      );

      // Persist to Firestore
      await _userService.createOrUpdateUser(newUser);

      // If barber role and shop details provided, create Barber document
      if (userRole == 'barber' && shopName != null && shopName.isNotEmpty && 
          address != null && address.isNotEmpty) {
        try {
          _logger.i('Creating Barber document during registration completion');
          
          // Build region map from address breakdown fields for customer discovery filtering
          final region = <String, dynamic>{};
          if (country != null && country.isNotEmpty) region['country'] = country;
          if (state != null && state.isNotEmpty) region['state'] = state;
          if (district != null && district.isNotEmpty) region['district'] = district;
          if (block != null && block.isNotEmpty) region['block'] = block;
          if (village != null && village.isNotEmpty) {
            region['village'] = village;
            region['town'] = village; // Also add as 'town' for compatibility
          }
          if (street != null && street.isNotEmpty) region['street'] = street;
          
          final barber = Barber(
            barberId: '', // Will be set by Firestore
            shopName: shopName,
            shopId: shopName,
            ownerName: name,
            phone: phone ?? '',
            address: address,
            createdAt: DateTime.now(),
            region: region.isNotEmpty ? region : null,
          );

          if (referralCode != null && referralCode.isNotEmpty) {
            await _barberService.createBarberWithAgent(
              barber: barber,
              referralCode: referralCode,
            );
          } else {
            await _barberService.createBarber(barber, uid: _currentUser!.uid);
          }
          
          _logger.i('Barber document created successfully during registration');
        } catch (e) {
          _logger.w('Warning: Could not create Barber document: $e');
          // Continue - user profile is complete even if barber doc creation failed
        }
      }

      // Reload full profile from Firestore
      _currentUser = await _userService.getUserById(newUser.uid);
      _needsRegistration = false;
      _isAuthenticated = true;
      _logger.i('Registration completed for ${newUser.email} (role=$userRole)');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error completing registration: $e');
      _setError('Failed to complete registration: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password with email
  Future<bool> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Resetting password for: $email');

      await _authService.resetPassword(email);

      _logger.i('Password reset email sent');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error resetting password: $e');
      _setError('Failed to send reset email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      _logger.i('Logging out...');

      await _authService.signOut();

      _currentUser = null;
      _isAuthenticated = false;

      _logger.i('Successfully logged out');

      notifyListeners();
    } catch (e) {
      _logger.e('Error logging out: $e');
      _setError('Failed to logout');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? city,
    String? state,
    String? shopId,
    String? referralCode,
    int? yearsOfExperience,
    String? bio,
    String? country,
    String? district,
    String? block,
    String? village,
    String? street,
    String? nearbyLocation,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _logger.i('Updating user profile');

      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: displayName ?? _currentUser!.name,
          photoUrl: photoURL ?? _currentUser!.photoUrl,
          phone: phoneNumber ?? _currentUser!.phone,
          city: city ?? _currentUser!.city,
          state: state ?? _currentUser!.state,
          shopId: shopId ?? _currentUser!.shopId,
          referralCode: referralCode ?? _currentUser!.referralCode,
          yearsOfExperience:
              yearsOfExperience ?? _currentUser!.yearsOfExperience,
          bio: bio ?? _currentUser!.bio,
          country: country ?? _currentUser!.country,
          district: district ?? _currentUser!.district,
          block: block ?? _currentUser!.block,
          village: village ?? _currentUser!.village,
          street: street ?? _currentUser!.street,
          nearbyLocation: nearbyLocation ?? _currentUser!.nearbyLocation,
        );

        await _userService.createOrUpdateUser(_currentUser!);
      }

      _logger.i('User profile updated successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add barber to favorites
  Future<bool> toggleFavoriteBarber(String barberId) async {
    try {
      if (_currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      _logger.i('Toggling favorite barber: $barberId');

      await _userService.toggleFavoriteBarber(_currentUser!.uid, barberId);

      // Update local state
      final isFavorited = _currentUser!.favoriteBarbers.contains(barberId);
      if (isFavorited) {
        _currentUser = _currentUser!.copyWith(
          favoriteBarbers: _currentUser!.favoriteBarbers
              .where((id) => id != barberId)
              .toList(),
        );
      } else {
        _currentUser = _currentUser!.copyWith(
          favoriteBarbers: [..._currentUser!.favoriteBarbers, barberId],
        );
      }

      _logger.i('Favorite barber toggled');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Error toggling favorite barber: $e');
      _setError('Failed to toggle favorite');
      return false;
    }
  }

  /// Check if user is customer
  bool isCustomer() => _currentUser?.userType == 'customer';

  /// Check if user is barber
  bool isBarber() => _currentUser?.userType == 'barber';

  /// Check if user is admin
  bool isAdmin() => _currentUser?.userType == 'admin';

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
}
