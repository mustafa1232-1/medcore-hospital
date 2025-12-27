// lib/src_v2/features/patients/presentation/pages/my_assigned_patients_page.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_underscores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/patients/data/services/patients_api_service.dart';
import 'package:mobile/src_v2/features/admissions/data/services/admissions_api_service.dart';
import 'package:mobile/src_v2/features/admissions/presentation/pages/admit_patient_page.dart';
import 'package:mobile/src_v2/features/patients/presentation/pages/patient_details_page.dart';

class MyAssignedPatientsPage extends StatefulWidget {
  const MyAssignedPatientsPage({super.key});

  @override
  State<MyAssignedPatientsPage> createState() => _MyAssignedPatientsPageState();
}

class _MyAssignedPatientsPageState extends State<MyAssignedPatientsPage> {
  final _api = const PatientsApiService();
  final _admissionsApi = const AdmissionsApiService();
  final _search = TextEditingController();

  Timer? _debounce;

  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _items = [];
  final int _limit = 20;
  int _offset = 0;
  int _total = 0;
  bool _hasMore = true;

  // cache active admission per patientId
  final Map<String, String?> _activeAdmissionCache = {};

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _offset = 0;
        _total = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final res = await _api.listAssignedPatients(
        q: _search.text.trim().isEmpty ? null : _search.text.trim(),
        limit: _limit,
        offset: _offset,
      );

      final itemsRaw = (res['items'] is List)
          ? (res['items'] as List)
          : const [];
      final items = itemsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final meta = (res['meta'] is Map)
          ? Map<String, dynamic>.from(res['meta'])
          : <String, dynamic>{};
      final total = (meta['total'] is num) ? (meta['total'] as num).toInt() : 0;

      if (!mounted) return;
      setState(() {
        _total = total;
        _items.addAll(items);
        _loading = false;

        if (total > 0) {
          _hasMore = _items.length < total;
        } else {
          _hasMore = items.length == _limit;
        }
      });

      // warm cache (non-blocking)
      for (final p in items) {
        final pid = (p['id'] ?? '').toString().trim();
        if (pid.isEmpty) continue;
        if (_activeAdmissionCache.containsKey(pid)) continue;
        _fetchActiveAdmission(pid);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchActiveAdmission(String patientId) async {
    try {
      final id = await _admissionsApi.getActiveAdmissionIdForPatient(
        patientId: patientId,
      );
      if (!mounted) return;
      setState(() => _activeAdmissionCache[patientId] = id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeAdmissionCache[patientId] = null);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _activeAdmissionCache.clear();
      _load(reset: true);
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _offset += _limit;
    await _load(reset: false);
  }

  Future<void> _admitPatient(String patientId, String? patientLabel) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdmitPatientPage(patientId: patientId, patientLabel: patientLabel),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      await _fetchActiveAdmission(patientId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التنويم بنجاح')));
    }
  }

  Future<void> _openPatientDetails(String patientId, String patientName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PatientDetailsPage(patientId: patientId, patientName: patientName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('مرضاي')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'ابحث باسم المريض أو الهاتف...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _errorBox(theme, _error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _activeAdmissionCache.clear();
                await _load(reset: true);
              },
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('لا يوجد مرضى مخصصين لك حالياً'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 220) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (i >= _items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: _loading
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('تحميل المزيد'),
                                      ),
                              ),
                            );
                          }

                          final p = _items[i];
                          final id = (p['id'] ?? '').toString().trim();
                          final fullName = (p['fullName'] ?? p['name'] ?? '—')
                              .toString();
                          final phone = (p['phone'] ?? '').toString().trim();
                          final gender = (p['gender'] ?? '').toString().trim();
                          final dob = (p['dateOfBirth'] ?? '')
                              .toString()
                              .trim();

                          final cached = _activeAdmissionCache[id];
                          final hasAdmission =
                              cached != null && cached.trim().isNotEmpty;

                          // إذا ما جلبنا بعد: اعرض "Checking..." بدل ما نكذب ونقول منوّم
                          final isChecked = _activeAdmissionCache.containsKey(
                            id,
                          );
                          final statusLabel = !isChecked
                              ? '...جاري التحقق'
                              : (hasAdmission
                                    ? 'لديه Admission'
                                    : 'لا يوجد Admission');

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: id.isEmpty
                                ? null
                                : () => _openPatientDetails(id, fullName),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                  color: theme.dividerColor.withAlpha(35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primary
                                        .withAlpha(22),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _pill(
                                              theme,
                                              statusLabel,
                                              ok: hasAdmission && isChecked,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 6,
                                          children: [
                                            if (phone.isNotEmpty)
                                              _chip(
                                                theme,
                                                Icons.phone_rounded,
                                                phone,
                                              ),
                                            if (gender.isNotEmpty)
                                              _chip(
                                                theme,
                                                Icons.badge_rounded,
                                                gender,
                                              ),
                                            if (dob.isNotEmpty)
                                              _chip(
                                                theme,
                                                Icons.cake_rounded,
                                                dob,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            if (isChecked && !hasAdmission)
                                              FilledButton.icon(
                                                onPressed: id.isEmpty
                                                    ? null
                                                    : () => _admitPatient(
                                                        id,
                                                        fullName,
                                                      ),
                                                icon: const Icon(
                                                  Icons.local_hospital_rounded,
                                                ),
                                                label: const Text('تنويم'),
                                              )
                                            else if (isChecked && hasAdmission)
                                              OutlinedButton.icon(
                                                onPressed: null,
                                                icon: const Icon(
                                                  Icons.verified_rounded,
                                                ),
                                                label: const Text(
                                                  'موجود Admission',
                                                ),
                                              )
                                            else
                                              const SizedBox.shrink(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'الإجمالي: $_total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, String text, {required bool ok}) {
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

  Widget _chip(ThemeData theme, IconData icon, String text) {
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
}
