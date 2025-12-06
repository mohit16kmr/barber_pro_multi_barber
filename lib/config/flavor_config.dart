/// Flavor configuration for multi-app setup
enum AppFlavor { customer, barber, admin }

class FlavorConfig {
  static late AppFlavor _flavor;
  static late String _appName;
  static late String _appId;

  static void setFlavor(AppFlavor flavor, String appName, String appId) {
    _flavor = flavor;
    _appName = appName;
    _appId = appId;
  }

  static AppFlavor get flavor => _flavor;
  static String get appName => _appName;
  static String get appId => _appId;

  static bool get isCustomer => _flavor == AppFlavor.customer;
  static bool get isBarber => _flavor == AppFlavor.barber;
  static bool get isAdmin => _flavor == AppFlavor.admin;

  static String get flavorName => _flavor.name;

  /// Get app-specific display name for UI
  static String get displayName {
    switch (_flavor) {
      case AppFlavor.customer:
        return 'BarberPro - Customer';
      case AppFlavor.barber:
        return 'BarberPro - Barber';
      case AppFlavor.admin:
        return 'BarberPro - Admin';
    }
  }

  /// Get app-specific accent color
  static int get brandColor {
    switch (_flavor) {
      case AppFlavor.customer:
        return 0xFF1E88E5; // Blue
      case AppFlavor.barber:
        return 0xFF7B1FA2; // Purple
      case AppFlavor.admin:
        return 0xFFD32F2F; // Red
    }
  }
}
