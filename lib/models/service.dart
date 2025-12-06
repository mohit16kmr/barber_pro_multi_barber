import 'package:equatable/equatable.dart';

/// Service Model for Barber Services
class Service extends Equatable {
  final String name;
  final double price;
  final int durationMinutes; // Duration in minutes

  const Service({
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      durationMinutes: json['durationMinutes'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
    };
  }

  Service copyWith({
    String? name,
    double? price,
    int? durationMinutes,
  }) {
    return Service(
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [name, price, durationMinutes];
}
