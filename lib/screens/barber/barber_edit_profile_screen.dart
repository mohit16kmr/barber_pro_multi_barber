import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import 'package:barber_pro/providers/barber_provider.dart';
import '../../models/index.dart';
import '../../services/index.dart';

class BarberEditProfileScreen extends StatefulWidget {
  const BarberEditProfileScreen({super.key});

  @override
  State<BarberEditProfileScreen> createState() =>
      _BarberEditProfileScreenState();
}

class _BarberEditProfileScreenState extends State<BarberEditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _referralCodeController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _ratingController;
  bool _isLoading = false;
  List<String> _selectedSpecialties = [];
  List<Service> _services = [];
  Barber? _barberDoc;
  bool _barberNotFound = false;
  final double _rating = 4.5;

  // Photo handling
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _barberPhotoFile;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _shopNameController = TextEditingController(text: user?.shopId ?? '');
    _referralCodeController = TextEditingController(
      text: user?.referralCode ?? '',
    );
    _addressController = TextEditingController(text: user?.city ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _experienceController = TextEditingController(
      text: user?.yearsOfExperience?.toString() ?? '',
    );
    _ratingController = TextEditingController(
      text: user?.rating?.toString() ?? '',
    );
    _selectedSpecialties = user?.specialties ?? [];
    // Load barber document to get editable services
    final barberService = BarberService();
    () async {
      try {
        final uid = user?.uid;
        if (uid != null) {
          final barber = await barberService.getBarberById(uid);
          if (barber != null) {
            setState(() {
              _barberDoc = barber;
              _services = List<Service>.from(barber.services);
            });
          } else {
            setState(() {
              _barberNotFound = true;
            });
          }
        } else {
          setState(() {
            _barberNotFound = true;
          });
        }
      } catch (_) {
        setState(() {
          _barberNotFound = true;
        });
      }
    }();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _ratingController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // Helper method to pick photo
  Future<void> _pickBarberPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
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
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // Show photo picker dialog
  void _showPhotoPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Profile Photo'),
          content: const Text('Choose a photo source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickBarberPhoto(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickBarberPhoto(ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final shopId = _shopNameController.text.trim();
      final referralCode = _referralCodeController.text.trim();
      final city = _addressController.text.trim();
      final bio = _bioController.text.trim();
      final years = int.tryParse(_experienceController.text.trim());
      final specialties = _selectedSpecialties;

      bool ok = false;

      if (authProvider.needsRegistration) {
        // Complete registration for external-authenticated user
        ok = await authProvider.completeRegistrationForCurrentUser(
          name: name.isEmpty ? (authProvider.currentUser?.name ?? '') : name,
          userRole: 'barber',
          phone: phone.isEmpty ? null : phone,
          city: city.isEmpty ? null : city,
          shopId: shopId.isEmpty ? null : shopId,
          referralCode: referralCode.isEmpty ? null : referralCode,
        );
        // After completing registration, persist any additional barber fields
        if (ok) {
          await authProvider.updateUserProfile(
            displayName: name,
            phoneNumber: phone.isEmpty ? null : phone,
            city: city.isEmpty ? null : city,
            shopId: shopId.isEmpty ? null : shopId,
            referralCode: referralCode.isEmpty ? null : referralCode,
            yearsOfExperience: years,
            specialties: specialties.isEmpty ? null : specialties,
            bio: bio.isEmpty ? null : bio,
          );
        }
      } else {
        // Regular profile update
        ok = await authProvider.updateUserProfile(
          displayName: name.isEmpty ? null : name,
          phoneNumber: phone.isEmpty ? null : phone,
          city: city.isEmpty ? null : city,
          shopId: shopId.isEmpty ? null : shopId,
          referralCode: referralCode.isEmpty ? null : referralCode,
          yearsOfExperience: years,
          specialties: specialties.isEmpty ? null : specialties,
          bio: bio.isEmpty ? null : bio,
        );
      }

      if (!mounted) return;

        if (ok) {
          // Attempt to persist barber services to Firestore (if barber doc exists)
          if (_barberDoc != null) {
            try {
              final barberService = BarberService();
              final updatedBarber = _barberDoc!.copyWith(
                services: _services,
                shopName: shopId.isNotEmpty ? shopId : _barberDoc!.shopName,
                ownerName: name.isNotEmpty ? name : _barberDoc!.ownerName,
                phone: phone.isNotEmpty ? phone : _barberDoc!.phone,
                address: city.isNotEmpty ? city : _barberDoc!.address,
                referralCode: referralCode.isNotEmpty ? referralCode : _barberDoc!.referralCode,
              );
              await barberService.updateBarber(_barberDoc!.barberId, updatedBarber);
              // Light refresh: fetch the single barber and select it in the provider
              try {
                final refreshed = await context.read<BarberProvider>().getBarberById(_barberDoc!.barberId);
                if (refreshed != null) {
                  context.read<BarberProvider>().selectBarber(refreshed);
                }
              } catch (_) {}
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated but failed to save services: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _barberPhotoFile != null
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey[300]!,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF1E88E5),
                            backgroundImage: _barberPhotoFile != null
                                ? FileImage(File(_barberPhotoFile!.path))
                                : null,
                            child: _barberPhotoFile == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'B',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showPhotoPickerDialog,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Barber Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$_rating (45 reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Professional Information Section
              _buildSectionHeader('Professional Information'),
              const SizedBox(height: 12),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 16),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Experience Field
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                icon: Icons.work_outline,
                hint: 'Years',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Rating Display
              _buildTextField(
                controller: _ratingController,
                label: 'Rating',
                icon: Icons.star,
                hint: 'Rating out of 5',
                keyboardType: TextInputType.number,
                enabled: false,
              ),
              const SizedBox(height: 24),

              // Shop Information Section
              _buildSectionHeader('Shop Information'),
              const SizedBox(height: 12),

              // Shop Name Field
              _buildTextField(
                controller: _shopNameController,
                label: 'Shop/Salon Name',
                icon: Icons.store,
                hint: 'Enter shop name',
              ),
              const SizedBox(height: 16),

              // Referral Code Field
              _buildTextField(
                controller: _referralCodeController,
                label: 'Referral Code (optional)',
                icon: Icons.badge,
                hint: 'Enter referral code if applicable',
              ),
              const SizedBox(height: 16),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Shop Address',
                icon: Icons.location_on,
                hint: 'Enter complete address',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About & Bio'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _bioController,
                label: 'Professional Bio',
                icon: Icons.description,
                hint: 'Tell customers about yourself and your expertise',
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Specialties Section
              _buildSectionHeader('Specialties'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Select all services you offer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
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
                      final isSelected = _selectedSpecialties.contains(
                        specialty,
                      );
                      return FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSpecialties.add(specialty);
                            } else {
                              _selectedSpecialties.remove(specialty);
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

              const SizedBox(height: 16),

              // Services Editor
              _buildSectionHeader('Services'),
              const SizedBox(height: 8),
              if (_barberNotFound)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Barber record not found. Services cannot be edited until your shop is registered.',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              Column(
                children: [
                  ..._services.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final service = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(service.name),
                        subtitle: Text('\$${service.price.toStringAsFixed(2)} • ${service.durationMinutes} min'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                              onPressed: () => _showAddEditServiceDialog(index: idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeService(idx),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _barberNotFound ? null : () => _showAddEditServiceDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Service'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 8),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            filled: !enabled,
            fillColor: !enabled ? Colors.grey[100] : null,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters ?? [],
        ),
      ],
    );
  }

  // Show dialog to add or edit a service
  Future<void> _showAddEditServiceDialog({int? index}) async {
    final isEdit = index != null;
    final nameController = TextEditingController(text: isEdit ? _services[index!].name : '');
    final priceController = TextEditingController(text: isEdit ? _services[index!].price.toString() : '');
    final durationController = TextEditingController(text: isEdit ? _services[index!].durationMinutes.toString() : '30');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Service' : 'Add Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final duration = int.tryParse(durationController.text.trim()) ?? 30;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a service name')),
                  );
                  return;
                }

                final newService = Service(name: name, price: price, durationMinutes: duration);
                setState(() {
                  if (isEdit) {
                    _services[index!] = newService;
                  } else {
                    _services.add(newService);
                  }
                });

                Navigator.of(context).pop();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeService(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Service'),
        content: const Text('Are you sure you want to remove this service?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
