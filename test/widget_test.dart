import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

// Use the customer flavor main which defines `MyApp` used in tests.
import 'package:barber_pro_multi_barber/main_customer.dart';
import 'package:barber_pro_multi_barber/providers/auth_provider.dart';
import 'package:barber_pro_multi_barber/providers/theme_provider.dart';
import 'package:barber_pro_multi_barber/services/fake_auth_service.dart';
import 'package:barber_pro_multi_barber/services/user_service_base.dart';
import 'package:barber_pro_multi_barber/models/index.dart';
import 'package:barber_pro_multi_barber/config/flavor_config.dart';
import 'package:barber_pro_multi_barber/services/barber_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:barber_pro_multi_barber/firebase_options.dart';

/// Lightweight in-memory user service for tests to avoid Firestore.
class _InMemoryUserService implements BaseUserService {
  final Map<String, User> _store = {};

  @override
  Future<void> createOrUpdateUser(User user) async {
    _store[user.uid] = user;
  }

  @override
  Future<User?> getUserById(String userId) async => _store[userId];

  @override
  Stream<User?> getUserStream(String userId) =>
      Stream<User?>.value(_store[userId]);

  @override
  Future<void> toggleFavoriteBarber(String userId, String barberId) async {}

  @override
  Future<void> updateLastLogin(String userId) async {}

  @override
  Future<void> deleteUser(String userId) async {
    _store.remove(userId);
  }

  @override
  Future<bool> userExists(String userId) async => _store.containsKey(userId);

  @override
  Future<List<User>> getAllUsers() async => _store.values.toList();

  @override
  Future<List<User>> searchUsersByName(String query) async => [];

  @override
  Future<void> switchUserRole(String userId, String newRole) async {}
}

/// Minimal fake AuthProvider for widget tests. Provides the
/// `authStateChanges` stream and `isAuthenticated` used by the router.
class TestAuthProvider extends AuthProvider {
  TestAuthProvider()
    : super(
        authService: FakeAuthService(),
        userService: _InMemoryUserService(),
        barberService: _FakeBarberService(),
      );

  @override
  // Return a stream that emits `null` once so GoRouter's refreshListenable
  // can consider the initial state without requiring Firebase.
  Stream<firebase_auth.User?> get authStateChanges =>
      Stream<firebase_auth.User?>.value(null);

  @override
  bool get isAuthenticated => false;
}

/// Minimal fake barber service to avoid Firestore in widget tests.
class _FakeBarberService extends BarberService {
  _FakeBarberService();

  @override
  Future<String> createBarberWithAgent({required Barber barber, String? referralCode}) async {
    return 'fake-barber-id';
  }

  @override
  Future<String> createBarber(Barber barber, {String? uid}) async {
    return uid ?? 'fake-barber-id';
  }

  @override
  Future<Barber?> getBarberById(String barberId) async => null;

  @override
  Stream<Barber?> getBarberStream(String barberId) => Stream.value(null);
}

void main() {
  testWidgets('MyApp renders successfully', (WidgetTester tester) async {
    // Ensure a flavor is set so MyApp can read displayName and theming.
    FlavorConfig.setFlavor(
      AppFlavor.customer,
      'BarberPro Test',
      'com.barberpro.test',
    );

    // Initialize Firebase for tests (use Android options for host VM)
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

    final fakeAuth = TestAuthProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
        ],
        child: MyApp(
          authProvider: fakeAuth,
          themeProvider: await ThemeProvider.create(),
        ),
      ),
    );

    // Allow GoRouter to settle
    await tester.pumpAndSettle();

    // Verify that the app renders with the title (fallback splash/home)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
