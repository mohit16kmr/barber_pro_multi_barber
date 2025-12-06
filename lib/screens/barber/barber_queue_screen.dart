import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';

/// Barber Queue Screen - shows customer queue for this barber
class BarberQueueScreen extends StatefulWidget {
  const BarberQueueScreen({super.key});

  @override
  State<BarberQueueScreen> createState() => _BarberQueueScreenState();
}

class _BarberQueueScreenState extends State<BarberQueueScreen> {
  @override
  void initState() {
    super.initState();
    _loadQueueData();
  }

  void _loadQueueData() {
    final authProvider = context.read<AuthProvider>();
    final barberProvider = context.read<BarberProvider>();
    
    if (authProvider.currentUser?.uid != null) {
      barberProvider.loadBarberQueue(authProvider.currentUser!.uid);
      barberProvider.getBarberShift(authProvider.currentUser!.uid);
    }
  }



  void _toggleOnlineStatus() async {
    final barberProvider = context.read<BarberProvider>();
    final newStatus = !barberProvider.isBarberOnline;
    
    final success = await barberProvider.toggleBarberOnlineStatus(
      context.read<AuthProvider>().currentUser!.uid,
      newStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'You are now ONLINE' : 'You are now OFFLINE'),
          backgroundColor: newStatus ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeService(String queueId, double amount) async {
    final barberProvider = context.read<BarberProvider>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Service?'),
        content: const Text('Mark this service as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await barberProvider.completeService(
                queueId,
                amount,
                0.0,
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service marked as completed'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(barberProvider.errorMessage ?? 'Failed to complete service'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _skipCustomer(String queueId) async {
    final barberProvider = context.read<BarberProvider>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Customer?'),
        content: const Text('Move this customer to the end of queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await barberProvider.skipCustomer(queueId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer moved to end of queue')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(barberProvider.errorMessage ?? 'Failed to skip customer'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _callCustomer(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final List<dynamic> queue = barberProvider.currentBarberQueue;

        final dynamic servingCustomer = queue.firstWhere(
          (q) => q is Map ? q['status'] == 'serving' : (q as dynamic).status == 'serving',
          orElse: () => <String, dynamic>{},
        );

        final waitingCount = queue.where((q) {
          if (q is Map) return q['status'] == 'waiting';
          return (q as dynamic).status == 'waiting';
        }).length;

        final hasServing = servingCustomer is Map ? servingCustomer.isNotEmpty : servingCustomer != null;
        final servingName = servingCustomer is Map
            ? servingCustomer['customerName'] ?? ''
            : (servingCustomer.customerName ?? '');
        final servingService = servingCustomer is Map
            ? servingCustomer['serviceType'] ?? ''
            : (servingCustomer.serviceType ?? '');
        final servingPhone = servingCustomer is Map
            ? servingCustomer['phoneNumber'] ?? ''
            : (servingCustomer.customerPhone ?? '');
        final servingPrice = servingCustomer is Map
            ? (servingCustomer['price'] ?? 0.0)
            : (servingCustomer.servicePrice ?? 0.0);
        final servingId = servingCustomer is Map
            ? servingCustomer['id']
            : servingCustomer.queueId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Queue'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleOnlineStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: barberProvider.isBarberOnline 
                          ? Colors.green.withOpacity(0.9)
                          : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (barberProvider.isBarberOnline ? Colors.green : Colors.red)
                              .withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            barberProvider.isBarberOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: queue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No customers in queue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// Queue Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Queue Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$waitingCount customers waiting',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white24,
                              child: Text(
                                waitingCount.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Currently Serving
                      if (hasServing) ...[
                        const Text(
                          'Currently Serving',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green[50],
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
                                          servingName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          servingService,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${servingPrice?.toStringAsFixed(0) ?? '0'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Chip(
                                        label: Text(
                                          'Serving Now',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.green,
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _callCustomer(
                                            servingPhone,
                                          ),
                                          icon: const Icon(Icons.call),
                                          label: const Text('Call'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                  const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _completeService(
                                            servingId,
                                            servingPrice ?? 0.0,
                                          ),
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Complete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      /// Waiting Queue
                      const Text(
                        'Waiting in Queue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: queue.length,
                        itemBuilder: (ctx, idx) {
                          final customer = queue[idx];
                          final status = customer is Map ? customer['status'] : customer.status;
                          
                          if (status == 'serving') return const SizedBox.shrink();

                          final id = customer is Map ? customer['id'] : customer.queueId;
                          final name = customer is Map ? customer['customerName'] : customer.customerName;
                          final phone = customer is Map ? customer['phoneNumber'] : customer.customerPhone;
                          final service = customer is Map ? customer['serviceType'] : customer.serviceType;
                          final price = customer is Map ? customer['price'] : customer.servicePrice;
                          final waitTime = customer is Map ? customer['waitTime'] : '${customer.bookingTime}';
                          final position = idx;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1E88E5),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '#${position + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              service,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rs. ${price?.toStringAsFixed(0) ?? '0'}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            waitTime,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _callCustomer(phone),
                                          icon: const Icon(Icons.call, size: 16),
                                          label: const Text('Call'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _skipCustomer(id),
                                          icon:
                                              const Icon(Icons.skip_next, size: 16),
                                          label: const Text('Skip'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}
