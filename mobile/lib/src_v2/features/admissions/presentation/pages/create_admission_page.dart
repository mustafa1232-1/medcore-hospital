// lib/src_v2/features/admissions/presentation/pages/create_admission_page.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_underscores

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../admissions/data/services/admissions_api_service.dart';
import '../../../../core/api/api_client.dart';

class CreateAdmissionPage extends StatefulWidget {
  final String patientId;
  final String? patientLabel;

  const CreateAdmissionPage({
    super.key,
    required this.patientId,
    this.patientLabel,
  });

  @override
  State<CreateAdmissionPage> createState() => _CreateAdmissionPageState();
}

class _CreateAdmissionPageState extends State<CreateAdmissionPage> {
  final _admissionsApi = const AdmissionsApiService();
  final Dio _dio = ApiClient.dio;

  bool _saving = false;
  String? _error;

  // Department
  String? _departmentId;
  String? _departmentLabel;

  // Doctor
  String? _doctorId;
  String? _doctorLabel;

  // ✅ Date picker (instead of writing)
  DateTime? _visitDate;
  String? _visitDateLabel;

  final _reason = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pLabel = (widget.patientLabel ?? '').trim().isEmpty
        ? widget.patientId
        : widget.patientLabel!.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('فتح Admission للمريض')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _kvCard('المريض', pLabel),
          const SizedBox(height: 10),

          if (_error != null) ...[
            _errorBox(theme, _error!),
            const SizedBox(height: 10),
          ],

          _sectionTitle('تعيين (Reception)'),
          const SizedBox(height: 8),

          // ✅ Visit date picker
          _pickerTile(
            label: 'تاريخ الزيارة (اختياري)',
            value: _visitDateLabel,
            onPick: _pickVisitDate,
          ),
          const SizedBox(height: 10),

          // Department picker
          _pickerTile(
            label: 'القسم (اختياري)',
            value: _departmentLabel,
            onPick: () async {
              final picked = await _pickFromLookup(
                title: 'اختيار القسم',
                searchHint: 'ابحث باسم/كود القسم...',
                loader: (q) => _lookupDepartments(q: q),
              );
              if (picked == null) return;

              setState(() {
                _departmentId = (picked['id'] ?? '').toString();
                _departmentLabel = _labelOfPicked(picked);

                // ✅ reset doctor if department changed
                _doctorId = null;
                _doctorLabel = null;
              });
            },
          ),
          const SizedBox(height: 10),

