import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Barber Income Model - tracks individual barber earnings
class BarberIncome extends Equatable {
  final String incomeId;
  final String barberId; // User ID of barber
  final String shopId; // Shop where barber works
  final double dailyEarnings; // Earnings for this day
  final double monthlyEarnings; // Cumulative earnings for this month
  final double totalEarnings; // Total earnings lifetime
  final int bookingsCompleted; // Number of completed bookings today
  final int monthlyBookings; // Bookings this month
  final int totalBookings; // Total bookings lifetime
  final DateTime date; // Date for daily earnings
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarberIncome({
    required this.incomeId,
    required this.barberId,
    required this.shopId,
    this.dailyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.totalEarnings = 0.0,
    this.bookingsCompleted = 0,
    this.monthlyBookings = 0,
    this.totalBookings = 0,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BarberIncome.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarberIncome(
      incomeId: doc.id,
      barberId: data['barberId'] ?? '',
      shopId: data['shopId'] ?? '',
      dailyEarnings: (data['dailyEarnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (data['monthlyEarnings'] ?? 0.0).toDouble(),
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      bookingsCompleted: data['bookingsCompleted'] ?? 0,
      monthlyBookings: data['monthlyBookings'] ?? 0,
      totalBookings: data['totalBookings'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barberId': barberId,
      'shopId': shopId,
      'dailyEarnings': dailyEarnings,
      'monthlyEarnings': monthlyEarnings,
      'totalEarnings': totalEarnings,
      'bookingsCompleted': bookingsCompleted,
      'monthlyBookings': monthlyBookings,
      'totalBookings': totalBookings,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BarberIncome copyWith({
    String? incomeId,
    String? barberId,
    String? shopId,
    double? dailyEarnings,
    double? monthlyEarnings,
    double? totalEarnings,
    int? bookingsCompleted,
    int? monthlyBookings,
    int? totalBookings,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarberIncome(
      incomeId: incomeId ?? this.incomeId,
      barberId: barberId ?? this.barberId,
      shopId: shopId ?? this.shopId,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      bookingsCompleted: bookingsCompleted ?? this.bookingsCompleted,
      monthlyBookings: monthlyBookings ?? this.monthlyBookings,
      totalBookings: totalBookings ?? this.totalBookings,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        incomeId,
        barberId,
        shopId,
        dailyEarnings,
        monthlyEarnings,
        totalEarnings,
        bookingsCompleted,
        monthlyBookings,
        totalBookings,
        date,
        createdAt,
        updatedAt,
      ];
}
