// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_auth_service.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_join_facility_page.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_home_page.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_login_page.dart';

class PatientFacilitiesPage extends StatefulWidget {
  static const routeName = '/patient/facilities';
  const PatientFacilitiesPage({super.key});

  @override
  State<PatientFacilitiesPage> createState() => _PatientFacilitiesPageState();
}

class _PatientFacilitiesPageState extends State<PatientFacilitiesPage> {
  // We do NOT have a memberships endpoint in your pasted backend.
  // So this page acts as "workspace launcher" + join facility.
  // If you later add GET /api/patient-join/memberships, we will load and show list here.
  final List<Map<String, dynamic>> _facilities =
      []; // local favorites (optional)

  Future<void> _openJoin() async {
    final out = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const PatientJoinFacilityPage()),
    );

    if (out == null) return;

    // store locally for UX (not server truth)
    setState(() {
      _facilities.removeWhere((x) => x['tenantId'] == out['tenantId']);
      _facilities.insert(0, out);
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PatientHomePage(tenantId: out['tenantId']),
      ),
    );
  }

  Future<void> _logout() async {
    await PatientAuthService.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      PatientLoginPage.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'حساب المريض',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _card(
            theme,
            title: 'إجراءات سريعة',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openJoin,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('ربط حسابي بمنشأة (Join Code / QR)'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل خروج'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _card(
            theme,
            title: 'منشآت أخيرة (محلياً)',
            child: _facilities.isEmpty
                ? const Text(
                    'لا توجد منشآت محفوظة محلياً بعد. استخدم زر الربط أعلاه.',
                  )
                : Column(
                    children: _facilities.map((f) {
                      final tenantId = (f['tenantId'] ?? '').toString();
                      final patientId = (f['patientId'] ?? '').toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Facility: $tenantId'),
                        subtitle: Text('Patient: $patientId'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientHomePage(tenantId: tenantId),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 12),

          _card(
            theme,
            title: 'ملاحظة',
            child: const Text(
              'هذه الصفحة لا تعتمد على endpoint memberships (غير موجود ضمن ملفاتك الحالية). '
              'إذا أضفت endpoint لاحقاً سنجلب القائمة من السيرفر ونستبدل التخزين المحلي.',
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