          // ✅ Doctor picker (uses /api/lookups/staff?role=DOCTOR&departmentId=)
          _pickerTile(
            label: 'الطبيب (مهم)',
            value: _doctorLabel,
            onPick: () async {
              // UX: if no department selected, still allow search (no filter)
              final picked = await _pickFromLookup(
                title: 'اختيار الطبيب',
                searchHint: 'ابحث باسم الطبيب...',
                loader: (q) =>
                    _lookupDoctors(q: q, departmentId: _departmentId),
              );
              if (picked == null) return;

              setState(() {
                _doctorId = (picked['id'] ?? '').toString();
                _doctorLabel = _labelOfPicked(picked);

                // If API returns department info, you can auto-fill department later.
              });
            },
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          _text(
            controller: _reason,
            label: 'سبب الزيارة (اختياري)',
            hint: 'Chief complaint / reason',
          ),
          const SizedBox(height: 10),

          _multiline(
            controller: _notes,
            label: 'ملاحظات (اختياري)',
            hint: 'أي تفاصيل للاستقبال/الطبيب...',
            minLines: 3,
            maxLines: 6,
          ),

          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_saving ? 'جاري الحفظ...' : 'فتح Admission'),
          ),

          const SizedBox(height: 10),
          _hintBox(
            'ملاحظة: حالياً جدول admissions لا يحتوي departmentId ولا visitDate، لذلك حفظ القسم/التاريخ سيكون داخل notes كتاغات. '
            'لاحقاً نضيف migration صغيرة وندعمها رسميًا بالـ API.',
          ),
        ],
      ),
    );
  }

  Future<void> _pickVisitDate() async {
    final now = DateTime.now();
    final initial = _visitDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      helpText: 'اختيار تاريخ الزيارة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (picked == null) return;

    setState(() {
      _visitDate = picked;
      _visitDateLabel = _fmtDate(picked); // yyyy-mm-dd
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    // doctor is required (UI policy)
    if ((_doctorId ?? '').trim().isEmpty) {
      setState(() {
        _saving = false;
        _error = 'الرجاء اختيار الطبيب.';
      });
      return;
    }

    // ✅ add tags to notes (temporary until DB fields exist)
    final tags = <String>[];

    if ((_departmentLabel ?? '').trim().isNotEmpty) {
      tags.add('[DEPT:${_departmentLabel!.trim()}]');
    }
    if (_visitDate != null) {
      tags.add('[VISIT:${_fmtDate(_visitDate!)}]');
    }

    final notesText = _notes.text.trim();
    final baseNotes = notesText.isEmpty ? null : notesText;

    final tagString = tags.join(' ');
    String? mergedNotes;

    if ((baseNotes == null || baseNotes.isEmpty) && tagString.isEmpty) {
      mergedNotes = null;
    } else if (baseNotes == null || baseNotes.isEmpty) {
      mergedNotes = tagString;
    } else if (tagString.isEmpty) {
      mergedNotes = baseNotes;
    } else {
      // avoid duplicate tags if user edits
      mergedNotes = baseNotes;
      for (final t in tags) {
        if (!mergedNotes!.contains(t)) mergedNotes = '${mergedNotes!} $t';
      }
      mergedNotes = mergedNotes!.trim();
    }

    try {
      await _admissionsApi.createAdmission(
        patientId: widget.patientId,
        assignedDoctorUserId: _doctorId,
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        notes: mergedNotes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم فتح Admission بنجاح')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------
  // Lookups
  // ---------------------------

  Future<List<Map<String, dynamic>>> _lookupDepartments({
    required String q,
  }) async {
    final Response res = await _dio.get(
      '/api/lookups/departments',
      queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim(), 'limit': 50},
    );

    final data = res.data;

    // Backend shape: { ok: true, items: [...] }
    final items = (data is Map && data['items'] is List)
        ? (data['items'] as List)
        : (data is List ? data : const []);

    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> _lookupDoctors({
    required String q,
    String? departmentId,
  }) async {
    final Response res = await _dio.get(
      '/api/lookups/staff',
      queryParameters: {
        'role': 'DOCTOR',
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (departmentId != null && departmentId.trim().isNotEmpty)
          'departmentId': departmentId.trim(),
        'limit': 50,
      },
    );

    final data = res.data;

    // Backend shape: { ok: true, items: [...] }
    final items = (data is Map && data['items'] is List)
        ? (data['items'] as List)
        : (data is List ? data : const []);

    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---------------- UI helpers ----------------

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Widget _sectionTitle(String s) =>
      Text(s, style: const TextStyle(fontWeight: FontWeight.w900));

  Widget _kvCard(String k, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(v),
        ],
      ),
    );
  }

  Widget _hintBox(String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withAlpha(50)),
        color: theme.colorScheme.surface,
      ),
      child: Text(msg),
    );
  }

  Widget _text({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _multiline({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 2,
    int maxLines = 5,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _pickerTile({
    required String label,
    required String? value,
    required VoidCallback onPick,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: Theme.of(context).colorScheme.surface,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text((value ?? '').isEmpty ? '-' : value!),
      trailing: const Icon(Icons.search_rounded),
      onTap: onPick,
    );
  }

  String _labelOfPicked(Map<String, dynamic> it) {
    final label = (it['label'] ?? '').toString().trim();
    if (label.isNotEmpty) return label;

    final name = (it['name'] ?? it['fullName'] ?? it['code'] ?? '')
        .toString()
        .trim();
    final code = (it['code'] ?? '').toString().trim();
    return [
      name,
      if (code.isNotEmpty && !name.contains(code)) '($code)',
    ].where((x) => x.trim().isNotEmpty).join(' ');
  }

  Future<Map<String, dynamic>?> _pickFromLookup({
    required String title,
    required String searchHint,
    required Future<List<Map<String, dynamic>>> Function(String q) loader,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _LookupSheet(title: title, searchHint: searchHint, loader: loader),
    );
  }
}

class _LookupSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<Map<String, dynamic>>> Function(String q) loader;

  const _LookupSheet({
    required this.title,
    required this.searchHint,
    required this.loader,
  });

  @override
  State<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<_LookupSheet> {
  final _c = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.loader(q.trim());
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

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _load(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          top: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _load,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: widget.searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                  ? Center(child: Text(_error!, textAlign: TextAlign.center))
                  : (_items.isEmpty)
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        final label =
                            (it['label'] ??
                                    it['name'] ??
                                    it['fullName'] ??
                                    it['code'] ??
                                    '')
                                .toString();

                        final sub = (it['sub'] ?? '').toString().trim();

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: theme.colorScheme.surface,
                          title: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(it),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
