import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to create test users for email/password login testing
Future<void> createTestUsers() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Test credentials
  const testUsers = [
    {'email': 'customer@test.com', 'password': 'Test@1234', 'role': 'customer'},
    {'email': 'barber@test.com', 'password': 'Test@1234', 'role': 'barber'},
  ];

  for (final user in testUsers) {
    try {
      // Create auth user
      final userCred = await auth.createUserWithEmailAndPassword(
        email: user['email'] as String,
        password: user['password'] as String,
      );

      print('✅ Created user: ${user['email']}');

      // Create user profile in Firestore
      await firestore.collection('users').doc(userCred.user!.uid).set({
        'email': user['email'],
        'name': 'Test ${user['role']}',
        'role': user['role'],
        'createdAt': FieldValue.serverTimestamp(),
        'phone': '+91 98765 43210',
      });

      print('✅ Created profile for: ${user['email']}');
    } catch (e) {
      print('⚠️ Error creating ${user['email']}: $e');
    }
  }

  print('\n📝 Test Credentials:');
  for (final user in testUsers) {
    print('Email: ${user['email']}');
    print('Password: ${user['password']}');
    print('---');
  }
}

void main() async {
  print('Creating test users...');
  await createTestUsers();
}
