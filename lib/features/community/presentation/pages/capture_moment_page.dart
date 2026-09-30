import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_watermark_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../application/providers/community_providers.dart';

class CaptureMomentPage extends ConsumerStatefulWidget {
  const CaptureMomentPage({super.key});

  @override
  ConsumerState<CaptureMomentPage> createState() => _CaptureMomentPageState();
}

class _CaptureMomentPageState extends ConsumerState<CaptureMomentPage> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  final _watermarkService = const ImageWatermarkService();

  Uint8List? _capturedBytes;
  bool _isSaving = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureFromCamera();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
    });
    try {
      final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
      if (kIsWeb) {
        _showMessage('Camera capture is limited on web. Opening gallery instead.');
      }
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (image == null) {
        _showMessage('Image selection cancelled.');
        if (mounted && _capturedBytes == null) {
          Navigator.of(context).pop(false);
        }
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedBytes = bytes;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _saveMoment() async {
    if (_capturedBytes == null) {
      _showMessage('Please capture a photo first.');
      return;
    }
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      _showMessage('Please sign in to save a moment.');
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final watermarked = await _watermarkService.applyCenteredLogoWatermark(
        _capturedBytes!,
      );
      final uploaderName =
          (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : ((user.email != null && user.email!.trim().isNotEmpty)
                ? user.email!.trim()
                : 'Malaya user');

      final repository = ref.read(communityRepositoryProvider);
      final imageUrl = await repository.uploadWatermarkedImage(
        bucket: 'captured-moments',
        folderPrefix: user.id,
        bytes: watermarked,
      );
      await repository.createCapturedMoment(
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        imageUrl: imageUrl,
        userId: user.id,
        uploaderName: uploaderName,
      );

      ref.invalidate(myCapturedMomentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Moment saved successfully.')));
      Navigator.of(context).pop(true);
    } catch (_) {
      _showMessage('Unable to upload image. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
      appBar: AppBar(title: const Text('Capture Moment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_capturedBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _capturedBytes!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: _isPicking
                    ? const CircularProgressIndicator()
                    : Text(
                        'No image captured.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _captionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Caption/description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _captureFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveMoment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(_isSaving ? 'Saving...' : 'Save Moment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
