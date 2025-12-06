import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/flavor_config.dart';
// firebase_options.dart not required for Android flavor init when using
// flavor-specific google-services.json
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
// dev flags and fake services removed; using real services via providers
import 'providers/barber_provider.dart';
import 'providers/booking_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set flavor config for CUSTOMER
  FlavorConfig.setFlavor(
    AppFlavor.customer,
    'BarberPro Customer',
    'com.barberpro.customer',
  );
  try {
    // On Android/iOS, prefer the native google-services.json placed in
    // android/app/src/customer/google-services.json so the correct
    // Firebase app client is selected for this flavor.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Create and initialize AuthProvider before running the app so routing
  // can reflect the correct initial auth state.
  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  // Initialize ThemeProvider (loads saved preferences)
  final themeProvider = await ThemeProvider.create();

  runApp(MyApp(authProvider: authProvider, themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.authProvider, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use the already-initialized authProvider and themeProvider instances
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => BarberProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: Builder(builder: (context) {
        // Create router using the provider's auth state stream so redirects
        // are based on the same auth state the provider exposes.
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
