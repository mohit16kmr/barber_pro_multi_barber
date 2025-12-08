/*
  This file is the Flutter entry point but should NOT be used.
  Individual flavor mains (main_barber.dart, main_admin.dart, main_customer.dart)
  should be specified via build flags.

  DO NOT RUN THIS DIRECTLY. Use:
    flutter run --flavor barber -t lib/main_barber.dart
    flutter run --flavor admin -t lib/main_admin.dart
    flutter run --flavor customer -t lib/main_customer.dart
    flutter build apk --flavor barber -t lib/main_barber.dart
    flutter build apk --flavor admin -t lib/main_admin.dart
    flutter build apk --flavor customer -t lib/main_customer.dart

  This fallback main should NEVER be called in production.
*/

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Emergency fallback if flavor-specific main is not used
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'ERROR: Wrong Entry Point',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This app must be built with flavor-specific entry points.\n\n'
                  'Use:\n'
                  'flutter build apk --flavor barber -t lib/main_barber.dart\n'
                  'flutter build apk --flavor customer -t lib/main_customer.dart\n'
                  'flutter build apk --flavor admin -t lib/main_admin.dart',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
