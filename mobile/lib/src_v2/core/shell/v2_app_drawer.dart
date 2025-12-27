// lib/src_v2/core/shell/v2_app_drawer.dart
import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/patients/presentation/pages/create_patient_page.dart';
import 'package:mobile/src_v2/features/patients/presentation/pages/my_assigned_patients_page.dart';
import 'package:mobile/src_v2/features/patients/presentation/pages/patients_list_page.dart';
import 'package:provider/provider.dart';

import '../auth/auth_store.dart';
import '../rbac/role_utils.dart';

// Doctor pages
import '../../features/orders/presentation/pages/orders_dashboard_page.dart';
import '../../features/orders/presentation/pages/create_medication_order_page.dart';

// ✅ Doctor assigned patients page (NEW)

// Nurse pages
import '../../workspaces/nurse/nurse_tasks_page.dart';

// Reception pages
// Settings
import '../../core/settings/v2_settings_page.dart';

// Admin staff pages
import '../../features/admin_staff/presentation/pages/admin_users_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_user_page.dart';
import '../../features/admin_staff/presentation/pages/admin_departments_page.dart';
import '../../features/admin_staff/presentation/pages/admin_create_department_page.dart';

// ✅ Admin pharmacy approvals page (NEW)
import '../../features/admin_staff/presentation/pages/admin_stock_requests_page.dart';

// Pharmacy workspace pages (PHARMACY only)
import '../../workspaces/pharmacy/presentation/pages/pharmacy_inventory_page.dart';
import '../../workspaces/pharmacy/presentation/pages/pharmacy_stock_requests_page.dart';
import '../../workspaces/pharmacy/presentation/pages/pharmacy_stock_moves_page.dart';

class V2AppDrawer extends StatelessWidget {
  const V2AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;

    final isAdmin = RoleUtils.hasRole(user, 'ADMIN');
    final isDoctor = RoleUtils.hasRole(user, 'DOCTOR');
    final isNurse = RoleUtils.hasRole(user, 'NURSE');
    final isPharmacy = RoleUtils.hasRole(user, 'PHARMACY');
    final isReception = RoleUtils.hasRole(user, 'RECEPTION');

    final fullName = user?['fullName']?.toString().trim();
    final userName = (fullName == null || fullName.isEmpty) ? '—' : fullName;

    final rolesRaw = (user?['roles'] is List)
        ? (user?['roles'] as List)
        : const [];
    final rolesUpper = rolesRaw
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();

    final roleLabel = _roleLabel(rolesUpper);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(userName: userName, roleLabel: roleLabel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                children: [
                  // =====================
                  // DOCTOR
                  // =====================
                  if (isDoctor) ...[
                    _SectionCard(
                      title: 'الطبيب',
                      icon: Icons.health_and_safety_rounded,
                      children: [
                        _Item(
                          icon: Icons.dashboard_rounded,
                          title: 'لوحة الأوامر',
                          onTap: () =>
                              _go(context, const OrdersDashboardPage()),
                        ),
                        _Item(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'إنشاء طلب دواء',
                          onTap: () =>
                              _go(context, const CreateMedicationOrderPage()),
                        ),
                        // ✅ NEW: Doctor sees only assigned patients
                        _Item(
                          icon: Icons.people_alt_rounded,
                          title: 'مرضاي',
                          onTap: () =>
                              _go(context, const MyAssignedPatientsPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // =====================
                  // RECEPTION (and ADMIN)
                  // =====================
                  if (isReception || isAdmin) ...[
                    _SectionCard(
                      title: 'الاستقبال',
                      icon: Icons.how_to_reg_rounded,
                      children: [
                        _Item(
                          icon: Icons.people_alt_rounded,
                          title: 'المرضى',
                          onTap: () => _go(context, const PatientsListPage()),
                        ),
                        _Item(
                          icon: Icons.person_add_alt_rounded,
                          title: 'إنشاء مريض',
                          onTap: () => _go(context, const CreatePatientPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // =====================
                  // NURSE
                  // =====================
                  if (isNurse) ...[
                    _SectionCard(
                      title: 'التمريض',
                      icon: Icons.medical_services_rounded,
                      children: [
                        _Item(
                          icon: Icons.checklist_rounded,
                          title: 'مهامي',
                          onTap: () => _go(context, const NurseTasksPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // =====================
                  // PHARMACY
                  // =====================
                  if (isPharmacy) ...[
                    _SectionCard(
                      title: 'الصيدلية',
                      icon: Icons.local_pharmacy_rounded,
                      children: [
                        _Item(
                          icon: Icons.inventory_2_rounded,
                          title: 'المخزون',
                          onTap: () =>
                              _go(context, const PharmacyInventoryPage()),
                        ),
                        _Item(
                          icon: Icons.assignment_rounded,
                          title: 'طلبات المخزون',
                          onTap: () =>
                              _go(context, const PharmacyStockRequestsPage()),
                        ),
                        _Item(
                          icon: Icons.swap_horiz_rounded,
                          title: 'حركات المخزون',
                          onTap: () =>
                              _go(context, const PharmacyStockMovesPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // =====================
                  // ADMIN
                  // =====================
                  if (isAdmin) ...[
                    _SectionCard(
                      title: 'الإدارة',
                      icon: Icons.admin_panel_settings_rounded,
                      children: [
                        _Item(
                          icon: Icons.groups_2_rounded,
                          title: 'الموظفون',
                          onTap: () => _go(context, const AdminUsersPage()),
                        ),
                        _Item(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'إضافة موظف',
                          onTap: () =>
                              _go(context, const AdminCreateUserPage()),
                        ),
                        _Item(
                          icon: Icons.apartment_rounded,
                          title: 'الأقسام',
                          onTap: () =>
                              _go(context, const AdminDepartmentsPage()),
                        ),
                        _Item(
                          icon: Icons.add_business_rounded,
                          title: 'إضافة قسم',
                          onTap: () =>
                              _go(context, const AdminCreateDepartmentPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'موافقات الصيدلية',
                      icon: Icons.fact_check_rounded,
                      children: [
                        _Item(
                          icon: Icons.assignment_turned_in_rounded,
                          title: 'طلبات المخزون (موافقة/رفض)',
                          onTap: () =>
                              _go(context, const AdminStockRequestsPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // =====================
                  // APP
                  // =====================
                  _SectionCard(
                    title: 'التطبيق',
                    icon: Icons.local_hospital_rounded,
                    children: [
                      _Item(
                        icon: Icons.settings_rounded,
                        title: 'الإعدادات',
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
                  Navigator.pop(context);
                  await context.read<AuthStore>().logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل خروج'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
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

  static String _roleLabel(List<String> rolesUpper) {
    if (rolesUpper.contains('ADMIN')) return 'Admin';
    if (rolesUpper.contains('DOCTOR')) return 'Doctor';
    if (rolesUpper.contains('NURSE')) return 'Nurse';
    if (rolesUpper.contains('LAB')) return 'Lab';
    if (rolesUpper.contains('PHARMACY')) return 'Pharmacy';
    if (rolesUpper.contains('RECEPTION')) return 'Reception';
    return '';
  }

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

// ===== UI widgets below remain the same (no logic change) =====

class _Header extends StatelessWidget {
  final String userName;
  final String roleLabel;

  const _Header({required this.userName, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(220),
                  theme.colorScheme.tertiary.withAlpha(180),
                ],
              ),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
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
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withAlpha(22),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withAlpha(22),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Item({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: Icon(icon, color: theme.colorScheme.onSurface.withAlpha(220)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
