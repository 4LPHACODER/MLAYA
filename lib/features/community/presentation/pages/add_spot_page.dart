import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_watermark_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../application/providers/community_providers.dart';

class AddSpotPage extends ConsumerStatefulWidget {
  const AddSpotPage({super.key});

  @override
  ConsumerState<AddSpotPage> createState() => _AddSpotPageState();
}

class _AddSpotPageState extends ConsumerState<AddSpotPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  final _watermarkService = const ImageWatermarkService();

  String _selectedCategory = 'Beach';
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  static const _categories = [
    'Beach',
    'Mountain',
    'Falls',
    'Park',
    'River',
    'Camping',
    'Hiking',
    'Surfing',
    'Fishing',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final chosenSource = (kIsWeb && source == ImageSource.camera)
        ? ImageSource.gallery
        : source;
    if (kIsWeb && source == ImageSource.camera) {
      _showMessage('Camera capture is limited on web. Opening gallery instead.');
    }

    final image = await _picker.pickImage(
      source: chosenSource,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (image == null) {
      _showMessage('Image selection cancelled.');
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImageBytes == null) {
      _showMessage('Please select or capture an image.');
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      _showMessage('Please sign in to add a spot.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final watermarked = await _watermarkService.applyCenteredLogoWatermark(
        _selectedImageBytes!,
      );
      final uploaderName =
          (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : ((user.email != null && user.email!.trim().isNotEmpty)
                ? user.email!.trim()
                : 'Malaya user');

      final repository = ref.read(communityRepositoryProvider);
      final imageUrl = await repository.uploadWatermarkedImage(
        bucket: 'added-spots',
        folderPrefix: user.id,
        bytes: watermarked,
      );
      await repository.createAddedSpot(
        spotName: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        imageUrl: imageUrl,
        userId: user.id,
        uploaderName: uploaderName,
      );

      ref.invalidate(myAddedSpotsProvider);
      ref.invalidate(publicAddedSpotsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spot added successfully.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage('Unable to upload image. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Spot')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Spot name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a spot name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location/address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'No image selected yet',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Saving...' : 'Submit Spot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
