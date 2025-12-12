import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro_multi_barber/providers/barber_provider.dart';
import 'package:barber_pro_multi_barber/providers/auth_provider.dart';

/// Admin Shop Management - Manage all shop settings and barbers
class AdminShopManagementScreen extends StatefulWidget {
  const AdminShopManagementScreen({super.key});

  @override
  State<AdminShopManagementScreen> createState() =>
      _AdminShopManagementScreenState();
}

class _AdminShopManagementScreenState extends State<AdminShopManagementScreen> {
  late TextEditingController _shopNameController;
  late TextEditingController _shopPhoneController;
  late TextEditingController _shopAddressController;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _shopPhoneController = TextEditingController();
    _shopAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Management'),
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
            // Shop Info Section
            _buildShopInfoSection(),
            const SizedBox(height: 24),

            // Barbers Management Section
            _buildBarbersManagementSection(),
            const SizedBox(height: 24),

            // Shop Settings
            _buildShopSettingsSection(),
          ],
        ),
      ),
    );
  }

  /// Shop Info Section
  Widget _buildShopInfoSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final shopId = authProvider.currentUser?.shopId ?? 'N/A';

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Shop ID: $shopId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shop information updated'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Barbers Management Section
  Widget _buildBarbersManagementSection() {
    return Consumer<BarberProvider>(
      builder: (context, barberProvider, _) {
        final barbers = barberProvider.allBarbers;

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
                      'Manage Barbers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddBarberDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (barbers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No barbers added yet'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: barbers.length,
                    itemBuilder: (ctx, idx) {
                      final barber = barbers[idx];
                      return Dismissible(
                        key: Key(barber.barberId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${barber.ownerName} removed'),
                            ),
                          );
                        },
                        background: Container(
                          color: Colors.red.withValues(alpha: 0.7),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(barber.ownerName[0]),
                            ),
                            title: Text(barber.ownerName),
                            subtitle: Text(barber.phone),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              _showBarberDetailsDialog(barber.ownerName);
                            },
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

  /// Shop Settings Section
  Widget _buildShopSettingsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shop Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _settingsTile(
              title: 'Business Hours',
              subtitle: '09:00 AM - 06:00 PM',
              icon: Icons.schedule,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Business hours editor coming soon'),
                  ),
                );
              },
            ),
            _settingsTile(
              title: 'Service Categories',
              subtitle: '5 categories configured',
              icon: Icons.category,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service categories editor coming soon'),
                  ),
                );
              },
            ),
            _settingsTile(
              title: 'Notifications',
              subtitle: 'Manage alerts and notifications',
              icon: Icons.notifications,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings coming soon'),
                  ),
                );
              },
            ),
            _settingsTile(
              title: 'Tax Settings',
              subtitle: 'Configure tax rates',
              icon: Icons.receipt,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tax settings coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Settings tile widget
  Widget _settingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// Show add barber dialog
  void _showAddBarberDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final barberProvider = context.read<BarberProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

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

              await barberProvider.addBarber(name: name, phone: phone);

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('Barber "$name" added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Show barber details dialog
  void _showBarberDetailsDialog(String barberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(barberName),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Queue: 3 customers'),
              SizedBox(height: 8),
              Text('Rating: 4.8/5'),
              SizedBox(height: 8),
              Text('Today\'s Earnings: Rs 2,500'),
              SizedBox(height: 8),
              Text('Total Earnings: Rs 45,000'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
