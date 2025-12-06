import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';

/// Barber Management Screen - Shop owner sees all barbers, can add/remove/view details
class BarberManagementScreen extends StatefulWidget {
  const BarberManagementScreen({super.key});

  @override
  State<BarberManagementScreen> createState() => _BarberManagementScreenState();
}

class _BarberManagementScreenState extends State<BarberManagementScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadBarbers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadBarbers() {
    final authProvider = context.read<AuthProvider>();
    final barberProvider = context.read<BarberProvider>();

    if (authProvider.currentUser?.shopId != null) {
      // Load barbers for this shop (or all if service does not filter by shop)
      barberProvider.loadAllBarbers();
    }
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Note: barbers are loaded from `BarberProvider.allBarbers`.

  void _showAddBarberDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Barber'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Barber Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final barberProvider = context.read<BarberProvider>();
              final authProvider = context.read<AuthProvider>();
              final shopId = authProvider.currentUser?.shopId ?? authProvider.currentUser?.uid;

              // Show a small loading indicator while adding
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final createdId = await barberProvider.addBarber(name: name, phone: phone, shopId: shopId);

              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pop(); // remove loading

              if (createdId != null) {
                if (!mounted) return;
                Navigator.of(context).pop(); // close add dialog
                if (!mounted) return;
                // Refresh provider list so UI shows new barber
                await barberProvider.loadAllBarbers();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Barber "$name" added successfully')),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add barber, try again')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Barbers'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<BarberProvider>(
        builder: (context, barberProvider, _) {
          final barbers = barberProvider.allBarbers;

          return barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No barbers added yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first barber',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                children: [
                  // Scroll Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filled(
                          onPressed: _scrollLeft,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Scroll Left',
                        ),
                        Text(
                          '${barbers.length} Barbers',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _scrollRight,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Scroll Right',
                        ),
                      ],
                    ),
                  ),
                  // Barbers List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      controller: _scrollController,
                      itemCount: barbers.length,
                      itemBuilder: (ctx, idx) {
                        final barber = barbers[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              barber.ownerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: StreamBuilder<List<dynamic>>(
                              // Use the provider's queue stream to show live queue count
                              stream: barberProvider.getBarberQueueStream(barber.barberId),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.length ?? barber.queueLength;
                                return Text('Queue: $count');
                              },
                            ),
                            onTap: () {
                              // Navigate to queue management for this barber using GoRouter
                              context.push('/queue-management/${barber.barberId}');
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Active/Inactive switch - only visible to shop owner
                                Consumer2<AuthProvider, BarberProvider>(
                                  builder: (context, authProvider, barberProvider, _) {
                                    final isShopOwner = authProvider.currentUser?.shopId != null;
                                    final isOnline = barber.isOnline;
                                    
                                    return Switch(
                                      value: isOnline,
                                      activeThumbColor: Colors.green,
                                      onChanged: isShopOwner
                                          ? (val) async {
                                              try {
                                                await barberProvider.toggleBarberOnlineStatus(barber.barberId, val);
                                              } catch (_) {
                                                // ignore errors for mock flow
                                              }
                                            }
                                          : null, // Disabled for non-owners
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBarberDialog,
        tooltip: 'Add Barber',
        child: const Icon(Icons.add),
      ),
    );
  }
}
