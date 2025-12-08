import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';

/// Admin Dashboard - Overview of shop statistics and management
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    final barberProvider = context.read<BarberProvider>();

    // Load all barbers and shop earnings
    barberProvider.loadAllBarbers();
    barberProvider.loadShopEarnings(
      context.read<AuthProvider>().currentUser?.shopId ?? 'shop123',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            // Summary Cards Row
            _buildSummaryCards(),
            const SizedBox(height: 24),

            // Barbers Section
            _buildBarbersSummary(),
            const SizedBox(height: 24),

            // Bookings Section
            _buildBookingsSummary(),
            const SizedBox(height: 24),

            // Performance Metrics
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  /// Summary Cards with key metrics
  Widget _buildSummaryCards() {
    return Consumer2<BarberProvider, AuthProvider>(
      builder: (context, barberProvider, authProvider, _) {
        final totalBarbers = barberProvider.allBarbers.length;
        final totalEarnings = barberProvider.calculateTotalShopEarnings();
        final avgEarningsPerBarber = barberProvider
            .calculateAverageBarberEarnings();

        // Derive total bookings from barber incomes if available
        final totalBookings = barberProvider.allBarberIncomes.values.fold<int>(
          0,
          (sum, income) => sum + (income.totalBookings),
        );

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _summaryCard(
              title: 'Total Barbers',
              value: totalBarbers.toString(),
              icon: Icons.person,
              color: Colors.blue,
            ),
            _summaryCard(
              title: 'Total Bookings',
              value: totalBookings.toString(),
              icon: Icons.calendar_today,
              color: Colors.green,
            ),
            _summaryCard(
              title: 'Shop Earnings',
              value: 'Rs ${totalEarnings.toStringAsFixed(0)}',
              icon: Icons.money,
              color: Colors.orange,
            ),
            _summaryCard(
              title: 'Avg per Barber',
              value: 'Rs ${avgEarningsPerBarber.toStringAsFixed(0)}',
              icon: Icons.trending_up,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  /// Individual summary card widget
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Barbers Summary Section
  Widget _buildBarbersSummary() {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final barbers = barberProvider.allBarbers;
        final onlineCount = barbers.where((b) => b.isOnline).length;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barbers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$onlineCount Online',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (barbers.isEmpty)
                  const Text('No barbers added yet')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: barbers.length,
                    itemBuilder: (ctx, idx) {
                      final barber = barbers[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barber.ownerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    barber.phone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: barber.isOnline
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    barber.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: barber.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rating: ${barber.rating}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
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

  /// Bookings Summary Section
  Widget _buildBookingsSummary() {
    // Build booking summary from available barber incomes (admin-level summary)
    final totalBookings = context
        .read<BarberProvider>()
        .allBarberIncomes
        .values
        .fold<int>(0, (sum, i) => sum + (i.totalBookings));
    final completedCount = context
        .read<BarberProvider>()
        .allBarberIncomes
        .values
        .fold<int>(0, (sum, i) => sum + (i.bookingsCompleted));
    final pendingCount = (totalBookings - completedCount) > 0
        ? (totalBookings - completedCount)
        : 0;
    final cancelledCount =
        0; // Cancellation tracking requires bookings collection queries

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookings Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bookingStatusBadge('Completed', completedCount, Colors.green),
                _bookingStatusBadge('Pending', pendingCount, Colors.orange),
                _bookingStatusBadge('Cancelled', cancelledCount, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Bookings: $totalBookings',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Booking status badge widget
  Widget _bookingStatusBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Performance Metrics Section
  Widget _buildPerformanceMetrics() {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final topPerformer = barberProvider.getTopPerformingBarber();
        final allBarbers = barberProvider.allBarbers;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (topPerformer != null && allBarbers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Performer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topPerformer,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Income: Rs ${(barberProvider.allBarberIncomes[topPerformer]?.dailyEarnings ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                else
                  const Text('No performance data available'),
              ],
            ),
          ),
        );
      },
    );
  }
}
