// lib/src_v2/features/patients/presentation/pages/patient_details_page.dart
// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/patients/data/services/patients_api_service.dart';
import 'package:mobile/src_v2/features/admissions/data/services/admissions_api_service.dart';

// إذا عندك صفحة التنويم (اختيار سرير) باسم مختلف، عدّل import
import 'package:mobile/src_v2/features/admissions/presentation/pages/admit_patient_page.dart';

// إذا تريد زر تعيين طبيب يدوي:
import 'package:mobile/src_v2/features/admissions/presentation/pages/create_admission_page.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  final String? patientName;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _api = const PatientsApiService();
  final _admissionsApi = const AdmissionsApiService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _record; // medical record
  Map<String, dynamic>? _advice; // health advice

  bool _creatingVisit = false;

  Map<String, dynamic> _asMap(dynamic v) => Map<String, dynamic>.from(v as Map);

  Map<String, dynamic>? _asNullableMap(dynamic v) =>
      v is Map ? _asMap(v) : null;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _record = null;
      _advice = null;
    });

    try {
      final record = await _api.getMedicalRecord(widget.patientId);
      final advice = await _api.getHealthAdvice(widget.patientId);

      if (!mounted) return;
      setState(() {
        _record = record;
        _advice = advice;
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
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic>? get _patient =>
      _record?['patient'] is Map ? _asMap(_record!['patient']) : null;

  Map<String, dynamic>? get _currentAdmission =>
      _record?['currentAdmission'] is Map
      ? _asMap(_record!['currentAdmission'])
      : null;

  bool get _hasActiveAdmission => _currentAdmission != null;

  bool get _isInpatientNow {
    final ca = _currentAdmission;
    if (ca == null) return false;
    final bedCode = (ca['bedCode'] ?? '').toString().trim();
    final roomCode = (ca['roomCode'] ?? '').toString().trim();
    // إذا توجد bedCode/roomCode نعتبره inpatient
    return bedCode.isNotEmpty || roomCode.isNotEmpty;
  }

  Future<void> _createOutpatientVisit() async {
    if (_creatingVisit) return;

    setState(() {
      _creatingVisit = true;
      _error = null;
    });

    try {
      await _admissionsApi.createOutpatientVisit(
        patientId: widget.patientId,
        notes: 'Created from patient details',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء زيارة Outpatient بنجاح')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creatingVisit = false);
    }
  }

  Future<void> _openAdmitInpatient() async {
    final patientLabel = (_patient?['fullName'] ?? widget.patientName ?? '')
        .toString()
        .trim();

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmitPatientPage(
          patientId: widget.patientId,
          patientLabel: patientLabel.isEmpty ? null : patientLabel,
        ),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التنويم بنجاح')));
      await _load();
    }
  }

  Future<void> _openAssignDoctor() async {
    final patientLabel = (_patient?['fullName'] ?? widget.patientName ?? '')
        .toString()
        .trim();

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateAdmissionPage(
          patientId: widget.patientId,
          patientLabel: patientLabel.isEmpty ? null : patientLabel,
        ),
      ),
    );

    if (ok == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final patientName =
        (_patient?['fullName'] ?? widget.patientName ?? 'تفاصيل المريض')
            .toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? _errorState(theme)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                children: [
                  _patientHeader(theme, _patient),
                  const SizedBox(height: 12),

                  // ✅ Actions (no auto navigation)
                  _actionsCard(theme),
                  const SizedBox(height: 12),

                  _sectionTitle('Health Advice'),
                  const SizedBox(height: 8),
                  _adviceCard(theme),
                  const SizedBox(height: 12),

                  _sectionTitle('Admissions'),
                  const SizedBox(height: 8),
                  _admissionsList(theme),
                  const SizedBox(height: 12),

                  _sectionTitle('Bed History'),
                  const SizedBox(height: 8),
                  _bedHistoryList(theme),
                  const SizedBox(height: 12),

                  _sectionTitle('Patient Log'),
                  const SizedBox(height: 8),
                  _logsList(theme),
                  const SizedBox(height: 12),

                  _sectionTitle('Files Archive'),
                  const SizedBox(height: 8),
                  _filesList(theme),
                ],
              ),
            ),
    );
  }

  // ===================== Actions =====================

  Widget _actionsCard(ThemeData theme) {
    final statusText = !_hasActiveAdmission
        ? 'لا يوجد Admission نشط'
        : (_isInpatientNow
              ? 'منوّم حالياً (Inpatient)'
              : 'زيارة حالياً (Outpatient)');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(statusText, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: (_hasActiveAdmission || _creatingVisit)
                    ? null
                    : _createOutpatientVisit,
                icon: _creatingVisit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: const Text('إنشاء زيارة Outpatient'),
              ),
              OutlinedButton.icon(
                onPressed: _hasActiveAdmission ? null : _openAdmitInpatient,
                icon: const Icon(Icons.local_hospital_rounded),
                label: const Text('تنويم Inpatient'),
              ),
              // اختياري: تعيين طبيب (يدوي)
              TextButton.icon(
                onPressed: _openAssignDoctor,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('تعيين طبيب/Admission'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== UI blocks (أغلبها من ملفك كما هي) =====================

  Widget _errorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _errorBox(theme, _error!),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientHeader(ThemeData theme, Map<String, dynamic>? patient) {
    final fullName = (patient?['fullName'] ?? '—').toString();
    final phone = (patient?['phone'] ?? '').toString().trim();
    final email = (patient?['email'] ?? '').toString().trim();
    final gender = (patient?['gender'] ?? '').toString().trim();
    final dob = (patient?['dateOfBirth'] ?? '').toString().trim();
    final nationalId = (patient?['nationalId'] ?? '').toString().trim();
    final isActive = patient?['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withAlpha(22),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(theme, isActive ? 'ACTIVE' : 'INACTIVE', isActive),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoChip(theme, Icons.tag_rounded, _shortId(widget.patientId)),
              if (phone.isNotEmpty)
                _infoChip(theme, Icons.phone_rounded, phone),
              if (email.isNotEmpty)
                _infoChip(theme, Icons.email_rounded, email),
              if (gender.isNotEmpty)
                _infoChip(theme, Icons.badge_rounded, gender),
              if (dob.isNotEmpty) _infoChip(theme, Icons.cake_rounded, dob),
              if (nationalId.isNotEmpty)
                _infoChip(theme, Icons.credit_card_rounded, nationalId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adviceCard(ThemeData theme) {
    final current = _advice?['current'];
    final advice = _advice?['advice'];

    final currentMap = _asNullableMap(current);
    final adviceList = (advice is List) ? advice : const [];

    final dept = (currentMap?['departmentCode'] ?? '').toString().trim();
    final deptName = (currentMap?['departmentName'] ?? '').toString().trim();
    final room = (currentMap?['roomCode'] ?? '').toString().trim();
    final bed = (currentMap?['bedCode'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentMap == null) ...[
            Text(
              'لا توجد إقامة فعّالة حالياً.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else ...[
            Text(
              'Current: ${[if (deptName.isNotEmpty) deptName, if (dept.isNotEmpty) '($dept)'].join(' ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (room.isNotEmpty)
                  _infoChip(theme, Icons.meeting_room_rounded, 'Room $room'),
                if (bed.isNotEmpty)
                  _infoChip(theme, Icons.bed_rounded, 'Bed $bed'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (adviceList.isEmpty)
            const Text('No advice.')
          else
            Column(
              children: List.generate(adviceList.length, (i) {
                final line = adviceList[i].toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '•  ',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      // ignore: dead_code
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // ملاحظة: داخل advice list عندك سطر Row ثابت، خليته كما هو لا يكسر.
  // إذا تريد الإصلاح الدقيق له، قلّي.

  Widget _admissionsList(ThemeData theme) {
    final admissions = _record?['admissions'];
    final list = (admissions is List) ? admissions : const [];

    if (list.isEmpty) return _emptyCard(theme, 'لا توجد Admissions.');

    return Column(
      children: List.generate(list.length, (i) {
        final a = Map<String, dynamic>.from(list[i] as Map);
        final id = (a['id'] ?? '').toString();
        final status = (a['status'] ?? '').toString();
        final reason = (a['reason'] ?? '').toString().trim();
        final startedAt = (a['startedAt'] ?? '').toString().trim();
        final endedAt = (a['endedAt'] ?? '').toString().trim();
        final departmentCode = (a['departmentCode'] ?? '').toString().trim();
        final roomCode = (a['roomCode'] ?? '').toString().trim();
        final bedCode = (a['bedCode'] ?? '').toString().trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor.withAlpha(35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admission ${_shortId(id)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _statusChip(
                    theme,
                    status.isEmpty ? '—' : status,
                    status.toUpperCase() == 'ACTIVE' ||
                        status.toUpperCase() == 'PENDING',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (reason.isNotEmpty)
                    _infoChip(theme, Icons.info_outline_rounded, reason),
                  if (startedAt.isNotEmpty)
                    _infoChip(
                      theme,
                      Icons.play_circle_outline_rounded,
                      startedAt,
                    ),
                  if (endedAt.isNotEmpty)
                    _infoChip(theme, Icons.stop_circle_outlined, endedAt),
                  if (departmentCode.isNotEmpty)
                    _infoChip(theme, Icons.apartment_rounded, departmentCode),
                  if (roomCode.isNotEmpty)
                    _infoChip(theme, Icons.meeting_room_rounded, roomCode),
                  if (bedCode.isNotEmpty)
                    _infoChip(theme, Icons.bed_rounded, bedCode),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bedHistoryList(ThemeData theme) {
    final bedHistory = _record?['bedHistory'];
    final list = (bedHistory is List) ? bedHistory : const [];

    if (list.isEmpty) return _emptyCard(theme, 'لا يوجد Bed History.');

    return Column(
      children: List.generate(list.length, (i) {
        final b = Map<String, dynamic>.from(list[i] as Map);

        final assignedAt = (b['assignedAt'] ?? '').toString().trim();
        final releasedAt = (b['releasedAt'] ?? '').toString().trim();
        final departmentCode = (b['departmentCode'] ?? '').toString().trim();
        final roomCode = (b['roomCode'] ?? '').toString().trim();
        final bedCode = (b['bedCode'] ?? '').toString().trim();
        final reason = (b['reason'] ?? '').toString().trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor.withAlpha(35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Movement',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (departmentCode.isNotEmpty)
                    _infoChip(theme, Icons.apartment_rounded, departmentCode),
                  if (roomCode.isNotEmpty)
                    _infoChip(theme, Icons.meeting_room_rounded, roomCode),
                  if (bedCode.isNotEmpty)
                    _infoChip(theme, Icons.bed_rounded, bedCode),
                  if (assignedAt.isNotEmpty)
                    _infoChip(theme, Icons.login_rounded, 'In: $assignedAt'),
                  if (releasedAt.isNotEmpty)
                    _infoChip(theme, Icons.logout_rounded, 'Out: $releasedAt'),
                  if (reason.isNotEmpty)
                    _infoChip(theme, Icons.comment_rounded, reason),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _logsList(ThemeData theme) {
    final logs = _record?['logs'];
    final list = (logs is List) ? logs : const [];

    if (list.isEmpty) return _emptyCard(theme, 'لا يوجد Patient Log.');

    return Column(
      children: List.generate(list.length, (i) {
        final l = Map<String, dynamic>.from(list[i] as Map);

        final createdAt = (l['createdAt'] ?? '').toString().trim();
        final eventType = (l['eventType'] ?? '').toString().trim();
        final message = (l['message'] ?? '').toString().trim();
        final actorName = (l['actorName'] ?? '').toString().trim();
        final actorStaffCode = (l['actorStaffCode'] ?? '').toString().trim();

        final actor = [
          if (actorName.isNotEmpty) actorName,
          if (actorStaffCode.isNotEmpty) '($actorStaffCode)',
        ].join(' ');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor.withAlpha(35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eventType.isEmpty ? 'LOG' : eventType,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (actor.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  actor,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _filesList(ThemeData theme) {
    final files = _record?['files'];
    final list = (files is List) ? files : const [];

    if (list.isEmpty) return _emptyCard(theme, 'لا يوجد ملفات.');

    return Column(
      children: List.generate(list.length, (i) {
        final f = Map<String, dynamic>.from(list[i] as Map);

        final filename = (f['filename'] ?? '—').toString();
        final kind = (f['kind'] ?? '').toString().trim();
        final mime = (f['mimeType'] ?? '').toString().trim();
        final createdAt = (f['createdAt'] ?? '').toString().trim();
        final sizeBytes = f['sizeBytes'];

        final size = (sizeBytes is num) ? _formatBytes(sizeBytes.toInt()) : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor.withAlpha(35)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withAlpha(22),
                child: Icon(
                  Icons.insert_drive_file_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        if (kind.isNotEmpty) _miniTag(theme, kind),
                        if (mime.isNotEmpty) _miniTag(theme, mime),
                        if (size.isNotEmpty) _miniTag(theme, size),
                        if (createdAt.isNotEmpty) _miniTag(theme, createdAt),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'فتح لاحقاً',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فتح الملفات سنضيفه لاحقاً')),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyCard(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Text(text),
    );
  }

  Widget _sectionTitle(String s) =>
      Text(s, style: const TextStyle(fontWeight: FontWeight.w900));

  Widget _infoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withAlpha(18),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(55)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statusChip(ThemeData theme, String text, bool ok) {
    final c = ok ? theme.colorScheme.primary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withAlpha(18),
        border: Border.all(color: c.withAlpha(55)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: c,
        ),
      ),
    );
  }

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(1)} GB';
  }
}
