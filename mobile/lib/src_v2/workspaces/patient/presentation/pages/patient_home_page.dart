// lib/src_v2/workspaces/patient/presentation/pages/patient_home_page.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';

import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_medications_page.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_facilities_page.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_profile_page.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_profile_service.dart';

class PatientHomePage extends StatefulWidget {
  final String? tenantId; // ✅ now optional

  const PatientHomePage({super.key, required this.tenantId});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await PatientProfileService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
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

  String _s(String key, {String fallback = '—'}) {
    final v = _profile?[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int? _i(String key) {
    final v = _profile?[key];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String _tenantShort(String t) {
    final x = t.trim();
    if (x.length <= 10) return x;
    return '${x.substring(0, 6)}…${x.substring(x.length - 4)}';
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientProfilePage()),
    );
    await _loadProfile();
  }

  void _openFacilities() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientFacilitiesPage()),
    );
  }

  void _openMedications() {
    final tenantId = widget.tenantId;
    if (tenantId == null || tenantId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن عرض الأدوية بدون اختيار/ربط منشأة أولاً.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientMedicationsPage(tenantId: tenantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantId = widget.tenantId;
    final hasTenant = tenantId != null && tenantId.trim().isNotEmpty;

    return V2ShellScaffold(
      title: 'بوابة المريض',
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _heroHeader(theme),
            const SizedBox(height: 12),

            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _errorBox(theme, _error!),
            ],

            if (!_loading) ...[
              _profileSummaryCard(theme),
              const SizedBox(height: 12),
            ],

            _actions(theme, hasTenant: hasTenant),
            const SizedBox(height: 12),

            _facilityCard(theme, hasTenant: hasTenant),
            const SizedBox(height: 12),

            _tipsCard(theme),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.16),
            theme.colorScheme.tertiary.withOpacity(0.10),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withOpacity(0.14),
            ),
            child: Icon(
              Icons.health_and_safety,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اطّلع على ملفك الصحي، وعدّل بيانات الطوارئ بسهولة. ربط منشأة متاح عند الحاجة.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSummaryCard(ThemeData theme) {
    final fullName = _s('fullName', fallback: 'مريض');
    final phone = _s('phone', fallback: 'غير مضاف');
    final blood = _s('bloodType', fallback: 'غير محدد');

    final height = _i('heightCm');
    final weight = _i('weightKg');

    String hw() {
      if (height == null && weight == null) return '—';
      final h = height == null ? '—' : '${height}cm';
      final w = weight == null ? '—' : '${weight}kg';
      return '$h • $w';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.18)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.person, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الهاتف: $phone',
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'فصيلة الدم: $blood • ${hw()}',
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton.icon(
            onPressed: _openProfile,
            icon: const Icon(Icons.edit),
            label: const Text('تعديل'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ThemeData theme, {required bool hasTenant}) {
    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool primary = false,
      bool disabled = false,
    }) {
      final bg = disabled
          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.35)
          : (primary
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.surface);

      final border = disabled
          ? theme.dividerColor.withOpacity(0.10)
          : (primary
                ? theme.colorScheme.primary.withOpacity(0.25)
                : theme.dividerColor.withOpacity(0.18));

      final ic = disabled
          ? theme.hintColor
          : (primary ? theme.colorScheme.primary : theme.colorScheme.onSurface);

      return InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: bg,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: ic),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: disabled ? theme.hintColor : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: theme.hintColor)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الاختصارات',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: tile(
                icon: Icons.assignment_ind_outlined,
                title: 'ملفي الشخصي',
                subtitle: 'البيانات الصحية والطوارئ والعنوان',
                onTap: _openProfile,
                primary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: tile(
                icon: Icons.medication_outlined,
                title: 'أدويتي',
                subtitle: hasTenant
                    ? 'الوصفات الحالية من المنشأة'
                    : 'يتطلب ربط/اختيار منشأة',
                onTap: _openMedications,
                disabled: !hasTenant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        tile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'ربط منشأة (Join Code / QR)',
          subtitle: 'اختياري — استخدمه عند بدء علاجك أو مراجعتك',
          onTap: _openFacilities,
        ),
        const SizedBox(height: 10),

        tile(
          icon: Icons.apartment_rounded,
          title: 'المنشآت / الحساب',
          subtitle: 'إدارة المنشآت أو تسجيل الخروج',
          onTap: _openFacilities,
        ),
      ],
    );
  }

  Widget _facilityCard(ThemeData theme, {required bool hasTenant}) {
    final tenantId = widget.tenantId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.18)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المنشأة الحالية',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          if (hasTenant) ...[
            _rowInfo('المعرّف', _tenantShort(tenantId!)),
            const SizedBox(height: 8),
            Text(
              'يمكنك تبديل المنشأة أو ربط منشأة جديدة من (المنشآت / الحساب).',
              style: TextStyle(color: theme.hintColor),
            ),
          ] else ...[
            Text(
              'غير مرتبطة بأي منشأة حالياً.',
              style: TextStyle(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا طبيعي. يمكنك إكمال ملفك الشخصي الآن، وعند الحاجة اربط منشأتك عبر Join Code / QR.',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.18)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('قريباً', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _bullet('المواعيد والزيارات'),
          _bullet('نتائج التحاليل والفحوصات'),
          _bullet('الملفات والتقارير الطبية'),
          _bullet('سجل الطبيب والإرشادات الصحية'),
          const SizedBox(height: 10),
          Text(
            'نصيحة: أكمل بيانات الطوارئ والحساسية لتكون تجربة العلاج أكثر أماناً ودقة.',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _rowInfo(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
      ),
      child: Text(
        'حدث خطأ أثناء جلب بيانات الملف الشخصي:\n$msg',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}
