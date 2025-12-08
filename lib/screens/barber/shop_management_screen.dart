import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/barber_provider.dart';
import '../../services/index.dart';

/// Shop Management Screen - where shop owner can manage and add barbers
class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barberPhoneController = TextEditingController(); // Primary lookup
  final _barberNameController = TextEditingController();
  final _barberEmailController = TextEditingController();
  final _barberExperienceController = TextEditingController();
  final _barberBioController = TextEditingController();
  final _referralCodeController =
      TextEditingController(); // Referral Code field
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showAddBarberForm = false;
  bool _isSearchingBarber = false;
  bool _barberFoundFromPhone = false; // Track if barber was found by phone
  XFile? _barberPhotoFile;
  List<String> _selectedSpecialties = [];
  String? _errorMessage;
  // Use BarberProvider to obtain connected barbers

  @override
  void dispose() {
    _barberNameController.dispose();
    _barberPhoneController.dispose();
    _barberEmailController.dispose();
    _barberExperienceController.dispose();
    _barberBioController.dispose();
    _referralCodeController.dispose(); // Dispose referral code controller
    super.dispose();
  }

  /// Search for existing barber by phone number
  Future<void> _searchBarberByPhone() async {
    if (_barberPhoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Enter phone number to search');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isSearchingBarber = true;
      _errorMessage = null;
    });

    try {
      // Query local provider for barber by phone
      final phone = _barberPhoneController.text;
      final barberProvider = context.read<BarberProvider>();
      final barbers = barberProvider.allBarbers;

      // Simulate a tiny delay while searching
      await Future.delayed(const Duration(milliseconds: 300));

      final matches = barbers.where((b) => b.phone == phone).toList();

      if (matches.isEmpty) {
        setState(() {
          _errorMessage = 'Barber not found with this phone number';
          _barberFoundFromPhone = false;
        });
        return;
      }

      final found = matches.first;

      // Auto-fill form with found barber details
      setState(() {
        _barberNameController.text = found.ownerName;
        _barberExperienceController.text = '0';
        _barberFoundFromPhone = true;
        _errorMessage = null;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Barber found! Details auto-filled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error searching barber: $e');
    } finally {
      setState(() => _isSearchingBarber = false);
    }
  }

  /// Remove barber from shop
  Future<void> _removeBarber(String barberId) async {
    final messenger = ScaffoldMessenger.of(context);
    final barberProvider = context.read<BarberProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Barber?'),
        content: const Text(
          'Are you sure you want to remove this barber from your shop?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final barberService = BarberService();
      await barberService.deleteBarber(barberId);

      // Refresh provider list
      await barberProvider.loadAllBarbers();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Barber removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPhotoPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Barber Photo'),
          content: const Text('Choose a photo source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickPhotoFromCamera();
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickPhotoFromGallery();
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPhotoFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _barberPhotoFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _barberPhotoFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleAddBarber() async {
    if (!_formKey.currentState!.validate()) return;

    if (_barberPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barber photo is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one specialty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement actual barber addition logic
      // This would typically:
      // 1. Upload photo to Firebase Storage
      // 2. Create new barber user account
      // 3. Link barber to shop
      // 4. Send invitation/registration link to barber email

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barber added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _barberNameController.clear();
      _barberPhoneController.clear();
      _barberEmailController.clear();
      _barberExperienceController.clear();
      _barberBioController.clear();
      _referralCodeController.clear(); // Clear referral code
      setState(() {
        _barberPhotoFile = null;
        _selectedSpecialties = [];
        _showAddBarberForm = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add barber: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          children: [
            /// Shop Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Shop',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.store_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Salon Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'City, Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Barbers: 1',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Connected Barbers Section
            if (!_showAddBarberForm) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connected Barbers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showAddBarberForm = true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Barber'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barbers list from provider
              Consumer<BarberProvider>(
                builder: (context, barberProvider, _) {
                  final barbers = barberProvider.allBarbers;
                  if (barbers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No barbers connected yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: barbers.length,
                    itemBuilder: (ctx, idx) {
                      final barber = barbers[idx];
                      final isOnline = barber.isOnline;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOnline
                                ? Colors.green
                                : Colors.grey,
                            child: Icon(
                              isOnline
                                  ? Icons.check_circle
                                  : Icons.offline_bolt,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(barber.ownerName),
                          subtitle: Text('${barber.phone} • 0 yrs exp'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  'Rs. ${barber.totalEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF1E88E5),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Text('View Details'),
                                    onTap: () {
                                      // TODO: Show barber details
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Text('Remove'),
                                    onTap: () => _removeBarber(barber.barberId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],

            /// Add Barber Form
            if (_showAddBarberForm) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1E88E5)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Barber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showAddBarberForm = false;
                              _formKey.currentState?.reset();
                              _barberPhotoFile = null;
                              _selectedSpecialties = [];
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          /// Phone Lookup - Search existing barber by phone number
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              border: Border.all(color: Colors.amber[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Find Existing Barber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _barberPhoneController,
                                        keyboardType: TextInputType.phone,
                                        enabled: !_isSearchingBarber,
                                        decoration: InputDecoration(
                                          hintText: 'Enter phone number',
                                          prefixIcon: const Icon(
                                            Icons.phone_outlined,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _isSearchingBarber
                                          ? null
                                          : _searchBarberByPhone,
                                      icon: _isSearchingBarber
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.search),
                                      label: const Text('Search'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_barberFoundFromPhone)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        border: Border.all(color: Colors.green),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Barber found! Details populated below',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Barber Photo Upload
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _barberPhotoFile != null
                                    ? const Color(0xFF1E88E5)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                if (_barberPhotoFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_barberPhotoFile!.path),
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Barber Photo *',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _barberPhotoFile != null
                                                ? 'Photo selected ✓'
                                                : 'Upload barber photo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _barberPhotoFile != null
                                                  ? Colors.green
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _showPhotoPickerDialog,
                                      icon: const Icon(Icons.add_a_photo),
                                      label: const Text('Upload'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1E88E5,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Name field
                          TextFormField(
                            controller: _barberNameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Barber Full Name',
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Email field
                          TextFormField(
                            controller: _barberEmailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              ).hasMatch(value!)) {
                                return 'Valid email is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Experience field
                          TextFormField(
                            controller: _barberExperienceController,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Years of Experience',
                              prefixIcon: const Icon(Icons.work_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Experience is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Bio field
                          TextFormField(
                            controller: _barberBioController,
                            maxLines: 3,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Professional Bio',
                              prefixIcon: const Icon(Icons.info_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Bio is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Referral Code field (Optional)
                          TextFormField(
                            controller: _referralCodeController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Referral Code (Optional)',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              suffixIcon:
                                  _referralCodeController.text.isNotEmpty
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              helperText:
                                  'If you were registered by someone, enter their referral code here',
                            ),
                            onChanged: (value) {
                              setState(() {}); // Refresh to show/hide checkmark
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Specialties
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Select Specialties *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                  'Haircut',
                                  'Beard Trim',
                                  'Shaving',
                                  'Hair Coloring',
                                  'Styling',
                                  'Threading',
                                  'Hair Wash',
                                  'Head Massage',
                                ].map((specialty) {
                                  final isSelected = _selectedSpecialties
                                      .contains(specialty);
                                  return FilterChip(
                                    label: Text(specialty),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedSpecialties.add(specialty);
                                        } else {
                                          _selectedSpecialties.remove(
                                            specialty,
                                          );
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: const Color(
                                      0xFF1E88E5,
                                    ).withAlpha((0.2 * 255).round()),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey[700],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 24),

                          /// Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _showAddBarberForm = false;
                                            _formKey.currentState?.reset();
                                            _barberPhotoFile = null;
                                            _selectedSpecialties = [];
                                          });
                                        },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleAddBarber,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text('Add Barber'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
