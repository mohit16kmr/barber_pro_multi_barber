import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Barber Shop Model - represents a physical shop/salon
class Shop extends Equatable {
  final String shopId;
  final String shopName;
  final String ownerUid; // User ID of shop owner
  final String ownerName;
  final String phone;
  final String address;
  final String city;
  final String state;
  final Map<String, dynamic>? location; // {latitude, longitude}
  final String? shopPhotoUrl; // Shop photo/branding image
  final List<String> barberIds; // List of User IDs of barbers in this shop
  final List<String> serviceCategories; // Services offered: Haircut, Beard Trim, etc.
  final Map<String, dynamic>? workingHours; // {monday: {open: '09:00', close: '18:00'}, ...}
  final double rating;
  final int totalReviews;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Shop({
    required this.shopId,
    required this.shopName,
    required this.ownerUid,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    this.location,
    this.shopPhotoUrl,
    this.barberIds = const [],
    this.serviceCategories = const [],
    this.workingHours,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shop(
      shopId: doc.id,
      shopName: data['shopName'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      location: data['location'],
      shopPhotoUrl: data['shopPhotoUrl'],
      barberIds: List<String>.from(data['barberIds'] ?? []),
      serviceCategories:
          List<String>.from(data['serviceCategories'] ?? []),
      workingHours: data['workingHours'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      verified: data['verified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'location': location,
      'shopPhotoUrl': shopPhotoUrl,
      'barberIds': barberIds,
      'serviceCategories': serviceCategories,
      'workingHours': workingHours,
      'rating': rating,
      'totalReviews': totalReviews,
      'verified': verified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  Shop copyWith({
    String? shopId,
    String? shopName,
    String? ownerUid,
    String? ownerName,
    String? phone,
    String? address,
    String? city,
    String? state,
    Map<String, dynamic>? location,
    String? shopPhotoUrl,
    List<String>? barberIds,
    List<String>? serviceCategories,
    Map<String, dynamic>? workingHours,
    double? rating,
    int? totalReviews,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Shop(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      location: location ?? this.location,
      shopPhotoUrl: shopPhotoUrl ?? this.shopPhotoUrl,
      barberIds: barberIds ?? this.barberIds,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        shopId,
        shopName,
        ownerUid,
        ownerName,
        phone,
        address,
        city,
        state,
        location,
        shopPhotoUrl,
        barberIds,
        serviceCategories,
        workingHours,
        rating,
        totalReviews,
        verified,
        createdAt,
        updatedAt,
        isActive,
      ];
}
