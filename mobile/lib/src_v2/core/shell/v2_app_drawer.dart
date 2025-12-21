import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/core/auth/auth_store.dart';
import '../rbac/role_utils.dart';

// Existing pages you already have
import '../../features/orders/presentation/pages/orders_dashboard_page.dart';
import '../../features/orders/presentation/pages/create_order_page.dart';
import '../../workspaces/nurse/nurse_tasks_page.dart';
import '../../core/settings/v2_settings_page.dart';

// Admin pages
import '../../features/admin_staff/presentation/pages/admin_users_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_user_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_department_page.dart'; // ✅ NEW

class V2AppDrawer extends StatelessWidget {
  const V2AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;

    final isAdmin = RoleUtils.hasRole(user, 'ADMIN');
    final isDoctor = RoleUtils.hasRole(user, 'DOCTOR');
    final isNurse = RoleUtils.hasRole(user, 'NURSE');

    final userName = user?['fullName']?.toString() ?? '—';
    final roleLabel = _roleLabel(
      isAdmin: isAdmin,
      isDoctor: isDoctor,
      isNurse: isNurse,
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(userName: userName, roleLabel: roleLabel),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  if (isDoctor) ...[
                    _groupCard(
                      title: 'الطبيب',
                      children: [
                        _item(
                          context,
                          icon: Icons.dashboard_rounded,
                          title: 'لوحة الأوامر',
                          subtitle: 'عرض ومتابعة أوامر الطبيب',
                          onTap: () =>
                              _go(context, const OrdersDashboardPage()),
                        ),
                        _item(
                          context,
                          icon: Icons.add_circle_outline_rounded,
                          title: 'إنشاء أمر',
                          subtitle: 'إنشاء أمر جديد بسرعة',
                          onTap: () => _go(context, const CreateOrderPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isNurse) ...[
                    _groupCard(
                      title: 'التمريض',
                      children: [
                        _item(
                          context,
                          icon: Icons.checklist_rounded,
                          title: 'مهامي',
                          subtitle: 'قائمة مهامك الحالية',
                          onTap: () => _go(context, const NurseTasksPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isAdmin) ...[
                    _groupCard(
                      title: 'الإدارة',
                      children: [
                        _item(
                          context,
                          icon: Icons.groups_2_rounded,
                          title: 'الموظفون',
                          subtitle: 'إدارة المستخدمين والصلاحيات',
                          onTap: () => _go(context, const AdminUsersPage()),
                        ),
                        _item(
                          context,
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'إضافة موظف',
                          subtitle: 'إنشاء حساب موظف جديد',
                          onTap: () =>
                              _go(context, const AdminCreateUserPage()),
                        ),

                        // ✅ NEW: Create Department
                        _item(
                          context,
                          icon: Icons.account_tree_rounded,
                          title: 'إنشاء قسم',
                          subtitle: 'إضافة قسم جديد للمنشأة',
                          onTap: () =>
                              _go(context, const AdminCreateDepartmentPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  _groupCard(
                    title: 'التطبيق',
                    children: [
                      _item(
                        context,
                        icon: Icons.settings_rounded,
                        title: 'الإعدادات',
                        subtitle: 'اللغة، المظهر، وإعدادات الحساب',
                        onTap: () => _go(context, const V2SettingsPage()),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FilledButton.icon(
                onPressed: () async {
                  // ✅ logout should work here
                  await context.read<AuthStore>().logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل خروج'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers (no logic changes) ----------

  static String _roleLabel({
    required bool isAdmin,
    required bool isDoctor,
    required bool isNurse,
  }) {
    // purely display text; it does not affect any permissions.
    if (isAdmin) return 'مدير';
    if (isDoctor) return 'طبيب';
    if (isNurse) return 'تمريض';
    return 'مستخدم';
  }

  Widget _groupCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(const Divider(height: 10));
      }
    }
    return out;
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      dense: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.primary.withAlpha(26),
            theme.colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withAlpha(45)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withAlpha(28),
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
