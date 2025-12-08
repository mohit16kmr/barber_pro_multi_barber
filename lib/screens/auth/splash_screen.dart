import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';

/// SplashScreen displays on app launch and auto-routes based on auth state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToHome();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _navigateToHome() {
    // Wait 2 seconds, then navigate based on auth state
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();

      // Ensure auth provider initializes (works with fake or real services)
      try {
        await authProvider.initializeAuth();
      } catch (_) {
        // ignore errors; initializeAuth already logs
      }

      if (!mounted) return;

      final isLoggedIn = authProvider.isAuthenticated;
      final isBarber = authProvider.userRole == 'barber';

      if (isLoggedIn) {
        context.go(isBarber ? '/barber-home' : '/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5), // Primary blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Animated logo/icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.cut,
                      size: 80,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// App name
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Book Barber',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Your Barber, Your Time',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 50),

            /// Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
