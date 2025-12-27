// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_medications_service.dart';

class PatientMedicationsPage extends StatefulWidget {
  final String tenantId;
  const PatientMedicationsPage({super.key, required this.tenantId});

  @override
  State<PatientMedicationsPage> createState() => _PatientMedicationsPageState();
}

class _PatientMedicationsPageState extends State<PatientMedicationsPage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await PatientMedicationsService.listMyMedications(
        tenantId: widget.tenantId,
        limit: 50,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'أدويتي',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            if (_error != null) _errorBox(theme, _error!),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading && _items.isEmpty)
              _card(
                theme,
                title: 'لا توجد أدوية',
                child: const Text('لم يتم تسجيل طلبات أدوية بعد.'),
              ),

            ..._items.map((m) {
              final med = (m['medicationName'] ?? '—').toString();
              final dose = (m['dose'] ?? '—').toString();
              final freq = (m['frequency'] ?? '—').toString();
              final route = (m['route'] ?? '—').toString();
              final createdAt = (m['createdAt'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _card(
                  theme,
                  title: med,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dose: $dose | Route: $route | Frequency: $freq'),
                      if (createdAt.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Created: $createdAt',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientMedicationDetailsPage(item: m),
                                ),
                              ),
                              child: const Text('تفاصيل'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
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

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }
}

class PatientMedicationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const PatientMedicationDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String v(String key) {
      final x = item[key];
      if (x == null) return '—';
      final s = x.toString().trim();
      return s.isEmpty ? '—' : s;
    }

    return V2ShellScaffold(
      title: 'تفاصيل الدواء',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _card(theme, title: 'الدواء', child: Text(v('medicationName'))),
          const SizedBox(height: 10),
          _card(
            theme,
            title: 'الجرعة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dose: ${v('dose')}'),
                Text('Route: ${v('route')}'),
                Text('Frequency: ${v('frequency')}'),
                Text('Duration: ${v('duration')}'),
                const SizedBox(height: 8),
                Text('With food: ${v('withFood')}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _card(
            theme,
            title: 'تعليمات',
            child: Text(v('patientInstructionsAr')),
          ),
          const SizedBox(height: 10),
          _card(theme, title: 'تحذيرات', child: Text(v('warningsText'))),
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
