import 'package:intl/intl.dart';

/// Date and Time Utility Functions
class DateTimeUtils {
  /// Format DateTime to display time (HH:mm)
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format DateTime to display date (dd MMM yyyy)
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  /// Format DateTime to display full (dd MMM yyyy, HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Format DateTime to relative time (e.g., "2 minutes ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Get remaining time string (e.g., "30 minutes")
  static String formatDurationRemaining(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours h $mins m';
      }
    }
  }

  /// Get estimated completion time
  static String getEstimatedCompletionTime(int durationMinutes) {
    final completion = DateTime.now().add(Duration(minutes: durationMinutes));
    return formatTime(completion);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get day name from DateTime
  static String getDayName(DateTime dateTime) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dateTime.weekday - 1];
  }

  /// Check if a time is within working hours
  static bool isWithinWorkingHours(
    DateTime time,
    String openTime,
    String closeTime,
  ) {
    final now = DateFormat('HH:mm').format(time);
    return now.compareTo(openTime) >= 0 && now.compareTo(closeTime) <= 0;
  }

  /// Format service duration
  static String formatServiceDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours h';
      } else {
        return '$hours h $mins min';
      }
    }
  }

  /// Get current date as UTC
  static DateTime getNowUtc() {
    return DateTime.now().toUtc();
  }

  /// Convert local DateTime to UTC
  static DateTime toUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Convert UTC DateTime to local
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }
}
