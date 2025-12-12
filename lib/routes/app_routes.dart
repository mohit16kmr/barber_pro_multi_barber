import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro_multi_barber/providers/auth_provider.dart';
import 'package:barber_pro_multi_barber/config/flavor_config.dart';
import 'package:barber_pro_multi_barber/screens/auth/splash_screen.dart';
import 'package:barber_pro_multi_barber/screens/auth/login_screen.dart';
import 'package:barber_pro_multi_barber/screens/auth/signup_screen.dart';
import 'package:barber_pro_multi_barber/screens/auth/forgot_password_screen.dart';
import 'package:barber_pro_multi_barber/screens/app_shell.dart';
import 'package:barber_pro_multi_barber/screens/discovery/barber_list_screen.dart';
import 'package:barber_pro_multi_barber/screens/booking/barber_details_screen.dart';
import 'package:barber_pro_multi_barber/screens/customer/home_screen.dart';
import 'package:barber_pro_multi_barber/screens/customer/profile_screen.dart';
import 'package:barber_pro_multi_barber/screens/customer/edit_profile_screen.dart';
import 'package:barber_pro_multi_barber/screens/customer/settings_screen.dart';
import 'package:barber_pro_multi_barber/screens/customer/bookings_list_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_home_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_management_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_availability_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_profile_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_edit_profile_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_settings_screen.dart';
import 'package:barber_pro_multi_barber/screens/barber/barber_queue_screen.dart';
// removed barber_earnings_screen import; using shop earnings dashboard for barber user
import 'package:barber_pro_multi_barber/screens/barber/shop_earnings_dashboard_screen.dart';
import 'package:barber_pro_multi_barber/screens/admin/admin_dashboard_screen.dart';
import 'package:barber_pro_multi_barber/screens/admin/admin_shop_management_screen.dart';
import 'package:barber_pro_multi_barber/screens/admin/admin_reports_screen.dart';
import 'package:barber_pro_multi_barber/screens/admin/admin_agent_management_screen.dart';
import 'dart:async';

/// Simple helper to convert a Stream into a GoRouter-compatible Listenable.
/// This mirrors the helper available in some go_router examples but avoids
/// requiring a specific package version.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Immediately notify to ensure initial evaluation
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners(), onError: (_) {});
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Route names for easy navigation
class AppRoute {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String discovery = 'discovery';
  static const String booking = 'booking';
  static const String bookings = 'bookings';
  static const String queue = 'queue';
  static const String bookingDetails = 'booking-details';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String editProfile = 'edit-profile';
  static const String barberHome = 'barber-home';
  static const String barberManagement = 'barber-management';
  static const String barberAvailability = 'barber-availability';
  static const String queueManagement = 'queue-management';
  static const String barberProfile = 'barber-profile';
  static const String barberEditProfile = 'barber-edit-profile';
  static const String barberSettings = 'barber-settings';
  static const String barberQueue = 'barber-queue';
  static const String barberEarnings = 'barber-earnings';
  static const String shopEarnings = 'shop-earnings';
  static const String adminDashboard = 'admin-dashboard';
  static const String adminShopManagement = 'admin-shop-management';
  static const String adminReports = 'admin-reports';
  static const String adminAgents = 'admin-agents';
}

