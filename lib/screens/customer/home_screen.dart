import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/providers/booking_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';
import 'package:barber_pro/models/index.dart';

/// Customer Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load bookings on home screen load after first frame to safely use context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final customerId = context.read<AuthProvider>().currentUser?.uid;
      if (customerId != null) {
        context.read<BookingProvider>().loadCustomerBookings(customerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Redirect to login if not authenticated
    if (!authProvider.isAuthenticated || user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = user.name.isNotEmpty ? user.name : 'User';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(userName),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Upcoming bookings
            _buildUpcomingBookings(context),
            const SizedBox(height: 24),

            // Stats section
            _buildStats(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Welcome header with greeting
  Widget _buildWelcomeHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to get groomed? 💈',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha((0.9 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick action buttons
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                context,
                icon: Icons.search,
                label: 'Find Barber',
                color: Colors.blue,
                onTap: () => context.go('/discovery'),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: Icons.receipt,
                label: 'My Bookings',
                color: Colors.green,
                onTap: () => context.go('/bookings'),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: Icons.person,
                label: 'Profile',
                color: Colors.orange,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Action button widget
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Upcoming bookings section
  Widget _buildUpcomingBookings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Bookings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              if (bookingProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = bookingProvider.myBookings;

              if (bookings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming bookings',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/discovery'),
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),
                );
              }

              // Show first 3 bookings
              final upcomingBookings = bookings.take(3).toList();
              return Column(
                children: upcomingBookings.map((booking) {
                  return FutureBuilder<Barber?>(
                    future: context.read<BarberProvider>().getBarberById(
                      booking.barberId,
                    ),
                    builder: (ctx, snapshot) {
                      final barber = snapshot.data;
                      // Compute progress based on barber.currentToken and queueLength
                      double progress = 0.0;
                      String shopLabel = 'Shop';
                      String subLabel = '';
                      if (barber != null) {
                        shopLabel = barber.shopName.isNotEmpty
                            ? barber.shopName
                            : 'Shop';
                        final position =
                            booking.tokenNumber - barber.currentToken;
                        final total = (barber.queueLength <= 0)
                            ? 1
                            : barber.queueLength;
                        final remaining = position.clamp(0, total);
                        progress = 1.0 - (remaining / total);
                        subLabel = barber.address;
                      }

                      return InkWell(
                        onTap: () => context.push(
                          '/booking-details/${booking.bookingId}',
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Token #${booking.tokenNumber} - $shopLabel',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (subLabel.isNotEmpty)
                                          Text(
                                            subLabel,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        booking.status,
                                      ).withAlpha((0.2 * 255).round()),
                                      border: Border.all(
                                        color: _getStatusColor(booking.status),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      booking.status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(booking.status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDateTime(booking.bookingTime),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Stats section
  Widget _buildStats(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final totalBookings = bookingProvider.myBookings.length;
        final completedBookings = bookingProvider.myBookings
            .where((b) => b.status == 'completed')
            .length;
        final waitingBookings = bookingProvider.myBookings
            .where((b) => b.status == 'waiting')
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Stats',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    'Total\nBookings',
                    totalBookings.toString(),
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Completed',
                    completedBookings.toString(),
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Waiting',
                    waitingBookings.toString(),
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Stat card widget
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date time
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day;
    final month = dateTime.month;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'next':
      case 'confirmed':
        return Colors.green;
      case 'waiting':
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'skipped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
