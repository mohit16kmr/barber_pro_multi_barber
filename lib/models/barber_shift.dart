import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Barber Shift Model - tracks barber's online/offline status and availability
class BarberShift extends Equatable {
  final String shiftId;
  final String barberId; // User ID of barber
  final String shopId; // Shop where barber is working
  final DateTime startTime;
  final DateTime? endTime; // null if shift ongoing
  final bool isOnline; // true = online/available, false = offline
  final double totalEarnings; // Earnings for this shift
  final int totalCustomersServed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarberShift({
    required this.shiftId,
    required this.barberId,
    required this.shopId,
    required this.startTime,
    this.endTime,
    this.isOnline = true,
    this.totalEarnings = 0.0,
    this.totalCustomersServed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BarberShift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarberShift(
      shiftId: doc.id,
      barberId: data['barberId'] ?? '',
      shopId: data['shopId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] ?? true,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      totalCustomersServed: data['totalCustomersServed'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barberId': barberId,
      'shopId': shopId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'isOnline': isOnline,
      'totalEarnings': totalEarnings,
      'totalCustomersServed': totalCustomersServed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BarberShift copyWith({
    String? shiftId,
    String? barberId,
    String? shopId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isOnline,
    double? totalEarnings,
    int? totalCustomersServed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarberShift(
      shiftId: shiftId ?? this.shiftId,
      barberId: barberId ?? this.barberId,
      shopId: shopId ?? this.shopId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isOnline: isOnline ?? this.isOnline,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalCustomersServed: totalCustomersServed ?? this.totalCustomersServed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    shiftId,
    barberId,
    shopId,
    startTime,
    endTime,
    isOnline,
    totalEarnings,
    totalCustomersServed,
    createdAt,
    updatedAt,
  ];
}
