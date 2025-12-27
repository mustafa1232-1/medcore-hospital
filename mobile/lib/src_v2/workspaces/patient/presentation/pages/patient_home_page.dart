import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_medications_page.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_facilities_page.dart';

class PatientHomePage extends StatelessWidget {
  final String tenantId;

  const PatientHomePage({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'بوابة المريض',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _card(
            theme,
            title: 'المنشأة الحالية',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tenant ID: $tenantId',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text('يمكنك تغيير المنشأة من صفحة الحساب/المنشآت.'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _card(
            theme,
            title: 'الخدمات',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.medication),
                    label: const Text('أدويتي'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PatientMedicationsPage(tenantId: tenantId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.apartment),
                    label: const Text('المنشآت / الحساب'),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        PatientFacilitiesPage.routeName,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _card(
            theme,
            title: 'قريباً',
            child: const Text(
              'سنضيف لاحقاً: المواعيد، التحاليل، الملفات، سجل الطبيب، الإرشادات الصحية بحسب القسم.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
