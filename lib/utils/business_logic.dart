import 'package:barber_pro/models/index.dart';

/// Business Logic Utilities for BarberPro

/// Calculate wait time for a position in queue
/// [queueServiceDurations]: List of service durations in queue before the customer
/// Returns estimated wait time in minutes
int calculateWaitTime(List<int> queueServiceDurations) {
  if (queueServiceDurations.isEmpty) return 0;
  return queueServiceDurations.fold<int>(0, (sum, duration) => sum + duration);
}

/// Generate a unique token number for a barber
/// This is typically handled by Firestore transactions
/// [currentToken]: Current token number for the barber
/// Returns next token number (incremented)
int generateTokenNumber(int currentToken) {
  return currentToken + 1;
}

/// Filter barbers by least busy (smallest queue)
/// [barbers]: List of Barber objects
/// [limit]: Maximum number to return
List<Barber> getLeastBusyBarbers(List<Barber> barbers, {int limit = 5}) {
  // Filter online barbers not on break
  final availableBarbers = barbers
      .where((barber) => barber.isOnline && !_isBarberOnBreak(barber))
      .toList();

  // Sort by queue length (ascending)
  availableBarbers.sort((a, b) => a.queueLength.compareTo(b.queueLength));

  // Return top N
  return availableBarbers.take(limit).toList();
}

/// Check if barber is currently on break
bool _isBarberOnBreak(Barber barber) {
  final now = DateTime.now();
  for (final breakTime in barber.breakTimes) {
    final start = DateTime.parse(breakTime['startTime'] as String);
    final end = DateTime.parse(breakTime['endTime'] as String);
    if (now.isAfter(start) && now.isBefore(end)) {
      return true;
    }
  }
  return false;
}

/// Calculate estimated wait time based on position in queue
/// [bookingServices]: Services booked by current customer
/// [queueServices]: Services of customers before
/// Returns estimated wait time in minutes
int calculateEstimatedWaitTime(
  List<Service> bookingServices,
  List<List<Service>> queueServices,
) {
  int totalMinutes = 0;

  // Sum duration of all services in queue
  for (final services in queueServices) {
    for (final service in services) {
      totalMinutes += service.durationMinutes;
    }
  }

  // Add buffer (optional): 2 minutes per customer for transitions
  totalMinutes += (queueServices.length * 2);

  return totalMinutes;
}
