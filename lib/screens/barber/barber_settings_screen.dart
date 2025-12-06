import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class BarberSettingsScreen extends StatefulWidget {
  const BarberSettingsScreen({super.key});

  @override
  State<BarberSettingsScreen> createState() => _BarberSettingsScreenState();
}

class _BarberSettingsScreenState extends State<BarberSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _bookingAlerts = true;
  bool _paymentNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Settings Section
            _buildSectionHeader('Account', Icons.person),
            _buildSettingsTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              color: Colors.blue,
              onTap: () {
                context.push('/barber-edit-profile');
              },
            ),
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change password functionality coming soon')),
                );
              },
            ),

            // Notifications Section
            _buildSectionHeader('Notifications', Icons.notifications),
            _buildSwitchTile(
              icon: Icons.notifications_active,
              title: 'All Notifications',
              subtitle: 'Receive all notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            _buildSwitchTile(
              icon: Icons.event_available,
              title: 'Booking Alerts',
              subtitle: 'Get notified for new bookings',
              value: _bookingAlerts,
              onChanged: (value) {
                setState(() => _bookingAlerts = value);
              },
            ),
            _buildSwitchTile(
              icon: Icons.payment,
              title: 'Payment Notifications',
              subtitle: 'Get payment updates',
              value: _paymentNotifications,
              onChanged: (value) {
                setState(() => _paymentNotifications = value);
              },
            ),

            // Business Settings Section
            _buildSectionHeader('Business', Icons.store),
            _buildSettingsTile(
              icon: Icons.storefront,
              title: 'Shop Details',
              subtitle: 'Manage your shop information',
              color: Colors.purple,
              onTap: () {
                context.push('/barber-management');
              },
            ),
            _buildSettingsTile(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              subtitle: 'Add or update payment methods',
              color: Colors.green,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment methods - feature coming soon')),
                );
              },
            ),

            // App Settings Section
            _buildSectionHeader('App', Icons.settings),
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              color: Colors.cyan,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language settings - coming soon')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version 1.0.0',
              color: Colors.grey,
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildSettingsTile(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and report issues',
              color: Colors.indigo,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: const Text('Contact us at: support@barberpro.com\n\nPhone: +91 1800-BARBER-1'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and policies',
              color: Colors.teal,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Terms & Conditions'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'BarberPro Terms & Conditions\n\n'
                        '1. Service Agreement\n'
                        'By using BarberPro, you agree to provide accurate information.\n\n'
                        '2. Payment Terms\n'
                        'Payments must be made as per the booking confirmation.\n\n'
                        '3. Cancellation Policy\n'
                        'Cancellations can be made 24 hours before the appointment.\n\n'
                        '4. Liability\n'
                        'BarberPro is not responsible for disputes between barbers and customers.\n\n'
                        '5. Privacy\n'
                        'Your data is protected as per our Privacy Policy.',
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
              },
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E88E5), size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.green.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About BarberPro'),
        content: const Text(
          'BarberPro v1.0.0\n\n'
          'A complete barber shop management solution.\n\n'
          '© 2025 BarberPro. All rights reserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
