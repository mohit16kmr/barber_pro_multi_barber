import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';

/// Admin Reports & Analytics - View detailed reports and trends
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'today'; // today, week, month, year

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Revenue Analytics
            _buildRevenueAnalytics(),
            const SizedBox(height: 24),

            // Barber Performance
            _buildBarberPerformanceAnalytics(),
            const SizedBox(height: 24),

            // Booking Analytics
            _buildBookingAnalytics(),
          ],
        ),
      ),
    );
  }

  /// Period Selector
  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _periodButton('Today', 'today'),
            _periodButton('Week', 'week'),
            _periodButton('Month', 'month'),
            _periodButton('Year', 'year'),
          ],
        ),
      ),
    );
  }

  /// Period button
  Widget _periodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// Revenue Analytics
  Widget _buildRevenueAnalytics() {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final totalEarnings = barberProvider.calculateTotalShopEarnings();
        final avgEarnings = barberProvider.calculateAverageBarberEarnings();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _analyticsRow('Total Revenue', 'Rs ${totalEarnings.toStringAsFixed(0)}', Colors.green),
                _analyticsRow('Average Per Barber', 'Rs ${avgEarnings.toStringAsFixed(0)}', Colors.blue),
                _analyticsRow(
                  'Revenue Growth',
                  '+12.5%',
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Trend Chart',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: CustomPaint(
                          painter: SimpleChartPainter(),
                          size: const Size(double.infinity, 120),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Analytics row widget
  Widget _analyticsRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barber Performance Analytics
  Widget _buildBarberPerformanceAnalytics() {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final barbers = barberProvider.allBarbers;
        final topBarber = barberProvider.getTopPerformingBarber();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Barber Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (topBarber != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Performer',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topBarber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: barbers.length,
                  itemBuilder: (ctx, idx) {
                    final barber = barbers[idx];
                    final performance = ((barber.rating / 5) * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                barber.ownerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$performance%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: barber.rating / 5,
                              minHeight: 6,
                              backgroundColor: Colors.grey.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                barber.rating >= 4.5 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Booking Analytics
  Widget _buildBookingAnalytics() {
    // Derive booking analytics from barber incomes where possible
    final incomes = context.read<BarberProvider>().allBarberIncomes.values.toList();
    final totalCount = incomes.fold<int>(0, (sum, i) => sum + (i.totalBookings));
    final completedCount = incomes.fold<int>(0, (sum, i) => sum + (i.bookingsCompleted));
    final completionRate = totalCount > 0 ? (completedCount / totalCount * 100).toStringAsFixed(1) : '0.0';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _analyticsRow(
              'Total Bookings',
              totalCount.toString(),
              Colors.blue,
            ),
            _analyticsRow(
              'Completed',
              completedCount.toString(),
              Colors.green,
            ),
            _analyticsRow(
              'Completion Rate',
              '$completionRate%',
              Colors.orange,
            ),
            _analyticsRow(
              'Avg Booking Value',
              'Rs 500',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple chart painter for visual representation
class SimpleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.2),
      Offset(size.width, size.height * 0.3),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
      canvas.drawCircle(points[i], 4, paint..style = PaintingStyle.fill);
    }
    canvas.drawCircle(points.last, 4, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
