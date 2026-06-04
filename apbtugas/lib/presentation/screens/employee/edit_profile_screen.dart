import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _localPhotoPath;
  bool _cameraLoading = false;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() {
      _cameraLoading = true;
    });
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      _showCameraDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cameraLoading = false;
        });
      }
    }
  }

  void _showCameraDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.primaryCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Ambil Foto Profil',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cameraController != null && _cameraController!.value.isInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _cameraController?.dispose();
                    _cameraController = null;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final photo = await _cameraController!.takePicture();
                      setState(() {
                        _localPhotoPath = photo.path;
                      });
                      _cameraController?.dispose();
                      _cameraController = null;
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mengambil foto: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, color: AppColors.white),
                  label: const Text('Ambil', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.currentUser;

    final isSaving = profileProvider.isUpdating || profileProvider.isUploadingPhoto;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfileTitle),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Foto Profil Selector ──
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.secondary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withAlpha(30),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _buildImagePreview(user),
                      ),
                    ),
                    GestureDetector(
                      onTap: isSaving || _cameraLoading ? null : _startCamera,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: _cameraLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Form Input Fields ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withAlpha(15)),
                  ),
                  child: Column(
                    children: [
                      // Name Input
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: AppStrings.nameLabel,
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.secondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.secondary.withAlpha(30)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.secondary.withAlpha(20)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone Input
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: AppStrings.phoneLabel,
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.secondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.secondary.withAlpha(30)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.secondary.withAlpha(20)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 9) {
                            return 'Nomor telepon minimal 9 digit';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Simpan Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => _saveProfile(authProvider, profileProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Menyimpan...',
                                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : const Text(
                            AppStrings.saveButton,
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(user) {
    if (_localPhotoPath != null) {
      return Image.file(
        File(_localPhotoPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      if (user.photoUrl!.startsWith('data:image')) {
        try {
          final base64Data = user.photoUrl!.substring(user.photoUrl!.indexOf(',') + 1);
          return Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } catch (_) {}
      } else {
        return CachedNetworkImage(
          imageUrl: user.photoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (context, url, error) => _buildInitials(user?.name),
        );
      }
    }
    return _buildInitials(user?.name);
  }

  Widget _buildInitials(String? name) {
    final initial = name != null && name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(color: AppColors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveProfile(AuthProvider authProvider, ProfileProvider profileProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final user = authProvider.currentUser;
    if (user == null) return;

    bool uploadSuccess = true;
    if (_localPhotoPath != null) {
      uploadSuccess = await profileProvider.uploadProfilePhoto(
        authProvider: authProvider,
        uid: user.uid,
        filePath: _localPhotoPath!,
      );
    }

    if (!uploadSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Gagal mengupload foto profil'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final updateSuccess = await profileProvider.updateProfile(
      authProvider: authProvider,
      uid: user.uid,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      if (updateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Gagal memperbarui profil'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
