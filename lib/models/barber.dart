import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'service.dart';

/// Barber Shop Model
class Barber extends Equatable {
  final String barberId;
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final Map<String, dynamic>?
  location; // {latitude, longitude} or manual location
  final List<Service> services;
  final List<String> photos;
  final List<Map<String, dynamic>> queue; // List of booking tokens
  final int currentToken;
  final int queueLength;
  final String? referralCode;
  final String? shopId;
  final bool isOnline;
  final List<Map<String, dynamic>> breakTimes; // {startTime, endTime}
  final List<DateTime> holidays;
  final double rating;
  final bool verified;
  final double totalEarnings;
  final DateTime createdAt;
  final Map<String, dynamic>?
  workingHours; // {monday: {open: '09:00', close: '18:00'}, ...}
  final Map<String, dynamic>? region; // {state, district, block, town, village}

  const Barber({
    required this.barberId,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.shopId,
    this.location,
    this.services = const [],
    this.photos = const [],
    this.queue = const [],
    this.currentToken = 0,
    this.queueLength = 0,
    this.referralCode,
    this.isOnline = false,
    this.breakTimes = const [],
    this.holidays = const [],
    this.rating = 0.0,
    this.verified = false,
    this.totalEarnings = 0.0,
    required this.createdAt,
    this.workingHours,
    this.region,
  });

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Barber(
      barberId: doc.id,
      shopName: data['shopName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      shopId: data['shopId'],
      location: data['location'],
      services:
          (data['services'] as List<dynamic>?)
              ?.map((s) => Service.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      photos: List<String>.from(data['photos'] ?? []),
      queue: List<Map<String, dynamic>>.from(data['queue'] ?? []),
      currentToken: data['currentToken'] ?? 0,
      queueLength: data['queueLength'] ?? 0,
      referralCode: data['referralCode'],
      isOnline: data['isOnline'] ?? false,
      breakTimes: List<Map<String, dynamic>>.from(data['breakTimes'] ?? []),
      holidays:
          (data['holidays'] as List<dynamic>?)
              ?.map((h) => (h as Timestamp).toDate())
              .toList() ??
          [],
      rating: (data['rating'] ?? 0.0).toDouble(),
      verified: data['verified'] ?? false,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      workingHours: data['workingHours'],
      region: data['region'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'shopId': shopId,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'location': location,
      'services': services.map((s) => s.toJson()).toList(),
      'photos': photos,
      'queue': queue,
      'currentToken': currentToken,
      'queueLength': queueLength,
      'referralCode': referralCode,
      'isOnline': isOnline,
      'breakTimes': breakTimes,
      'holidays': holidays.map((h) => Timestamp.fromDate(h)).toList(),
      'rating': rating,
      'verified': verified,
      'totalEarnings': totalEarnings,
      'createdAt': Timestamp.fromDate(createdAt),
      'workingHours': workingHours,
      'region': region,
    };
  }

  Barber copyWith({
    String? barberId,
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? shopId,
    Map<String, dynamic>? location,
    List<Service>? services,
    List<String>? photos,
    List<Map<String, dynamic>>? queue,
    int? currentToken,
    int? queueLength,
    String? referralCode,
    bool? isOnline,
    List<Map<String, dynamic>>? breakTimes,
    List<DateTime>? holidays,
    double? rating,
    bool? verified,
    double? totalEarnings,
    DateTime? createdAt,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? region,
  }) {
    return Barber(
      barberId: barberId ?? this.barberId,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      shopId: shopId ?? this.shopId,
      location: location ?? this.location,
      services: services ?? this.services,
      photos: photos ?? this.photos,
      queue: queue ?? this.queue,
      currentToken: currentToken ?? this.currentToken,
      queueLength: queueLength ?? this.queueLength,
      referralCode: referralCode ?? this.referralCode,
      isOnline: isOnline ?? this.isOnline,
      breakTimes: breakTimes ?? this.breakTimes,
      holidays: holidays ?? this.holidays,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      workingHours: workingHours ?? this.workingHours,
      region: region ?? this.region,
    );
  }

  @override
  List<Object?> get props => [
    barberId,
    shopName,
    shopId,
    ownerName,
    phone,
    address,
    location,
    services,
    photos,
    queue,
    currentToken,
    queueLength,
    referralCode,
    isOnline,
    breakTimes,
    holidays,
    rating,
    verified,
    totalEarnings,
    createdAt,
    workingHours,
    region,
  ];
}
