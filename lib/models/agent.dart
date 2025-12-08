import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Agent Model - represents a sales/registration agent
/// Agents register barber shops and get credit/commission
class Agent extends Equatable {
  final String agentId;
  final String name;
  final String email;
  final String phone;
  final int shopsCount; // Number of shops registered by this agent
  final List<String>
  shopIds; // List of barber shop IDs registered by this agent
  final double commissionRate; // Commission percentage (e.g., 5.0 = 5%)
  final double totalCommission; // Total commission earned
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Agent({
    required this.agentId,
    required this.name,
    required this.email,
    required this.phone,
    this.shopsCount = 0,
    this.shopIds = const [],
    this.commissionRate = 0.0,
    this.totalCommission = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Agent(
      agentId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      shopsCount: data['shopsCount'] ?? 0,
      shopIds: List<String>.from(data['shopIds'] ?? []),
      commissionRate: (data['commissionRate'] ?? 0.0).toDouble(),
      totalCommission: (data['totalCommission'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'shopsCount': shopsCount,
      'shopIds': shopIds,
      'commissionRate': commissionRate,
      'totalCommission': totalCommission,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Agent copyWith({
    String? agentId,
    String? name,
    String? email,
    String? phone,
    int? shopsCount,
    List<String>? shopIds,
    double? commissionRate,
    double? totalCommission,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agent(
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      shopsCount: shopsCount ?? this.shopsCount,
      shopIds: shopIds ?? this.shopIds,
      commissionRate: commissionRate ?? this.commissionRate,
      totalCommission: totalCommission ?? this.totalCommission,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    agentId,
    name,
    email,
    phone,
    shopsCount,
    shopIds,
    commissionRate,
    totalCommission,
    isActive,
    createdAt,
    updatedAt,
  ];
}
