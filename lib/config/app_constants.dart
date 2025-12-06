/// App Constants for BarberPro
class AppConstants {
  // App Name
  static const String appName = 'BarberPro';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String barbersCollection = 'barbers';
  static const String bookingsCollection = 'bookings';
  static const String adminsCollection = 'admins';
  static const String agentsCollection = 'agents';

  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeBarber = 'barber';
  static const String userTypeAdmin = 'admin';

  // Booking Status
  static const String bookingStatusWaiting = 'waiting';
  static const String bookingStatusNext = 'next';
  static const String bookingStatusServing = 'serving';
  static const String bookingStatusCompleted = 'completed';
  static const String bookingStatusCancelled = 'cancelled';
  static const String bookingStatusSkipped = 'skipped';

  // Payment Methods
  static const String paymentMethodCash = 'cash';

  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';

  // Grace Period (minutes)
  static const int gracePeriodMinutes = 5;

  // Timeout durations
  static const Duration firebaseTimeout = Duration(seconds: 10);
  static const Duration notificationDelay = Duration(seconds: 10);

  // Thresholds
  static const int notificationWaitTimeMinutes1 = 30;
  static const int notificationWaitTimeMinutes2 = 10;
  static const int maxConcurrentUsers = 100;

  // Locations (for Phase 1 - manual dropdown)
  static const List<String> defaultLocations = [
    'Downtown',
    'Midtown',
    'Uptown',
    'Suburbs',
    'Airport Area',
  ];

  // Paths for shared preferences
  static const String prefKeyAuthToken = 'auth_token';
  static const String prefKeyUserId = 'user_id';
  static const String prefKeyUserType = 'user_type';
  static const String prefKeyUserData = 'user_data';
  static const String prefKeyBarbersList = 'barbers_list';
  static const String prefKeyLastSync = 'last_sync';
}
