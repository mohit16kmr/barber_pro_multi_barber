import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../models/index.dart';
import '../../providers/barber_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';

class BarberDetailsScreen extends StatefulWidget {
  final String barberId;

  const BarberDetailsScreen({
    super.key,
    required this.barberId,
  });

  @override
  State<BarberDetailsScreen> createState() => _BarberDetailsScreenState();
}

class _BarberDetailsScreenState extends State<BarberDetailsScreen> {
  late Barber? _barber;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBarberDetails();
  }

  Future<void> _loadBarberDetails() async {
    setState(() {
      _loading = true;
    });

    try {
      // Try to load from barber provider
      final barberProvider = context.read<BarberProvider>();
      _barber = await barberProvider.getBarberById(widget.barberId);

      if (_barber == null) {
        // Fallback: create sample barber
        _createSampleBarber();
      }
    } catch (_) {
      _createSampleBarber();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _createSampleBarber() {
    _barber = Barber(
      barberId: widget.barberId,
      shopName: 'Premium Cuts Barbershop',
      ownerName: 'John Smith',
      phone: '0800-123-4567',
      address: '42 Main Street, Downtown',
      location: {
        'latitude': 51.5074,
        'longitude': -0.1278,
      },
      services: const [
        Service(
          name: 'Basic Haircut',
          price: 25.0,
          durationMinutes: 30,
        ),
        Service(
          name: 'Haircut + Fade',
          price: 35.0,
          durationMinutes: 45,
        ),
        Service(
          name: 'Full Beard Trim',
          price: 20.0,
          durationMinutes: 20,
        ),
        Service(
          name: 'Haircut + Beard',
          price: 45.0,
          durationMinutes: 60,
        ),
      ],
      photos: const [],
      queue: const [],
      currentToken: 5,
      queueLength: 3,
      isOnline: true,
      breakTimes: const [],
      holidays: const [],
      rating: 4.7,
      verified: true,
      totalEarnings: 2500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      workingHours: {
        'monday': {'open': '09:00', 'close': '18:00'},
        'tuesday': {'open': '09:00', 'close': '18:00'},
        'wednesday': {'open': '09:00', 'close': '18:00'},
        'thursday': {'open': '09:00', 'close': '18:00'},
        'friday': {'open': '09:00', 'close': '20:00'},
        'saturday': {'open': '10:00', 'close': '16:00'},
        'sunday': {'open': 'closed', 'close': 'closed'},
      },
    );
  }

  Future<void> _bookNow(List<Service> selectedServices) async {
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Confirming your booking...'),
          ],
        ),
      ),
    );

    try {
      // Calculate estimated wait time (base time + queue length)
      final estimatedWaitTime = 30 + (_barber?.queueLength ?? 0) * 15;

      final bookingId = await bookingProvider.createBooking(
        customerId: authProvider.currentUser!.uid,
        barberId: widget.barberId,
        services: selectedServices,
        estimatedWaitTime: estimatedWaitTime,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      if (bookingId != null && bookingId.isNotEmpty) {
        // Calculate total price
        final totalPrice = selectedServices.fold<double>(0, (sum, s) => sum + s.price);
        
        // Show booking confirmation bottom sheet
        _showBookingConfirmation(
          bookingId: bookingId,
          totalPrice: totalPrice,
          estimatedWait: estimatedWaitTime,
          selectedServices: selectedServices,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Booking failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show booking confirmation sheet
  void _showBookingConfirmation({
    required String bookingId,
    required double totalPrice,
    required int estimatedWait,
    required List<Service> selectedServices,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _confirmationRow('Booking ID', bookingId),
                    const SizedBox(height: 12),
                    _confirmationRow('Shop', _barber?.shopName ?? 'Unknown'),
                    const SizedBox(height: 12),
                    _confirmationRow('Services', selectedServices.map((s) => s.name).join(', ')),
                    const SizedBox(height: 12),
                    _confirmationRow('Total Price', '\$${totalPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _confirmationRow('Est. Wait Time', '$estimatedWait mins'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final bookingProvider = context.read<BookingProvider>();
                    final auth = context.read<AuthProvider>();
                    await bookingProvider.loadCustomerBookings(auth.currentUser!.uid);
                    if (!mounted) return;
                    context.go('/bookings');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!mounted) return;
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF1E88E5)),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber Details'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _barber == null
              ? const Center(child: Text('Failed to load barber details'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        color: Colors.grey[200],
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  _barber!.isOnline ? Colors.green : Colors.grey,
                              child: Text(
                                _barber!.shopName.isNotEmpty
                                    ? _barber!.shopName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _barber!.shopName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_barber!.rating.toStringAsFixed(1)} (${_barber!.verified ? 'Verified' : 'Unverified'})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      _barber!.isOnline ? 'Online' : 'Offline',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _barber!.isOnline
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                authProvider.currentUser != null &&
                                        authProvider.currentUser!.favoriteBarbers
                                            .contains(_barber!.barberId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                if (!authProvider.isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login to favorite'),
                                    ),
                                  );
                                  return;
                                }
                                await authProvider
                                    .toggleFavoriteBarber(_barber!.barberId);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact & Location
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_barber!.phone)),
                                    IconButton(
                                      icon: const Icon(Icons.call, color: Colors.green),
                                      onPressed: () async {
                                        final phone = _barber!.phone;
                                        if (phone.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Phone number not available')),
                                          );
                                          return;
                                        }
                                        final uri = Uri(scheme: 'tel', path: phone);
                                        try {
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Cannot open dialer on this device')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error launching dialer: $e')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_barber!.address)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Queue Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '${_barber!.queueLength}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'In Queue',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${30 + (_barber!.queueLength * 15)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Est. Wait (min)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      _barber!.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFA500),
                                      ),
                                    ),
                                    const Text(
                                      'Rating',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Services
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._barber!.services.map((service) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${service.durationMinutes} min',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blueAccent,
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
                                            '\$${service.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Book Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _barber!.isOnline
                                ? () {
                                    // Show service selection dialog
                                    _showServiceSelectionDialog(
                                      context,
                                      _barber!.services,
                                    );
                                  }
                                : null,
                            child: const Text('Book Now'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  void _showServiceSelectionDialog(
    BuildContext context,
    List<Service> services,
  ) {
    // Track selections by index to avoid identity/equality issues with
    // Service objects coming from different sources.
    final selectedIndexes = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(sbContext).viewInsets.bottom + 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...services.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;
                    final isSelected = selectedIndexes.contains(index);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedIndexes.add(index);
                          } else {
                            selectedIndexes.remove(index);
                          }
                        });
                      },
                      title: Text(service.name),
                      subtitle: Text(
                        '\$${service.price.toStringAsFixed(2)} • ${service.durationMinutes} min',
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedIndexes.isNotEmpty
                          ? () {
                              // Build selected services by indexes before closing
                              final selectedServices = selectedIndexes
                                  .map((i) => services[i])
                                  .toList();
                              Navigator.pop(dialogContext);
                              _bookNow(selectedServices);
                            }
                          : null,
                      child: Text(
                        selectedIndexes.isEmpty
                            ? 'Select at least one service'
                            : 'Confirm Booking',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Barber?> getBarberById(String barberId) async {
    // Placeholder for real implementation
    return null;
  }
}
