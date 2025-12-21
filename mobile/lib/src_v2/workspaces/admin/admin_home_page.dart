import 'package:flutter/material.dart';
import '../../core/shell/v2_shell_scaffold.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'لوحة التحكم',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _card(
            context,
            title: 'تنبيهات النظام',
            subtitle:
                'هنا ستظهر تنبيهات الأقسام والمرضى والمهام المتأخرة لاحقاً.',
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'مؤشرات سريعة',
            subtitle:
                'سنربطها لاحقاً: عدد المرضى النشطين، عدد المهام، إشغال الأسرّة...',
            icon: Icons.monitor_heart_rounded,
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'الإدارة عبر القائمة',
            subtitle:
                'كل العمليات (إضافة موظف، الأقسام، المستخدمين) داخل الـ Drawer.',
            icon: Icons.menu_rounded,
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withAlpha(25),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
