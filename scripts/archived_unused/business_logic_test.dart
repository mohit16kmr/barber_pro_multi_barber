import 'package:flutter_test/flutter_test.dart';
import 'package:barber_pro/models/index.dart';
import 'package:barber_pro/utils/business_logic.dart';

void main() {
  group('Business Logic Tests', () {
    group('calculateWaitTime', () {
      test('returns 0 for empty queue', () {
        final result = calculateWaitTime([]);
        expect(result, equals(0));
      });

      test('returns correct total duration for single service', () {
        final result = calculateWaitTime([30]);
        expect(result, equals(30));
      });

      test('returns correct total duration for multiple services', () {
        final result = calculateWaitTime([30, 45, 20]);
        expect(result, equals(95));
      });

      test('handles large queue', () {
        final durations = List<int>.filled(50, 30);
        final result = calculateWaitTime(durations);
        expect(result, equals(1500));
      });
    });

    group('generateTokenNumber', () {
      test('increments token correctly', () {
        expect(generateTokenNumber(0), equals(1));
        expect(generateTokenNumber(1), equals(2));
        expect(generateTokenNumber(99), equals(100));
      });

      test('works with large numbers', () {
        expect(generateTokenNumber(999999), equals(1000000));
      });
    });

    group('calculateEstimatedWaitTime', () {
      test('returns 0 for empty queue', () {
        final services = [Service(name: 'Haircut', price: 10, durationMinutes: 30)];
        final result = calculateEstimatedWaitTime(services, []);
        expect(result, equals(0));
      });

      test('calculates correctly for single customer in queue', () {
        final myServices = [
          Service(name: 'Haircut', price: 10, durationMinutes: 30)
        ];
        final queueServices = [
          [Service(name: 'Haircut', price: 10, durationMinutes: 30)]
        ];
        final result = calculateEstimatedWaitTime(myServices, queueServices);
        // 30 (queue) + 2 (buffer) = 32
        expect(result, equals(32));
      });

      test('calculates correctly for multiple customers in queue', () {
        final myServices = [
          Service(name: 'Haircut', price: 10, durationMinutes: 30)
        ];
        final queueServices = [
          [Service(name: 'Haircut', price: 10, durationMinutes: 30)],
          [Service(name: 'Trim', price: 8, durationMinutes: 20)],
          [Service(name: 'Beard Trim', price: 5, durationMinutes: 15)],
        ];
        final result = calculateEstimatedWaitTime(myServices, queueServices);
        // (30 + 20 + 15) + (3 * 2) = 71
        expect(result, equals(71));
      });

      test('handles multiple services per customer', () {
        final myServices = [
          Service(name: 'Haircut', price: 10, durationMinutes: 30)
        ];
        final queueServices = [
          [
            Service(name: 'Haircut', price: 10, durationMinutes: 30),
            Service(name: 'Beard Trim', price: 5, durationMinutes: 15),
          ],
        ];
        final result = calculateEstimatedWaitTime(myServices, queueServices);
        // (30 + 15) + (1 * 2) = 47
        expect(result, equals(47));
      });
    });

    group('getLeastBusyBarbers', () {
      test('returns empty list for empty input', () {
        final result = getLeastBusyBarbers([]);
        expect(result, isEmpty);
      });

      test('returns barbers sorted by queue length ascending', () {
        final barbers = [
          Barber(
            barberId: '1',
            shopName: 'Shop 1',
            ownerName: 'Owner 1',
            phone: '123',
            address: 'Address 1',
            queueLength: 10,
            isOnline: true,
            createdAt: DateTime.now(),
          ),
          Barber(
            barberId: '2',
            shopName: 'Shop 2',
            ownerName: 'Owner 2',
            phone: '456',
            address: 'Address 2',
            queueLength: 5,
            isOnline: true,
            createdAt: DateTime.now(),
          ),
          Barber(
            barberId: '3',
            shopName: 'Shop 3',
            ownerName: 'Owner 3',
            phone: '789',
            address: 'Address 3',
            queueLength: 15,
            isOnline: true,
            createdAt: DateTime.now(),
          ),
        ];

        final result = getLeastBusyBarbers(barbers, limit: 2);
        expect(result.length, equals(2));
        expect(result[0].queueLength, equals(5));
        expect(result[1].queueLength, equals(10));
      });

      test('excludes offline barbers', () {
        final barbers = [
          Barber(
            barberId: '1',
            shopName: 'Shop 1',
            ownerName: 'Owner 1',
            phone: '123',
            address: 'Address 1',
            queueLength: 5,
            isOnline: false,
            createdAt: DateTime.now(),
          ),
          Barber(
            barberId: '2',
            shopName: 'Shop 2',
            ownerName: 'Owner 2',
            phone: '456',
            address: 'Address 2',
            queueLength: 10,
            isOnline: true,
            createdAt: DateTime.now(),
          ),
        ];

        final result = getLeastBusyBarbers(barbers);
        expect(result.length, equals(1));
        expect(result[0].barberId, equals('2'));
      });

      test('respects limit parameter', () {
        final barbers = List<Barber>.generate(
          10,
          (index) => Barber(
            barberId: '$index',
            shopName: 'Shop $index',
            ownerName: 'Owner $index',
            phone: '$index',
            address: 'Address $index',
            queueLength: index,
            isOnline: true,
            createdAt: DateTime.now(),
          ),
        );

        final result = getLeastBusyBarbers(barbers, limit: 3);
        expect(result.length, equals(3));
      });
    });
  });
}
