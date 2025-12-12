import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro_multi_barber/providers/auth_provider.dart';

/// AppShell wraps all authenticated screens with bottom navigation
class AppShell extends StatefulWidget {
  final Widget child;
  final String userType; // 'customer' or 'barber'

  const AppShell({required this.child, required this.userType, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Get current route index based on location
  int _getSelectedIndex(String location) {
    if (widget.userType == 'customer') {
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/discovery')) return 1;
      if (location.startsWith('/bookings'))
        return 2; // ignore: curly_braces_in_flow_control_structures // Fixed: only /bookings maps to 2
      if (location.startsWith('/profile') ||
          location.startsWith('/edit-profile')) {
        return 3;
      }
      if (location.startsWith('/settings')) return 3;
    } else if (widget.userType == 'barber') {
      // Barber navigation (new structure)
      if (location.startsWith('/barber-home')) {
        return 0; // Home tab
      }
      if (location.startsWith('/barber-queue')) {
        return 1; // Queue tab
      }
      if (location.startsWith('/barber-earnings')) {
        return 2; // Earnings tab
      }
      if (location.startsWith('/barber-profile') ||
          location.startsWith('/barber-settings')) {
        return 3; // Profile tab
      }
    } else if (widget.userType == 'admin') {
      // Admin navigation
      if (location.startsWith('/admin-dashboard')) {
        return 0; // Dashboard tab
      }
      if (location.startsWith('/admin-shop-management')) {
        return 1; // Shop Management tab
      }
      if (location.startsWith('/admin-reports')) {
        return 2; // Reports tab
      }
      if (location.startsWith('/admin-agents')) {
        return 3; // Agents tab
      }
    }
    return 0;
  }

  void _onNavItemTapped(int index) {
    if (widget.userType == 'customer') {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/discovery');
          break;
        case 2:
          context.go(
            '/bookings',
          ); // Fixed: was '/profile', should be '/bookings'
          break;
        case 3:
          context.go(
            '/profile',
          ); // Fixed: was '/settings', should be '/profile'
          break;
      }
    } else if (widget.userType == 'barber') {
      // Barber navigation (new structure)
      switch (index) {
        case 0:
          context.go('/barber-home'); // Home tab
          break;
        case 1:
          context.go('/barber-queue'); // Queue tab
          break;
        case 2:
          context.go('/barber-earnings'); // Earnings tab
          break;
        case 3:
          context.go('/barber-profile'); // Profile tab
          break;
      }
    } else if (widget.userType == 'admin') {
      // Admin navigation
      switch (index) {
        case 0:
          context.go('/admin-dashboard'); // Dashboard tab
          break;
        case 1:
          context.go('/admin-shop-management'); // Shop Management tab
          break;
        case 2:
          context.go('/admin-reports'); // Reports tab
          break;
        case 3:
          context.go('/admin-agents'); // Agents tab
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(location);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Let go_router handle the back navigation
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: widget.child,
        bottomNavigationBar: _buildBottomNav(selectedIndex),
      ),
    );
  }

  /// Build app bar with user info and actions
  PreferredSizeWidget _buildAppBar() {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.currentUser?.name ?? 'User';
    final userType = widget.userType;

    String appTitle = 'BarberPro';
    if (userType == 'customer') {
      appTitle = 'BarberPro - Customer';
    } else if (userType == 'barber') {
      appTitle = 'BarberPro - Barber';
    } else if (userType == 'admin') {
      appTitle = 'BarberPro - Admin';
    }

    return AppBar(
      title: Text(
        appTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevation: 2,
      actions: [
        // Avatar: open profile on tap (logout moved to Profile screen)
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              // Navigate to the appropriate profile screen
              if (userType == 'customer') {
                context.go('/profile');
              } else if (userType == 'barber') {
                context.go('/barber-profile');
              } else {
                context.go('/admin-dashboard');
              }
            },
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build bottom navigation bar
  Widget _buildBottomNav(int selectedIndex) {
    if (widget.userType == 'customer') {
      return BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      );
    } else if (widget.userType == 'barber') {
      // Barber bottom nav (new structure)
      return BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Queue'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      );
    } else if (widget.userType == 'admin') {
      // Admin bottom nav
      return BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Agents',
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
