import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/flavor_config.dart';
// firebase_options.dart not required for Android flavor init when using
// flavor-specific google-services.json
import 'providers/auth_provider.dart';
import 'providers/barber_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set flavor config for BARBER
  FlavorConfig.setFlavor(
    AppFlavor.barber,
    'BarberPro Barber',
    'com.barberpro.barber',
  );
  
  try {
    // Prefer the flavor-specific google-services.json provided under
    // android/app/src/barber so the barber app uses its own Firebase client.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  // Prepare ThemeProvider (async factory) and BarberProvider instances
  final themeProvider = await ThemeProvider.create();
  final barberProvider = BarberProvider();

  // If a barber user is signed in, attempt to load/select their barber profile
  if (authProvider.isAuthenticated && authProvider.currentUser != null) {
    // Barber documents may be keyed by `shopId` (if the user belongs to a shop)
    // or by the user's UID. Try shopId first, then fall back to uid.
    final user = authProvider.currentUser!;
    final barberId = user.shopId ?? user.uid;
    final barber = await barberProvider.getBarberById(barberId);
    if (barber != null) {
      barberProvider.selectBarber(barber);
    }
  }

  runApp(MyApp(
    authProvider: authProvider,
    barberProvider: barberProvider,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final BarberProvider barberProvider;
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.barberProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: barberProvider),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Builder(builder: (context) {
        final router = createAppRouter(context.read<AuthProvider>().authStateChanges);
        return MaterialApp.router(
          title: FlavorConfig.displayName,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: context.watch<ThemeProvider>().themeMode,
          routerConfig: router,
        );
      }),
    );
  }
}
