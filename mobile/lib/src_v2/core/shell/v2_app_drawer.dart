import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/core/auth/auth_store.dart';
import '../rbac/role_utils.dart';

// Existing pages you already have
import '../../features/orders/presentation/pages/orders_dashboard_page.dart';
import '../../features/orders/presentation/pages/create_order_page.dart';
import '../../workspaces/nurse/nurse_tasks_page.dart';
import '../../core/settings/v2_settings_page.dart';

// Admin staff pages
import '../../features/admin_staff/presentation/pages/admin_users_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_user_page.dart';

// ✅ Departments pages (new)
import '../../features/admin_staff/presentation/pages/admin_departments_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_department_page.dart';

class V2AppDrawer extends StatelessWidget {
  const V2AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;

    final isAdmin = RoleUtils.hasRole(user, 'ADMIN');
    final isDoctor = RoleUtils.hasRole(user, 'DOCTOR');
    final isNurse = RoleUtils.hasRole(user, 'NURSE');

    final fullName = user?['fullName']?.toString().trim();
    final userName = (fullName == null || fullName.isEmpty) ? '—' : fullName;

    final rolesRaw = (user?['roles'] is List)
        ? (user?['roles'] as List)
        : const [];
    final rolesText = rolesRaw
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();

    final roleLabel = _roleLabel(rolesText);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(userName: userName, roleLabel: roleLabel),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  if (isDoctor) ...[
                    _sectionTitle('الطبيب'),
                    _item(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'لوحة الأوامر',
                      onTap: () => _go(context, const OrdersDashboardPage()),
                    ),
                    _item(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      title: 'إنشاء أمر',
                      onTap: () => _go(context, const CreateOrderPage()),
                    ),
                    _softDivider(),
                  ],

                  if (isNurse) ...[
                    _sectionTitle('التمريض'),
                    _item(
                      context,
                      icon: Icons.checklist_rounded,
                      title: 'مهامي',
                      onTap: () => _go(context, const NurseTasksPage()),
                    ),
                    _softDivider(),
                  ],

                  if (isAdmin) ...[
                    _sectionTitle('الإدارة'),
                    _item(
                      context,
                      icon: Icons.groups_2_rounded,
                      title: 'الموظفون',
                      onTap: () => _go(context, const AdminUsersPage()),
                    ),
                    _item(
                      context,
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'إضافة موظف',
                      onTap: () => _go(context, const AdminCreateUserPage()),
                    ),

                    // ✅ New: Departments
                    _item(
                      context,
                      icon: Icons.apartment_rounded,
                      title: 'الأقسام',
                      onTap: () => _go(context, const AdminDepartmentsPage()),
                    ),
                    _item(
                      context,
                      icon: Icons.add_business_rounded,
                      title: 'إضافة قسم',
                      onTap: () =>
                          _go(context, const AdminCreateDepartmentPage()),
                    ),
                    _softDivider(),
                  ],

                  _sectionTitle('التطبيق'),
                  _item(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'الإعدادات',
                    onTap: () => _go(context, const V2SettingsPage()),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FilledButton.icon(
                onPressed: () async {
                  // ✅ logout should work here
                  // keep behavior minimal and safe
                  Navigator.pop(context); // close drawer first
                  await context.read<AuthStore>().logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل خروج'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(List<String> rolesUpper) {
    if (rolesUpper.contains('ADMIN')) return 'Admin';
    if (rolesUpper.contains('DOCTOR')) return 'Doctor';
    if (rolesUpper.contains('NURSE')) return 'Nurse';
    if (rolesUpper.contains('LAB')) return 'Lab';
    if (rolesUpper.contains('PHARMACY')) return 'Pharmacy';
    if (rolesUpper.contains('RECEPTION')) return 'Reception';
    return '';
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface.withAlpha(220)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .2),
      ),
    );
  }

  Widget _softDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 18),
  );

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _Header extends StatelessWidget {
  final String userName;
  final String roleLabel;

  const _Header({required this.userName, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withAlpha(18),
            child: Icon(
              Icons.local_hospital_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (roleLabel.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withAlpha(170),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
