import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_logo.dart';

import '../admin/admin_employee_list_screen.dart';
import '../admin/admin_kpi_charts_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final user = auth.currentUser;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardScreen(context, admin, user),
          const AdminEmployeeListScreen(),
          const AdminKpiChartsScreen(),
          const SizedBox(), // Placeholder for logout
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardScreen(BuildContext context, AdminProvider admin, dynamic user) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const AppLogo(size: 32, showTagline: false, horizontal: true),
        actions: [
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
                Text('Admin',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, admin, user, (int index) {
        setState(() {
          _selectedIndex = index;
        });
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCreateEmployee),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Karyawan'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminProvider admin, dynamic user, Function(int) onNavigate) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: admin.loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Greeting
              _buildAdminGreeting(context, user),
              const SizedBox(height: 20),

              // Real-time stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (admin.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.secondary),
                    )
                  else
                    GestureDetector(
                      onTap: admin.loadDashboardStats,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.secondary, size: 20),
                    ),
                ],
              ),
              if (admin.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    admin.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildStatsGrid(context, admin),
              const SizedBox(height: 20),

              // Quick Actions
              Text('Menu Admin',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildAdminMenus(context, onNavigate),
              const SizedBox(height: 20),


            ],
          ),
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
                Text(AppStrings.welcomeBack,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        )),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.secondary.withAlpha(100)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.secondary, size: 14),
                      SizedBox(width: 4),
                      Text(AppStrings.adminRole,
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
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

  Widget _buildStatsGrid(BuildContext context, AdminProvider admin) {
    final stats = admin.stats;
    final items = [
      _StatItem(
        label: 'Total Karyawan',
        value: stats != null ? '${stats.totalEmployees}' : '--',
        icon: Icons.group_rounded,
        color: AppColors.info,
        sub: 'terdaftar',
      ),
      _StatItem(
        label: 'Hadir Hari Ini',
        value: stats != null ? '${stats.presentToday}' : '--',
        icon: Icons.how_to_reg_rounded,
        color: AppColors.success,
        sub: stats != null
            ? '${stats.attendanceRate.toStringAsFixed(0)}% kehadiran'
            : '…',
      ),
      _StatItem(
        label: 'Terlambat',
        value: stats != null ? '${stats.lateToday}' : '--',
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        sub: 'hari ini',
      ),
      _StatItem(
        label: 'Tidak Hadir',
        value: stats != null ? '${stats.absentToday}' : '--',
        icon: Icons.person_off_rounded,
        color: AppColors.error,
        sub: 'alpha/izin',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(context, items[i]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: stat.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 17),
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
              Text(stat.sub,
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

  Widget _buildAdminMenus(BuildContext context, Function(int) onNavigate) {
    final menus = [
      _MenuItem(
        icon: Icons.people_rounded,
        label: 'Daftar Karyawan',
        subtitle: 'Kelola & detail karyawan',
        color: AppColors.info,
        onTap: () => onNavigate(1),
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'KPI & Statistik',
        subtitle: 'Grafik kehadiran mingguan',
        color: AppColors.success,
        onTap: () => onNavigate(2),
      ),

      _MenuItem(
        icon: Icons.person_add_rounded,
        label: 'Tambah Karyawan',
        subtitle: 'Buat akun karyawan baru',
        color: AppColors.secondary,
        onTap: () => context.push(AppRoutes.adminCreateEmployee),
      ),
    ];

    return Column(
      children: menus
          .map((m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: m.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: m.color.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: m.color.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(m.icon, color: m.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: AppColors.textPrimary)),
                              Text(m.subtitle,
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
                            color: m.color, size: 16),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNav() {
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
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Karyawan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'KPI'),
          BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded), label: 'Keluar'),
        ],
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

class _StatItem {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.sub});
}

class _MenuItem {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});
}
