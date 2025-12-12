import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:barber_pro_multi_barber/config/flavor_config.dart';

/// Small helper to prevent cross-flavor navigation at runtime.
/// Use `flavorSafeGo(context, path)` instead of `context.go(path)` when
/// a screen might be shared between flavors.
void flavorSafeGo(BuildContext context, String path) {
  final isBarber = FlavorConfig.isBarber;
  final isAdmin = FlavorConfig.isAdmin;

  // Define customer and barber route prefixes (kept small and intentional)
  final customerPrefixes = <String>[
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

  final barberPrefixes = <String>[
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

  // Prevent barber flavor from navigating to customer routes
  if (isBarber) {
    if (customerPrefixes.any((p) => path.startsWith(p))) {
      // Silently block and optionally log for debugging
      // ignore: avoid_print
      print('Blocked navigation to customer route "$path" in barber flavor');
      return;
    }
  }

  // Prevent customer flavor from navigating to barber routes
  if (!isBarber && !isAdmin) {
    if (barberPrefixes.any((p) => path.startsWith(p))) {
      // ignore: avoid_print
      print('Blocked navigation to barber route "$path" in customer flavor');
      return;
    }
  }

  // Admin is allowed everywhere by design
  context.go(path);
}
