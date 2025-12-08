import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:barber_pro/providers/auth_provider.dart';
import 'package:barber_pro/config/flavor_config.dart';

/// LoginScreen handles user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedUserType = 'customer'; // customer or barber or admin

  @override
  void initState() {
    super.initState();
    // Set default user type based on app flavor so each flavor shows its own login
    if (FlavorConfig.isAdmin) {
      _selectedUserType = 'admin';
    } else if (FlavorConfig.isBarber) {
      _selectedUserType = 'barber';
    } else {
      _selectedUserType = 'customer';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Admin flavor uses email/password admin sign-in flow
      if (FlavorConfig.isAdmin) {
        final success = await authProvider.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (success) {
          context.go('/admin-dashboard');
          return;
        } else {
          setState(() {
            _errorMessage = authProvider.errorMessage ?? 'Admin login failed';
          });
          return;
        }
      }

      // Customer/Barber: existing login flow (email/password authenticated user)
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Check if registration is needed (edge case for email login)
        if (authProvider.needsRegistration) {
          context.go('/signup');
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        // Route based on user role from profile
        if (authProvider.isBarber()) {
          context.go('/barber-home');
        } else if (authProvider.isAdmin()) {
          context.go('/admin-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        final errorMsg =
            authProvider.errorMessage ??
            'Login failed. Please check your credentials.';
        setState(() {
          _errorMessage = errorMsg;
        });

        // Show error in snackbar too
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn(String userType) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      // If app flavor is admin, Google sign-in not supported for admin flow
      if (FlavorConfig.isAdmin) {
        setState(() {
          _errorMessage = 'Admin login requires email/password';
          _isLoading = false;
        });
        return;
      }

      // Check if user is already logged in with different role
      if (authProvider.isAuthenticated && authProvider.userRole != userType) {
        if (!mounted) return;

        // Show confirmation dialog for role switching
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Switch Role?'),
                content: Text(
                  'You are currently logged in as a ${authProvider.userRole == 'customer' ? 'Customer' : 'Barber'}. '
                  'Do you want to switch to ${userType == 'barber' ? 'Barber' : 'Customer'}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Switch'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!confirmed) {
          setState(() => _isLoading = false);
          return;
        }

        // Sign out before switching role
        await authProvider.signOut();

        if (!mounted) return;
      }

      // Normal login for new user or same role
      final success = await authProvider.signInWithGoogle(userType: userType);

      if (!mounted) return;

      if (success) {
        // CRITICAL: Check if registration is needed first
        // If true, always route to signup regardless of userType parameter
        if (authProvider.needsRegistration) {
          if (!mounted) return;
          context.go('/signup');
          return;
        }

        // Show success feedback
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign-in successful!')));

        // Route based on user's actual role from Firestore profile
        if (authProvider.isBarber()) {
          context.go('/barber-home');
        } else if (authProvider.isAdmin()) {
          context.go('/admin-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage =
              authProvider.errorMessage ??
              'Google sign-in failed. Please try again.';
        });

        // Show error in snackbar too for visibility
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Google sign-in failed'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _handleGoogleSignIn(userType),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Logo section
              SizedBox(height: MediaQuery.of(context).padding.top + 40),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.cut, size: 50, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Title
              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 8),

              /// Subtitle
              const Text(
                'Sign in to your account to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),

              const SizedBox(height: 40),

              /// Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              /// Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password is required';
                        }
                        if (value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    /// Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.push('/forgot-password'),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF1E88E5)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              /// Show user type label per flavor. For flavors we hide the toggle
              if (FlavorConfig.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Admin Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else if (FlavorConfig.isBarber)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Barber Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Customer Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 24),

              // Only show Google sign-in for barber/customer flavors
              if (!FlavorConfig.isAdmin)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _handleGoogleSignIn(_selectedUserType),
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        label: Text(
                          'Continue with Google as ${_selectedUserType == 'barber' ? 'Barber' : 'Customer'}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              /// Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : () => context.go('/signup'),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
