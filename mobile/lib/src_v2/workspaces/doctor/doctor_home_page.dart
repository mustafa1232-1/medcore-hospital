import 'package:flutter/material.dart';
import '../../core/shell/v2_shell_scaffold.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'لوحة الطبيب',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: const [
          _InfoCard(
            title: 'تنبيهات',
            subtitle: 'هنا ستظهر الأوامر المتأخرة والتصعيدات والتنبيهات.',
            icon: Icons.notifications_active_rounded,
          ),
          SizedBox(height: 12),
          _InfoCard(
            title: 'اختصار العمل',
            subtitle: 'كل العمليات داخل القائمة الجانبية (Drawer).',
            icon: Icons.menu_rounded,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
