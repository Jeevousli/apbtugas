import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/admin_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminEmployeeDetailScreen extends StatefulWidget {
  final String uid;
  const AdminEmployeeDetailScreen({super.key, required this.uid});

  @override
  State<AdminEmployeeDetailScreen> createState() =>
      _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState
    extends State<AdminEmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEmployeeDetail(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final emp = admin.selectedEmployee;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(emp?.name ?? 'Detail Karyawan',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (emp != null)
            PopupMenuButton<String>(
              color: AppColors.primaryCard,
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textPrimary),
              onSelected: (val) => _onMenuSelected(context, val, emp),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'logs',
                    child: Text('Lihat Log Absensi',
                        style: TextStyle(color: AppColors.textPrimary))),
                PopupMenuItem(
                    value: 'toggle_role',
                    child: Text(
                        emp.isAdmin
                            ? 'Jadikan Karyawan'
                            : 'Jadikan Admin',
                        style:
                            const TextStyle(color: AppColors.textPrimary))),
              ],
            ),
        ],
      ),
      body: admin.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : emp == null
              ? const Center(
                  child: Text('Data tidak ditemukan',
                      style: TextStyle(color: AppColors.textSecondary)))
              : _buildBody(context, emp),
    );
  }

  void _onMenuSelected(
      BuildContext context, String val, UserEntity emp) async {
    final admin = context.read<AdminProvider>();
    if (val == 'logs') {
      await admin.loadEmployeeLogs(emp.uid);
      if (context.mounted) {
        context.push(
            '${AppRoutes.adminAttendanceLogs}?uid=${emp.uid}&name=${emp.name}');
      }
    } else if (val == 'toggle_role') {
      final newRole =
          emp.isAdmin ? UserRole.employee : UserRole.admin;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.primaryCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ubah Role',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
              'Jadikan ${emp.name} sebagai ${newRole == UserRole.admin ? "Admin" : "Karyawan"}?',
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ya, Ubah')),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        await admin.updateEmployeeRole(emp.uid, newRole);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Role berhasil diubah')));
          context.pop();
        }
      }
    }
  }

  Widget _buildBody(BuildContext context, UserEntity emp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Identity card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(25)),
            ),
            child: Column(
              children: [
                // Card header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withAlpha(30),
                        AppColors.secondary.withAlpha(10),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_rounded,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: 8),
                      const Text('EMPLOYEE ID CARD',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 11)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: emp.isAdmin
                              ? AppColors.secondary.withAlpha(30)
                              : AppColors.success.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emp.isAdmin ? 'ADMIN' : 'KARYAWAN',
                          style: TextStyle(
                              color: emp.isAdmin
                                  ? AppColors.secondary
                                  : AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.secondary, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.secondary.withAlpha(40),
                                blurRadius: 12)
                          ],
                        ),
                        child: ClipOval(child: _buildAvatar(emp)),
                      ),
                      const SizedBox(height: 14),
                      Text(emp.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(emp.position ?? 'Staff',
                          style: const TextStyle(
                              color: AppColors.secondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      _row('NIK', emp.nik),
                      _divider(),
                      _row('Email', emp.email),
                      _divider(),
                      _row('Telepon', emp.phone ?? '-'),
                      _divider(),
                      _row('Departemen', emp.department ?? '-'),
                      _divider(),
                      _row('Status',
                          (emp.employeeStatus ?? 'Aktif').toUpperCase()),
                      _divider(),
                      _row('Bergabung', _fmtDate(emp.createdAt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context
                        .read<AdminProvider>()
                        .loadEmployeeLogs(emp.uid);
                    if (context.mounted) {
                      context.push(
                          '${AppRoutes.adminAttendanceLogs}?uid=${emp.uid}&name=${emp.name}');
                    }
                  },
                  icon: const Icon(Icons.assignment_rounded, size: 16),
                  label: const Text('Log Absensi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _divider() =>
      Divider(height: 10, color: AppColors.textSecondary.withAlpha(12));

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Widget _buildAvatar(UserEntity emp) {
    final url = emp.photoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          return Image.memory(
              base64Decode(url.substring(url.indexOf(',') + 1)),
              fit: BoxFit.cover);
        } catch (_) {}
      } else {
        return CachedNetworkImage(
            imageUrl: url, 
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _initials(emp.name));
      }
    }
    return _initials(emp.name);
  }

  Widget _initials(String name) => Container(
        color: AppColors.secondary.withAlpha(40),
        child: Center(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'K',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
        ),
      );
}
