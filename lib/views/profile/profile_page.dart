import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import '../../data/database.dart';
import '../../repositories/profile_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _photoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (profile != null && mounted) {
      _nameController.text = profile.name;
      _salaryController.text = profile.salary.toString();
      _addressController.text = profile.address ?? '';
      _phoneController.text = profile.phone ?? '';
      setState(() {
        _photoPath = profile.photoPath;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final profile = ProfilesCompanion(
        name: drift.Value(_nameController.text),
        salary: drift.Value(double.tryParse(_salaryController.text) ?? 0.0),
        address: drift.Value(_addressController.text.isEmpty ? null : _addressController.text),
        phone: drift.Value(_phoneController.text.isEmpty ? null : _phoneController.text),
        photoPath: drift.Value(_photoPath),
      );

      try {
        await ref.read(profileRepositoryProvider).saveProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to change photo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Salary',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your salary';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address (Optional)',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Save Profile',
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
