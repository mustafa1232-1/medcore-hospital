import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/orders/presentation/pages/create_medication_order_page.dart';
import '../../core/shell/v2_shell_scaffold.dart';

// ✅ غيّر المسار/الاسم حسب مشروعك
class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'لوحة الطبيب',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          // ✅ Quick actions
          _QuickActionsCard(
            onCreateMedicationOrder: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateMedicationOrderPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          const _InfoCard(
            title: 'تنبيهات',
            subtitle: 'هنا ستظهر الأوامر المتأخرة والتصعيدات والتنبيهات.',
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            title: 'اختصار العمل',
            subtitle: 'كل العمليات داخل القائمة الجانبية (Drawer).',
            icon: Icons.menu_rounded,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onCreateMedicationOrder;

  const _QuickActionsCard({required this.onCreateMedicationOrder});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          FilledButton.icon(
            onPressed: onCreateMedicationOrder,
            icon: const Icon(Icons.medication_rounded),
            label: const Text('إنشاء طلب دواء'),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {
              // ممكن لاحقاً: إنشاء LAB أو PROCEDURE
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: طلب تحليل/إجراء')),
              );
            },
            icon: const Icon(Icons.science_rounded),
            label: const Text('طلب تحليل (قريباً)'),
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
