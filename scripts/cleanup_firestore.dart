// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_identifier, undefined_class, avoid_print, dangling_library_doc_comments
/// Firestore Cleanup Script
/// This script removes all fake/sample data from Firestore
/// Usage: dart cleanup_firestore.dart
/// 
/// Before running:
/// 1. Ensure you have the Firebase Admin SDK set up
/// 2. Run: pub add firebase_admin (in a separate script-only project)
/// 3. Download your Firebase service account key from Firebase Console
/// 4. Set GOOGLE_APPLICATION_CREDENTIALS environment variable

import 'package:firebase_admin/firebase_admin.dart';

/// Collections to clean
const String usersCollection = 'users';
const String barbersCollection = 'barbers';
const String bookingsCollection = 'bookings';
const String barberIncomeCollection = 'barber_income';
const String barberShiftsCollection = 'barber_shifts';
const String agentsCollection = 'agents';

Future<void> main() async {
  try {
    // Initialize Firebase Admin SDK
    // This will use GOOGLE_APPLICATION_CREDENTIALS environment variable
    final app = FirebaseAdminApp.initializeApp();
    final firestore = Firestore.getInstance(app);

    print('🧹 Starting Firestore cleanup...\n');

    // Clean barbers collection (remove all entries)
    print('📍 Cleaning barbers collection...');
    await _cleanCollection(firestore, barbersCollection);

    // Clean bookings collection (remove all entries)
    print('📍 Cleaning bookings collection...');
    await _cleanCollection(firestore, bookingsCollection);

    // Clean barber_income collection (remove all entries)
    print('📍 Cleaning barber_income collection...');
    await _cleanCollection(firestore, barberIncomeCollection);

    // Clean barber_shifts collection (remove all entries)
    print('📍 Cleaning barber_shifts collection...');
    await _cleanCollection(firestore, barberShiftsCollection);

    // Clean users collection but KEEP admin users
    print('📍 Cleaning users collection (keeping admins)...');
    await _cleanUsersKeepingAdmins(firestore);

    // Clean agents collection
    print('📍 Cleaning agents collection...');
    await _cleanCollection(firestore, agentsCollection);

    print('\n✅ Firestore cleanup complete!');
    print('💡 All fake/sample data has been removed.');
    print('📊 Collections are now ready for real data.\n');

    await app.delete();
  } catch (e) {
    print('❌ Error during cleanup: $e');
    rethrow;
  }
}

/// Clean all documents in a collection
Future<void> _cleanCollection(
  Firestore firestore,
  String collectionPath,
) async {
  try {
    final docs = await firestore.collection(collectionPath).get();
    
    if (docs.empty) {
      print('   ✓ Collection is already empty');
      return;
    }

    int deletedCount = 0;
    for (final doc in docs.docs) {
      await doc.reference.delete();
      deletedCount++;
    }

    print('   ✓ Deleted $deletedCount documents from $collectionPath');
  } catch (e) {
    print('   ⚠️  Error cleaning $collectionPath: $e');
  }
}

/// Clean users collection but keep admin users
Future<void> _cleanUsersKeepingAdmins(Firestore firestore) async {
  try {
    final allUsers = await firestore.collection(usersCollection).get();
    
    if (allUsers.empty) {
      print('   ✓ Users collection is already empty');
      return;
    }

    int deletedCount = 0;
    int adminCount = 0;

    for (final userDoc in allUsers.docs) {
      final userData = userDoc.data() ?? {};
      final userType = userData['userType'] as String? ?? '';

      if (userType == 'admin') {
        // Keep admin users
        adminCount++;
        print('   ↳ Keeping admin user: ${userDoc.id}');
      } else {
        // Delete non-admin users
        await userDoc.reference.delete();
        deletedCount++;
      }
    }

    print('   ✓ Deleted $deletedCount non-admin users');
    print('   ✓ Kept $adminCount admin users');
  } catch (e) {
    print('   ⚠️  Error cleaning users: $e');
  }
}
