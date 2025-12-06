import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'service.dart';

/// Booking Model
class Booking extends Equatable {
  final String bookingId;
  final String customerId;
  final String barberId;
  final int tokenNumber;
  final List<Service> services;
  final double totalPrice;
  final String status; // waiting, next, serving, completed, cancelled, skipped
  final String paymentMethod; // cash
  final String paymentStatus; // pending, completed
  final DateTime bookingTime;
  final int estimatedWaitTime; // in minutes
  final int? actualServiceTime; // in minutes
  final DateTime? completionTime;
  final String? cancellationReason;
  final String? cancelledBy; // customer, barber, system
  final double? rating;
  final String? review;

  const Booking({
    required this.bookingId,
    required this.customerId,
    required this.barberId,
    required this.tokenNumber,
    required this.services,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingTime,
    required this.estimatedWaitTime,
    this.actualServiceTime,
    this.completionTime,
    this.cancellationReason,
    this.cancelledBy,
    this.rating,
    this.review,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      customerId: data['customerId'] ?? '',
      barberId: data['barberId'] ?? '',
      tokenNumber: data['tokenNumber'] ?? 0,
      services: (data['services'] as List<dynamic>?)
              ?.map((s) => Service.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'waiting',
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      estimatedWaitTime: data['estimatedWaitTime'] ?? 0,
      actualServiceTime: data['actualServiceTime'],
      completionTime: data['completionTime'] != null
          ? (data['completionTime'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      cancelledBy: data['cancelledBy'],
      rating: data['rating']?.toDouble(),
      review: data['review'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'barberId': barberId,
      'tokenNumber': tokenNumber,
      'services': services.map((s) => s.toJson()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'estimatedWaitTime': estimatedWaitTime,
      'actualServiceTime': actualServiceTime,
      'completionTime': completionTime != null ? Timestamp.fromDate(completionTime!) : null,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'rating': rating,
      'review': review,
    };
  }

  Booking copyWith({
    String? bookingId,
    String? customerId,
    String? barberId,
    int? tokenNumber,
    List<Service>? services,
    double? totalPrice,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? bookingTime,
    int? estimatedWaitTime,
    int? actualServiceTime,
    DateTime? completionTime,
    String? cancellationReason,
    String? cancelledBy,
    double? rating,
    String? review,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      services: services ?? this.services,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingTime: bookingTime ?? this.bookingTime,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
      actualServiceTime: actualServiceTime ?? this.actualServiceTime,
      completionTime: completionTime ?? this.completionTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        customerId,
        barberId,
        tokenNumber,
        services,
        totalPrice,
        status,
        paymentMethod,
        paymentStatus,
        bookingTime,
        estimatedWaitTime,
        actualServiceTime,
        completionTime,
        cancellationReason,
        cancelledBy,
        rating,
        review,
      ];
}
