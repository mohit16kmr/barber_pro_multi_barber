import 'package:equatable/equatable.dart';

/// Team Member Model for barber shop team
class TeamMember extends Equatable {
  final String name;
  final String phone;
  final String? specialization; // e.g., "Haircut", "Beard", "Coloring"
  final bool isActive;

  const TeamMember({
    required this.name,
    required this.phone,
    this.specialization,
    this.isActive = true,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      specialization: json['specialization'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'specialization': specialization,
      'isActive': isActive,
    };
  }

  TeamMember copyWith({
    String? name,
    String? phone,
    String? specialization,
    bool? isActive,
  }) {
    return TeamMember(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [name, phone, specialization, isActive];
}
