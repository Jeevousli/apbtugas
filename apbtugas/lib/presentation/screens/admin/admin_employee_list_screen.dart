import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/admin_provider.dart';

class AdminEmployeeListScreen extends StatefulWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  State<AdminEmployeeListScreen> createState() =>
      _AdminEmployeeListScreenState();
}

class _AdminEmployeeListScreenState extends State<AdminEmployeeListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final employees = admin.filteredEmployees;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Daftar Karyawan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: admin.searchEmployees,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIK, atau departemen...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          admin.searchEmployees('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primaryCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: admin.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : employees.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) =>
                      _buildEmployeeCard(ctx, employees[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded,
              color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 12),
          Text('Tidak ada karyawan ditemukan',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, UserEntity emp) {
    return InkWell(
      onTap: () => context
          .push('${AppRoutes.adminEmployeeDetail}?uid=${emp.uid}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withAlpha(15)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary.withAlpha(60)),
              ),
              child: ClipOval(child: _buildAvatar(emp)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('NIK: ${emp.nik}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  if (emp.department != null)
                    Text(emp.department!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: emp.isAdmin
                        ? AppColors.secondary.withAlpha(25)
                        : AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emp.isAdmin ? 'Admin' : 'Karyawan',
                    style: TextStyle(
                        color: emp.isAdmin
                            ? AppColors.secondary
                            : AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserEntity emp) {
    final photoUrl = emp.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final b64 = photoUrl.substring(photoUrl.indexOf(',') + 1);
          return Image.memory(base64Decode(b64), fit: BoxFit.cover);
        } catch (_) {}
      } else {
        return Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(emp.name));
      }
    }
    return _initials(emp.name);
  }

  Widget _initials(String name) {
    return Container(
      color: AppColors.secondary.withAlpha(40),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
    );
  }
}
