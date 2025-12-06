import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/barber_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/index.dart';

class BarberListScreen extends StatefulWidget {
  const BarberListScreen({super.key});

  @override
  State<BarberListScreen> createState() => _BarberListScreenState();
}

class _BarberListScreenState extends State<BarberListScreen> {
  bool _loading = false;
  bool _loadFailed = false;
  String? _selectedRegion;
  bool _useLocationFilter = true; // Filter by user's location by default

  @override
  void initState() {
    super.initState();
    _tryLoad();
  }

  Future<void> _tryLoad() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    final barberProvider = context.read<BarberProvider>();
    try {
      await barberProvider.loadAllBarbers();
      // If load fails or returns empty, that's OK - show empty state
      // Don't use fallback sample data since we now work with real data
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Extract unique regions/villages from barber addresses
  List<String> _buildRegionsList(List<Barber> barbers) {
    final Set<String> regions = {'All Regions'};
    
    for (final barber in barbers) {
      // Extract last part of address (usually village/city name)
      final addressParts = barber.address.split(',').map((e) => e.trim()).toList();
      if (addressParts.isNotEmpty) {
        // Add the last part (finest granularity - village)
        regions.add(addressParts.last);
        // Also add the second-to-last if available (city-level)
        if (addressParts.length > 1) {
          regions.add(addressParts[addressParts.length - 2]);
        }
      }
    }
    
    return regions.toList()..sort((a, b) {
      if (a == 'All Regions') return -1;
      if (b == 'All Regions') return 1;
      return a.compareTo(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final barberProvider = context.watch<BarberProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Get all barbers from provider (real data only, no fallback)
    final List<Barber> allItems = barberProvider.filteredBarbers;

    // Filter by region
    final List<Barber> items = _selectedRegion == null || _selectedRegion == 'All Regions'
        ? allItems
        : allItems
            .where((b) => b.address.toLowerCase().contains(
                _selectedRegion!.toLowerCase()))
            .toList();

    // Filter by user's location (city/state) if enabled
    final List<Barber> filteredBarbers = _useLocationFilter &&
            authProvider.currentUser?.city != null
        ? items
            .where((b) =>
                b.address.toLowerCase().contains(
                    authProvider.currentUser!.city!.toLowerCase()) ||
                // Fallback: match if barber address contains any word from user's city
                b.address.split(' ').any((word) =>
                    word.toLowerCase().startsWith(
                        authProvider.currentUser!.city!.toLowerCase())))
            .toList()
        : items;

    // Sort by least bookings (queue length)
    filteredBarbers.sort((a, b) => a.queueLength.compareTo(b.queueLength));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Barbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _tryLoad,
            tooltip: 'Refresh',
          )
        ],
      ),
      body: Column(
        children: [
          // Location Filter Toggle & Region Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Location-based filter toggle
                if (authProvider.currentUser?.city != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _useLocationFilter,
                          onChanged: (value) {
                            setState(() => _useLocationFilter = value ?? true);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Show barbers near ${authProvider.currentUser!.city}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Region Filter Dropdown - Dynamic regions from barber addresses
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedRegion ?? 'All Regions',
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: _buildRegionsList(allItems).map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRegion = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Barber List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _tryLoad,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBarbers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _loadFailed
                                        ? 'Failed to load barbers'
                                        : 'No barbers available yet',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _loadFailed
                                        ? 'Please check your connection and try again'
                                        : 'Check back later for available barbers',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final barber = filteredBarbers[index];
                            final isFavorited = authProvider.currentUser != null
                                ? authProvider.currentUser!.favoriteBarbers
                                    .contains(barber.barberId)
                                : false;

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      barber.isOnline ? Colors.green : Colors.grey,
                                  child: Text(barber.shopName.isNotEmpty
                                      ? barber.shopName[0]
                                      : '?'),
                                ),
                                title: Text(barber.shopName),
                                subtitle: Text(
                                    '${barber.ownerName} • ${barber.address}\nRating: ${barber.rating.toStringAsFixed(1)} • Queue: ${barber.queueLength}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(
                                isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isFavorited ? Colors.red : Colors.grey),
                            onPressed: () async {
                              if (!authProvider.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to favorite'),
                                  ),
                                );
                                return;
                              }

                              final ok = await authProvider
                                  .toggleFavoriteBarber(barber.barberId);
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.errorMessage ?? 'Failed'),
                                  ),
                                );
                              }
                            },
                          ),
                          onTap: () {
                            // Navigate to booking flow using go_router push so back works
                            context.push('/booking/${barber.barberId}');
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: filteredBarbers.length,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
