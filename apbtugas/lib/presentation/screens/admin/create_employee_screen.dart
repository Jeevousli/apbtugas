import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _nikFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _nikFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.createEmployee(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      nik: _nikController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Gagal menambahkan karyawan');
      authProvider.clearError();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Text('Sukses'),
          ],
        ),
        content: Text(
          'Karyawan dengan NIK ${_nikController.text} berhasil didaftarkan.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              context.pop(); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primaryCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Tambah Karyawan Baru'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendaftaran Karyawan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Isi formulir di bawah ini untuk membuat akun karyawan baru.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    CustomTextField(
                      label: 'Nama Lengkap',
                      hint: 'Nama Lengkap Karyawan',
                      controller: _nameController,
                      focusNode: _nameFocus,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _nameFocus.unfocus();
                        FocusScope.of(context).requestFocus(_nikFocus);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // NIK Field
                    CustomTextField(
                      label: 'Nomor Induk Karyawan (NIK)',
                      hint: 'Masukkan 8-16 digit angka NIK',
                      controller: _nikController,
                      focusNode: _nikFocus,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.badge_outlined,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 16,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _nikFocus.unfocus();
                        FocusScope.of(context).requestFocus(_emailFocus);
                      },
                      validator: AppValidators.validateNik,
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      label: 'Alamat Email',
                      hint: 'karyawan@email.com',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _emailFocus.unfocus();
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    CustomTextField(
                      label: 'Password Akun',
                      hint: 'Min. 6 karakter',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _handleSubmit,
                      validator: AppValidators.validatePassword,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      label: 'Daftarkan Karyawan',
                      onPressed: _handleSubmit,
                      isLoading: auth.isLoading,
                      leadingIcon: Icons.person_add_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
