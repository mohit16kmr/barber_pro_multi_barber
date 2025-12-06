import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// Firebase Connectivity Diagnostic Tool
/// Use this to verify Firebase connection and troubleshoot issues
class FirebaseDiagnostics {
  static final Logger _logger = Logger();

  /// Run complete Firebase health check
  static Future<void> runDiagnostics() async {
    _logger.i('=== Firebase Connectivity Diagnostics ===');

    try {
      // Check 1: Firebase Core Initialization
      await _checkFirebaseCore();

      // Check 2: Firestore Connection
      await _checkFirestoreConnection();

      // Check 3: Firebase Auth
      await _checkFirebaseAuth();

      // Check 4: Collections Access
      await _checkCollectionsAccess();

      _logger.i('=== All Checks Completed ✓ ===');
    } catch (e) {
      _logger.e('Diagnostics failed: $e');
    }
  }

  /// Check if Firebase Core is initialized
  static Future<void> _checkFirebaseCore() async {
    try {
      _logger.i('Check 1: Firebase Core Initialization');
      
      // Firebase should already be initialized in main.dart
      if (Firebase.apps.isNotEmpty) {
        _logger.i('  ✓ Firebase Core initialized');
        _logger.i('  ✓ Default app: ${Firebase.apps.first.name}');
      } else {
        _logger.e('  ✗ Firebase Core NOT initialized');
      }
    } catch (e) {
      _logger.e('  ✗ Error checking Firebase Core: $e');
    }
  }

  /// Check Firestore connection
  static Future<void> _checkFirestoreConnection() async {
    try {
      _logger.i('Check 2: Firestore Connection');

      final firestore = FirebaseFirestore.instance;
      
      // Try a simple read operation with timeout
      await firestore
          .collection('_diagnostic_test')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Firestore connection timeout');
            },
          );

      _logger.i('  ✓ Firestore connection successful');
      _logger.i('  ✓ Project ID: ${firestore.app.options.projectId}');
    } catch (e) {
      _logger.e('  ✗ Firestore connection failed: $e');
      _logger.e('  💡 Ensure Firestore database is enabled in Firebase Console');
    }
  }

  /// Check Firebase Authentication
  static Future<void> _checkFirebaseAuth() async {
    try {
      _logger.i('Check 3: Firebase Authentication');

      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        _logger.i('  ✓ User authenticated');
        _logger.i('  ✓ UID: ${currentUser.uid}');
        _logger.i('  ✓ Email: ${currentUser.email}');
      } else {
        _logger.i('  ℹ No user currently authenticated (normal if just launched)');
      }

      // Check if auth is properly configured
      _logger.i('  ✓ Firebase Auth available');
    } catch (e) {
      _logger.e('  ✗ Firebase Auth check failed: $e');
    }
  }

  /// Check collections accessibility
  static Future<void> _checkCollectionsAccess() async {
    try {
      _logger.i('Check 4: Collections Accessibility');

      final firestore = FirebaseFirestore.instance;
      final collections = [
        'users',
        'barbers',
        'bookings',
        'barber_income',
      ];

      for (final collection in collections) {
        try {
          final docs = await firestore
              .collection(collection)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 3));

          _logger.i('  ✓ Collection "$collection" accessible (${docs.docs.length} docs)');
        } on TimeoutException {
          _logger.w('  ⚠ Collection "$collection" timeout');
        } catch (e) {
          _logger.w('  ⚠ Collection "$collection" error: ${e.toString().split('\n').first}');
        }
      }
    } catch (e) {
      _logger.e('  ✗ Collections check failed: $e');
    }
  }

  /// Print system information
  static void printSystemInfo() {
    _logger.i('=== System Information ===');
    _logger.i('Firebase Projects:');
    _logger.i('  1. Project ID: book-your-barber-cd1f8');
    _logger.i('  2. Project ID: barber-pro-20d4b');
    _logger.i('');
    _logger.i('Connected Services:');
    _logger.i('  ✓ Firebase Auth (Google Sign-In, Email/Password)');
    _logger.i('  ✓ Cloud Firestore (Database)');
    _logger.i('  ✓ Firebase Storage (File uploads)');
    _logger.i('  ✓ Firebase Messaging (Push notifications)');
    _logger.i('');
    _logger.i('Auth Methods Enabled:');
    _logger.i('  • Google Sign-In');
    _logger.i('  • Email/Password (Admin)');
  }
}

/// Usage in your app:
/// 
/// // Add to main.dart after Firebase initialization:
/// if (kDebugMode) {
///   Future.delayed(const Duration(seconds: 1), () {
///     FirebaseDiagnostics.runDiagnostics();
///     FirebaseDiagnostics.printSystemInfo();
///   });
/// }
