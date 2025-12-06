import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';

/// Barber Individual Earnings Screen - shows earnings for single barber
class BarberEarningsScreen extends StatefulWidget {
  const BarberEarningsScreen({super.key});

  @override
  State<BarberEarningsScreen> createState() => _BarberEarningsScreenState();
}

class _BarberEarningsScreenState extends State<BarberEarningsScreen> {
  int _selectedTab = 0; // 0: Today, 1: This Month, 2: All Time

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() {
    final authProvider = context.read<AuthProvider>();
    final barberProvider = context.read<BarberProvider>();
    
    if (authProvider.currentUser?.uid != null) {
      barberProvider.getBarberIncome(authProvider.currentUser!.uid, DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        double totalAmount = 0;
        int bookingCount = 0;

        if (barberProvider.currentBarberIncome != null) {
          if (_selectedTab == 0) {
            totalAmount = barberProvider.currentBarberIncome!.dailyEarnings;
            bookingCount = barberProvider.currentBarberIncome!.bookingsCompleted;
          } else if (_selectedTab == 1) {
            totalAmount = barberProvider.currentBarberIncome!.monthlyEarnings;
            bookingCount = barberProvider.currentBarberIncome!.monthlyBookings;
          } else if (_selectedTab == 2) {
            totalAmount = barberProvider.currentBarberIncome!.totalEarnings;
            bookingCount = barberProvider.currentBarberIncome!.totalBookings;
          }
        }

        final avgPerBooking = bookingCount > 0 ? totalAmount / bookingCount : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Earnings'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Earnings Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E88E5),
                        const Color(0xFF1565C0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bookings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$bookingCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Avg per Booking',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${avgPerBooking.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// Period Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildTab('Today', 0),
                      _buildTab('This Month', 1),
                      _buildTab('All Time', 2),
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1E88E5)
                  : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
