import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationsEnabled;
  late String _selectedLanguage;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    // Initialize simple defaults; defer provider reads to didChangeDependencies
    _notificationsEnabled = true;
    _selectedLanguage = 'English';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      try {
        final themeProvider = context.read<ThemeProvider>();
        _selectedLanguage = themeProvider.language;
      } catch (_) {
        // ThemeProvider not available in this build context. Keep default language.
      }
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider? themeProvider;
    try {
      themeProvider = context.watch<ThemeProvider>();
    } catch (_) {
      // If provider is not available for any reason, fall back to null and
      // render the settings UI with local defaults to avoid crashing.
      themeProvider = null;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive booking and queue updates'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notifications ${value ? 'enabled' : 'disabled'}',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    value: themeProvider?.isDark ?? false,
                    onChanged: themeProvider == null
                        ? null
                        : (value) async {
                            await themeProvider!.setDarkMode(value);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Dark mode ${value ? 'enabled' : 'disabled'}',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: themeProvider == null
                        ? null
                        : () => _showLanguageDialog(themeProvider!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Settings Section
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change Password Coming Soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('View our privacy policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy Coming Soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('View our terms'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms of Service Coming Soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Contact our support team'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support Coming Soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('App version and info'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone Section
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.orange),
                    ),
                    subtitle: const Text('Sign out from your account'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange,
                    ),
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Permanently delete your account'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delete Account Coming Soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Spanish', 'French', 'German', 'Hindi']
                .map(
                  (lang) => ListTile(
                    title: Text(lang),
                    trailing: _selectedLanguage == lang
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () async {
                      setState(() => _selectedLanguage = lang);
                      // Capture navigator and messenger before awaiting
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await themeProvider.setLanguage(lang);
                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(content: Text('Language changed to $lang')),
                        );
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About Book Barber'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book Barber v1.0.0'),
            SizedBox(height: 16),
            Text(
              'Real-Time Barber Booking & Queue Management System',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text('© 2024 Book Barber. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
