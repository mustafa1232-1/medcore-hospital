// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_profile_service.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PatientProfileService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل الملف الشخصي';
        _loading = false;
      });
    }
  }

  String _txt(String key) {
    final v = _profile?[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  List<String> _list(String key) {
    final v = _profile?[key];
    if (v is List) {
      return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'ملفي الصحي',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit),
        label: const Text('تعديل'),
        onPressed: _loading ? null : _openEdit,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) _errorBox(theme, _error!),

            if (!_loading && _profile != null) ...[
              _headerCard(theme),
              const SizedBox(height: 14),

              _section(
                theme,
                title: 'الطوارئ',
                icon: Icons.emergency,
                child: Column(
                  children: [
                    _row('هاتف الطوارئ', _txt('emergencyPhone')),
                    _row('صلة القرابة', _txt('emergencyRelation')),
                    _row('اسم الشخص', _txt('emergencyContactName')),
                  ],
                ),
              ),

              _section(
                theme,
                title: 'معلومات صحية',
                icon: Icons.favorite,
                child: Column(
                  children: [
                    _row('فصيلة الدم', _txt('bloodType')),
                    _row('الطول (سم)', _txt('heightCm')),
                    _row('الوزن (كغم)', _txt('weightKg')),
                    const SizedBox(height: 8),
                    _chips(
                      theme,
                      'الأمراض المزمنة',
                      _list('chronicConditions'),
                      empty: 'لا توجد أمراض مزمنة مسجلة',
                    ),
                    const SizedBox(height: 8),
                    _chips(
                      theme,
                      'الأدوية المزمنة',
                      _list('chronicMedications'),
                      empty: 'لا توجد أدوية مزمنة',
                    ),
                  ],
                ),
              ),

              _section(
                theme,
                title: 'العنوان',
                icon: Icons.location_on,
                child: Column(
                  children: [
                    _row('المحافظة', _txt('governorate')),
                    _row('المنطقة', _txt('area')),
                    _row('تفاصيل العنوان', _txt('addressDetails')),
                  ],
                ),
              ),

              _section(
                theme,
                title: 'الطبيب الخاص',
                icon: Icons.local_hospital,
                child: Column(
                  children: [
                    _row('الاسم', _txt('primaryDoctorName')),
                    _row('الهاتف', _txt('primaryDoctorPhone')),
                  ],
                ),
              ),

              _section(
                theme,
                title: 'معلومات النظام',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    _row('آخر تحديث', _txt('updatedAt')),
                    _row('تاريخ الإنشاء', _txt('createdAt')),
                  ],
                ),
              ),

              const SizedBox(height: 90),
            ],
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _headerCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.10),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _txt('fullName'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📞 ${_txt('phone')}',
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _chips(
    ThemeData theme,
    String title,
    List<String> items, {
    required String empty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(empty, style: TextStyle(color: theme.hintColor))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => Chip(
                    label: Text(e),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Text(msg),
    );
  }

  Future<void> _openEdit() async {
    // لاحقاً نربطه مع Edit Sheet (جاهز عندك)
  }
}
