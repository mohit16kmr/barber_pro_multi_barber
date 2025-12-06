import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Barber Queue Model - represents customer queue for each barber
class BarberQueue extends Equatable {
  final String queueId;
  final String barberId; // Barber serving the customer
  final String shopId; // Shop
  final String customerId; // Customer in queue
  final String customerName;
  final String? customerPhone;
  final String serviceType; // Service: Haircut, Beard Trim, etc.
  final double servicePrice;
  final DateTime bookingTime; // When customer is expected
  final String status; // 'waiting', 'serving', 'completed', 'cancelled'
  final DateTime? completedAt;
  final double? rating; // Customer rating after service
  final String? review; // Customer review after service
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarberQueue({
    required this.queueId,
    required this.barberId,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.serviceType,
    required this.servicePrice,
    required this.bookingTime,
    this.status = 'waiting',
    this.completedAt,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BarberQueue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarberQueue(
      queueId: doc.id,
      barberId: data['barberId'] ?? '',
      shopId: data['shopId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'],
      serviceType: data['serviceType'] ?? '',
      servicePrice: (data['servicePrice'] ?? 0.0).toDouble(),
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'waiting',
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      rating:
          data['rating'] is num ? (data['rating'] as num).toDouble() : null,
      review: data['review'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barberId': barberId,
      'shopId': shopId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceType': serviceType,
      'servicePrice': servicePrice,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'status': status,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BarberQueue copyWith({
    String? queueId,
    String? barberId,
    String? shopId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? serviceType,
    double? servicePrice,
    DateTime? bookingTime,
    String? status,
    DateTime? completedAt,
    double? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarberQueue(
      queueId: queueId ?? this.queueId,
      barberId: barberId ?? this.barberId,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceType: serviceType ?? this.serviceType,
      servicePrice: servicePrice ?? this.servicePrice,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        queueId,
        barberId,
        shopId,
        customerId,
        customerName,
        customerPhone,
        serviceType,
        servicePrice,
        bookingTime,
        status,
        completedAt,
        rating,
        review,
        createdAt,
        updatedAt,
      ];
}
