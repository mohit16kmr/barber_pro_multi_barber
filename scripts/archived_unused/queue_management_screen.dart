import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_provider.dart';
import '../../models/index.dart';

class QueueManagementScreen extends StatefulWidget {
  final String? barberId;
  const QueueManagementScreen({super.key, this.barberId});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  bool _loading = false;
  final List<Booking> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }
  Future<void> _loadQueue() async {
    setState(() => _loading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final barberProvider = context.read<BarberProvider>();

      final barberId = (widget.barberId != null && widget.barberId!.isNotEmpty)
          ? widget.barberId!
          : (authProvider.currentUser?.uid ?? '');

      if (barberId.isNotEmpty) {
        barberProvider.loadBarberQueue(barberId);
        barberProvider.getBarberShift(barberId);
        barberProvider.getBarberIncome(barberId, DateTime.now());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading queue: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQueue,
              child: Consumer<BarberProvider>(
                builder: (context, barberProvider, _) {
                  final shift = barberProvider.currentBarberShift;
                  final income = barberProvider.currentBarberIncome;

                  final int jobsCompleted = income?.totalBookings ??
                      shift?.totalCustomersServed ??
                      _queueItems.where((q) => q.status == 'completed').length;

                  final double totalEarnings = income?.totalEarnings ??
                      shift?.totalEarnings ??
                      _queueItems.fold<double>(0.0, (sum, b) {
                    final servicesTotal = b.services.fold<double>(0.0, (s, svc) => s + svc.price);
                    return sum + servicesTotal;
                  });

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jobs Completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text('$jobsCompleted', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Earnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text('Rs. ${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _queueItems.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No customers in queue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemBuilder: (context, index) {
                                  final booking = _queueItems[index];
                                  final isServing = booking.status == 'serving';
                                  final isNext = booking.status == 'next';

                                  return Card(
                                    color: isServing
                                        ? Colors.green[50]
                                        : isNext
                                            ? Colors.blue[50]
                                            : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Token #${booking.tokenNumber}',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Chip(
                                                    label: Text(
                                                      booking.status.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    backgroundColor: isServing
                                                        ? Colors.green
                                                        : isNext
                                                            ? Colors.blue
                                                            : Colors.orange,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${booking.estimatedWaitTime} min',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Est. wait',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Services:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...booking.services.map((service) {
                                            return Text(
                                              '• ${service.name} (${service.durationMinutes} min) - Rs.${service.price.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 13),
                                            );
                                          }),
                                          const SizedBox(height: 12),
                                          if (isServing) ...[
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                onPressed: () => _completeBooking(booking),
                                                child: const Text('Complete Service'),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                onPressed: () => _skipBooking(booking),
                                                child: const Text('Skip'),
                                              ),
                                            ),
                                          ] else if (isNext) ...[
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () => _showCallNotAvailable(),
                                                child: const Text('Call Next'),
                                              ),
                                            ),
                                          ] else ...[
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                onPressed: () => _showCallNotAvailable(),
                                                child: const Text('Call Customer'),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemCount: _queueItems.length,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  void _completeBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Service'),
        content: Text('Mark Token #${booking.tokenNumber} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              setState(() {
                _queueItems.removeWhere((b) => b.bookingId == booking.bookingId);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Service completed for Token #${booking.tokenNumber}'),
                ),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _skipBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Skip Customer'),
        content: Text('Skip Token #${booking.tokenNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              setState(() {
                _queueItems.removeWhere((b) => b.bookingId == booking.bookingId);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Skipped Token #${booking.tokenNumber}'),
                ),
              );
            },
            child: const Text('Skip', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCallNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call feature not available for this booking')),
    );
  }
}
