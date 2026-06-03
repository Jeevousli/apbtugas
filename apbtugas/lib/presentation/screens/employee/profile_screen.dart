import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── EMPLOYEE IDENTITY CARD ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.secondary.withAlpha(25)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withAlpha(30),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Card Header with Badge/Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fingerprint_rounded, color: AppColors.secondary, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'EMPLOYEE ID CARD',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (user?.employeeStatus ?? 'Aktif').toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.secondary, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withAlpha(40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarImage(user?.photoUrl, user?.name),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name and Position
                          Text(
                            user?.name ?? 'Karyawan',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.position ?? 'Staff Karyawan',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Detailed Fields
                          _buildCardRow(context, 'NIK', user?.nik ?? '-'),
                          _buildCardDivider(),
                          _buildCardRow(context, 'Email', user?.email ?? '-'),
                          _buildCardDivider(),
                          _buildCardRow(context, 'Nomor Telepon', user?.phone ?? '-'),
                          _buildCardDivider(),
                          _buildCardRow(context, 'Departemen', user?.department ?? 'Operasional'),
                          _buildCardDivider(),
                          _buildCardRow(
                            context,
                            'Tanggal Bergabung',
                            user != null ? _formatDate(user.createdAt) : '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── SETTINGS / ACTIONS SECTION ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary.withAlpha(10)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.edit_rounded,
                      label: 'Edit Profil',
                      color: AppColors.secondary,
                      onTap: () {
                        context.push(AppRoutes.editProfile);
                      },
                    ),
                    _buildMenuDivider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.lock_outline_rounded,
                      label: 'Ubah Password',
                      color: AppColors.info,
                      onTap: () {
                        context.push(AppRoutes.changePassword);
                      },
                    ),
                    _buildMenuDivider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang Aplikasi',
                      color: AppColors.success,
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: AppStrings.appName,
                          applicationVersion: AppStrings.appVersion,
                          applicationIcon: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.secondary,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Logout Button ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(AppStrings.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Version ──
              Text(
                'APB Connect v${AppStrings.appVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? photoUrl, String? userName) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final base64Data = photoUrl.substring(photoUrl.indexOf(',') + 1);
          return Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } catch (_) {}
      } else {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(userName),
        );
      }
    }
    return _buildInitialsAvatar(userName);
  }

  Widget _buildInitialsAvatar(String? name) {
    final initials = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.accentGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCardRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDivider() {
    return Divider(height: 12, color: AppColors.textSecondary.withAlpha(15));
  }

  Widget _buildMenuDivider() {
    return Divider(height: 1, color: AppColors.textSecondary.withAlpha(10), indent: 56);
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );
  }
}
