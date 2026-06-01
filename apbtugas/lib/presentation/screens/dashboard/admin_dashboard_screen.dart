import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const AppLogo(size: 32, showTagline: false, horizontal: true),
        actions: [
          // Admin badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(100)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.secondary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, user),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.adminCreateEmployee),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Karyawan'),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Greeting
            _buildAdminGreeting(context, user),
            const SizedBox(height: 20),

            // Stats Row
            Text('Ringkasan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildStatsGrid(context),
            const SizedBox(height: 20),

            // Management Menu
            Text(
              'Manajemen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildManagementMenu(context),
            const SizedBox(height: 20),

            // Recent Activity
            Text(
              'Aktivitas Terbaru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminGreeting(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2F55), Color(0xFF112244)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.welcomeBack,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Administrator',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: AppColors.secondary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.adminRole,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withAlpha(100)),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.secondary, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _StatCard(
          label: AppStrings.totalEmployees,
          value: '48',
          icon: Icons.group_rounded,
          color: AppColors.info,
          trend: '+2 bulan ini'),
      _StatCard(
          label: AppStrings.activeToday,
          value: '42',
          icon: Icons.how_to_reg_rounded,
          color: AppColors.success,
          trend: '87.5% kehadiran'),
      _StatCard(
          label: AppStrings.pendingApproval,
          value: '5',
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
          trend: 'Perlu review'),
      _StatCard(
          label: 'Departemen',
          value: '6',
          icon: Icons.business_rounded,
          color: AppColors.secondary,
          trend: 'Aktif'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) => _buildStatCard(context, stats[i]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatCard stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: stat.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              Text(
                stat.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      )),
              Text(stat.trend,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: stat.color,
                        fontSize: 10,
                      )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementMenu(BuildContext context) {
    final menus = [
      _MenuCard(
          icon: Icons.people_rounded,
          label: 'Kelola Karyawan',
          subtitle: '48 karyawan aktif',
          color: AppColors.info),
      _MenuCard(
          icon: Icons.assignment_turned_in_rounded,
          label: 'Laporan Absensi',
          subtitle: 'Bulan Mei 2025',
          color: AppColors.success),
      _MenuCard(
          icon: Icons.campaign_rounded,
          label: 'Pengumuman',
          subtitle: 'Kelola pengumuman',
          color: AppColors.warning),
      _MenuCard(
          icon: Icons.settings_rounded,
          label: 'Pengaturan',
          subtitle: 'Konfigurasi sistem',
          color: AppColors.grey500),
    ];

    return Column(
      children: menus
          .map((menu) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: menu.color.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: menu.color.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(menu.icon,
                              color: menu.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(menu.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: AppColors.textPrimary)),
                              Text(menu.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: menu.color, size: 16),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      'Budi Santoso telah diabsen masuk — 08:02',
      'Siti Rahma mengajukan izin — kemarin',
      'Ahmad Fauzi ditambahkan sebagai karyawan baru',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: activities
            .asMap()
            .entries
            .map((entry) => Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    if (entry.key < activities.length - 1) ...[
                      const SizedBox(height: 4),
                      const Divider(color: AppColors.primaryLight),
                      const SizedBox(height: 4),
                    ],
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded), label: 'Karyawan'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded), label: 'Laporan'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.primaryCard)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 3) {
            _showLogoutDialog();
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: items,
      ),
    );
  }

  void _showLogoutDialog() {
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
              if (mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );
  }
}

class _StatCard {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.trend});
}

class _MenuCard {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  const _MenuCard(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color});
}
