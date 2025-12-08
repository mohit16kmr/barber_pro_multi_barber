import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';

/// Shop Earnings Dashboard - Owner sees total income and all barbers' earnings
class ShopEarningsDashboardScreen extends StatefulWidget {
  const ShopEarningsDashboardScreen({super.key});

  @override
  State<ShopEarningsDashboardScreen> createState() =>
      _ShopEarningsDashboardScreenState();
}

class _ShopEarningsDashboardScreenState
    extends State<ShopEarningsDashboardScreen> {
  int _selectedPeriod = 0; // 0: Today, 1: This Month, 2: This Year

  @override
  void initState() {
    super.initState();
    _loadShopEarnings();
  }

  void _loadShopEarnings() {
    final authProvider = context.read<AuthProvider>();
    final barberProvider = context.read<BarberProvider>();

    if (authProvider.currentUser?.shopId != null) {
      barberProvider.loadShopEarnings(authProvider.currentUser!.shopId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        // period tabs driven by _selectedPeriod

        // Build earnings summary from provider data
        final incomes = barberProvider.allBarberIncomes.values.toList();
        final totalAmount = incomes.fold<double>(
          0.0,
          (sum, i) => sum + (i.dailyEarnings),
        );
        final bookings = incomes.fold<int>(
          0,
          (sum, i) => sum + (i.bookingsCompleted),
        );
        final barbersCount = incomes.length;
        final averagePerBarber = barbersCount > 0
            ? totalAmount / barbersCount
            : 0.0;

        final earnings = {
          'totalAmount': totalAmount,
          'bookings': bookings,
          'barbers': barbersCount,
          'averagePerBarber': averagePerBarber,
        };

        final allBarbers = barberProvider.allBarberIncomes.entries
            .map(
              (e) => {
                'id': e.key,
                'name': e.key,
                'todayEarnings': e.value.dailyEarnings,
                'monthEarnings': e.value.monthlyEarnings,
                'totalEarnings': e.value.totalEarnings,
                'bookingsToday': e.value.bookingsCompleted,
                'status': 'online',
                'rating': 4.5,
                'reviewCount': 50,
              },
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Earnings Dashboard'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Total Shop Earnings Card - Enhanced
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E88E5),
                        const Color(0xFF1565C0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF1E88E5,
                        ).withAlpha((0.4 * 255).round()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Shop Income',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rs. ${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildEarningsStatItem(
                            label: 'Bookings',
                            value: '${earnings['bookings']}',
                            icon: Icons.calendar_today,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _buildEarningsStatItem(
                            label: 'Active Barbers',
                            value: '${earnings['barbers']}',
                            icon: Icons.people,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _buildEarningsStatItem(
                            label: 'Avg/Barber',
                            value:
                                'Rs. ${(averagePerBarber).toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Period Tabs - Enhanced
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.08 * 255).round()),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      _buildPeriodTab('Today', 0),
                      _buildPeriodTab('This Month', 1),
                      _buildPeriodTab('This Year', 2),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Barbers Earnings List header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barber Performance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Ranked by earnings',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (allBarbers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No earnings data yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allBarbers.length,
                    itemBuilder: (ctx, idx) {
                      final barber = allBarbers[idx];
                      final earningsKey = _selectedPeriod == 0
                          ? 'todayEarnings'
                          : _selectedPeriod == 1
                          ? 'monthEarnings'
                          : 'totalEarnings';
                      final bookingsKey = _selectedPeriod == 0
                          ? 'bookingsToday'
                          : 'bookings';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(
                                (0.06 * 255).round(),
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color:
                                                  barber['status'] == 'online'
                                                  ? Colors.green
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              (barber['name'] as String?) ??
                                                  'Barber',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 13,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${barber['rating']} (${barber['reviewCount']} reviews)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs. ${(barber[earningsKey] as num? ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1E88E5,
                                        ).withAlpha((0.15 * 255).round()),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '${(barber[bookingsKey] as num? ?? 0).toString()} bookings',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value:
                                    ((barber[earningsKey] as num? ?? 0) /
                                    (totalAmount > 0 ? totalAmount : 1)),
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Action Buttons - Enhanced
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to detailed analytics
                        },
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Analytics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Export earnings report
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E88E5),
                          side: const BorderSide(color: Color(0xFF1E88E5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}