/// GoRouter configuration factory.
/// Use `createAppRouter(authProvider.authStateChanges)` from `main_*` files
/// so the router listens to the same auth stream the providers use.
GoRouter createAppRouter(Stream<dynamic> authStateStream) {
  final flavorIsBarber = FlavorConfig.isBarber;
  final flavorIsAdmin = FlavorConfig.isAdmin;

  return GoRouter(
    /// Initial location based on auth state
    initialLocation: '/splash',
    // Re-evaluate redirects when Firebase auth state changes.
    refreshListenable: GoRouterRefreshStream(authStateStream),

    /// Redirect logic: handle auth state changes AND enforce flavor-based route access
    redirect: (context, state) {
      // Read auth state without listening here; GoRouter refreshListenable
      // is used to trigger redirect re-evaluation when auth changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final location = state.uri.path;

      // FLAVOR-BASED ROUTE GATING: Prevent access to routes not intended for this flavor
      // Admin flavor should ONLY see admin routes
      if (flavorIsAdmin) {
        final adminRoutes = [
          '/splash',
          '/login',
          '/signup',
          '/forgot-password',
          '/admin-dashboard',
          '/admin-shop-management',
          '/admin-reports',
          '/admin-agents',
        ];
        if (!adminRoutes.any((route) => location.startsWith(route))) {
          if (isLoggedIn) return '/admin-dashboard';
          return '/login';
        }
      }

      // Barber flavor should ONLY see barber routes (NO customer routes like /discovery, /home)
      if (flavorIsBarber) {
        final barberRoutes = [
          '/splash',
          '/login',
          '/signup',
          '/forgot-password',
          '/barber-home',
          '/barber-list',
          '/barber-profile',
          '/barber-edit-profile',
          '/barber-settings',
          '/barber-queue',
          '/barber-earnings',
          '/shop-earnings',
          '/barber-availability',
        ];

        // ALSO block customer routes explicitly
        final customerRoutes = [
          '/home',
          '/discovery',
          '/bookings',
          '/booking',
          '/queue',
          '/booking-details',
          '/profile',
          '/settings',
          '/edit-profile',
        ];

        // If trying to access customer route, redirect to barber home
        if (customerRoutes.any((route) => location.startsWith(route))) {
          if (isLoggedIn) return '/barber-home';
          return '/login';
        }

        // If trying to access non-barber route, redirect
        if (!barberRoutes.any((route) => location.startsWith(route))) {
          if (isLoggedIn) return '/barber-home';
          return '/login';
        }
      }

      // Customer flavor should ONLY see customer routes (NO barber routes)
      if (!flavorIsAdmin && !flavorIsBarber) {
        final customerRoutes = [
          '/splash',
          '/login',
          '/signup',
          '/forgot-password',
          '/home',
          '/discovery',
          '/bookings',
          '/booking',
          '/queue',
          '/booking-details',
          '/profile',
          '/settings',
          '/edit-profile',
        ];

        // ALSO block barber routes explicitly
        final barberRoutes = [
          '/barber-home',
          '/barber-list',
          '/barber-profile',
          '/barber-edit-profile',
          '/barber-settings',
          '/barber-queue',
          '/barber-earnings',
          '/shop-earnings',
          '/barber-availability',
        ];

        // If trying to access barber route, redirect to home
        if (barberRoutes.any((route) => location.startsWith(route))) {
          if (isLoggedIn) return '/home';
          return '/login';
        }

        // If trying to access non-customer route, redirect
        if (!customerRoutes.any((route) => location.startsWith(route))) {
          if (isLoggedIn) return '/home';
          return '/login';
        }
      }

      final isGoingToAuth =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/splash';

      // If not authenticated, go to login (except splash/auth routes)
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      // If authenticated and on auth page, normally go to home
      // EXCEPTION: if the user *needs registration* (external provider sign-in)
      // allow them to remain on `/signup` so they can complete their profile.
      if (isLoggedIn && isGoingToAuth && location != '/splash') {
        final needsRegistration = authProvider.needsRegistration;
        if (needsRegistration && location == '/signup') {
          // Allow the signup page so the user can complete registration
          return null;
        }

        if (flavorIsAdmin) return '/admin-dashboard';
        if (flavorIsBarber) return '/barber-home';
        return '/home';
      }

      // Splash screen: check auth and route accordingly
      if (location == '/splash' && isLoggedIn) {
        if (flavorIsAdmin) return '/admin-dashboard';
        if (flavorIsBarber) return '/barber-home';
        return '/home';
      }

      return null; // No redirect needed
    },

    /// Routes definition - FLAVOR-AWARE
    routes: [
      /// Splash & Auth Routes (always available)
      GoRoute(
        path: '/splash',
        name: AppRoute.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoute.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      /// Customer Routes (ONLY for customer flavor)
      if (!flavorIsAdmin && !flavorIsBarber)
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(userType: 'customer', child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              name: AppRoute.home,
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/discovery',
              name: AppRoute.discovery,
              builder: (context, state) => const BarberListScreen(),
            ),
            GoRoute(
              path: '/bookings',
              name: AppRoute.bookings,
              builder: (context, state) => const BookingsListScreen(),
            ),
            GoRoute(
              path: '/booking/:barberId',
              name: AppRoute.booking,
              builder: (context, state) {
                final barberId = state.pathParameters['barberId'] ?? '';
                return BarberDetailsScreen(barberId: barberId);
              },
            ),
            GoRoute(
              path: '/queue/:bookingId',
              name: AppRoute.queue,
              builder: (context, state) {
                final bookingId = state.pathParameters['bookingId'] ?? '';
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Queue Screen for Booking: $bookingId - Coming Soon',
                    ),
                  ),
                );
              },
            ),
            GoRoute(
              path: '/booking-details/:bookingId',
              name: AppRoute.bookingDetails,
              builder: (context, state) {
                final bookingId = state.pathParameters['bookingId'] ?? '';
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Booking Details for: $bookingId - Coming Soon',
                    ),
                  ),
                );
              },
            ),
            GoRoute(
              path: '/profile',
              name: AppRoute.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: AppRoute.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/edit-profile',
              name: AppRoute.editProfile,
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),

      /// Barber Routes (ONLY for barber flavor)
      if (flavorIsBarber)
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(userType: 'barber', child: child);
          },
          routes: [
            GoRoute(
              path: '/barber-home',
              name: AppRoute.barberHome,
              builder: (context, state) => const BarberHomeScreen(),
            ),
            GoRoute(
              path: '/barber-list',
              name: AppRoute.barberManagement,
              builder: (context, state) => const BarberManagementScreen(),
            ),
            GoRoute(
              path: '/barber-availability',
              name: AppRoute.barberAvailability,
              builder: (context, state) => const BarberAvailabilityScreen(),
            ),
            GoRoute(
              path: '/queue-management/:barberId',
              name: AppRoute.queueManagement,
              builder: (context, state) {
                return const BarberQueueScreen();
              },
            ),
            GoRoute(
              path: '/barber-profile',
              name: AppRoute.barberProfile,
              builder: (context, state) => const BarberProfileScreen(),
            ),
            GoRoute(
              path: '/barber-edit-profile',
              name: AppRoute.barberEditProfile,
              builder: (context, state) => const BarberEditProfileScreen(),
            ),
            GoRoute(
              path: '/barber-settings',
              name: AppRoute.barberSettings,
              builder: (context, state) => const BarberSettingsScreen(),
            ),
            GoRoute(
              path: '/barber-queue',
              name: AppRoute.barberQueue,
              builder: (context, state) => const BarberQueueScreen(),
            ),
            GoRoute(
              path: '/barber-earnings',
              name: AppRoute.barberEarnings,
              builder: (context, state) => const ShopEarningsDashboardScreen(),
            ),
            GoRoute(
              path: '/shop-earnings',
              name: AppRoute.shopEarnings,
              builder: (context, state) => const ShopEarningsDashboardScreen(),
            ),
          ],
        ),

      /// Admin Routes (ONLY for admin flavor)
      if (flavorIsAdmin)
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(userType: 'admin', child: child);
          },
          routes: [
            GoRoute(
              path: '/admin-dashboard',
              name: AppRoute.adminDashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/admin-shop-management',
              name: AppRoute.adminShopManagement,
              builder: (context, state) => const AdminShopManagementScreen(),
            ),
            GoRoute(
              path: '/admin-reports',
              name: AppRoute.adminReports,
              builder: (context, state) => const AdminReportsScreen(),
            ),
            GoRoute(
              path: '/admin-agents',
              name: AppRoute.adminAgents,
              builder: (context, state) => const AdminAgentManagementScreen(),
            ),
          ],
        ),
    ],

    /// Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
