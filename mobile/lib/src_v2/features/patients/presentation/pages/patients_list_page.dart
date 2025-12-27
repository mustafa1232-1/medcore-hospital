// lib/src_v2/features/patients/presentation/pages/patients_list_page.dart

// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/patients/data/services/patients_api_service.dart';

import 'create_patient_page.dart';
import 'patient_details_page.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  final _api = PatientsApiService();

  final _q = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _items = [];
  int _limit = 20;
  int _offset = 0;
  int _total = 0;

  bool _isActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
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
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final res = await _api.listPatients(
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        isActive: _isActiveOnly ? true : null,
        limit: _limit,
        offset: _offset,
      );

      // backend returns {items:[...], meta:{total,limit,offset}}
      final itemsRaw = res['items'];
      final metaRaw = res['meta'];

      final List<Map<String, dynamic>> items = (itemsRaw is List)
          ? itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      final meta = (metaRaw is Map) ? Map<String, dynamic>.from(metaRaw) : {};
      final total = (meta['total'] is num)
          ? (meta['total'] as num).toInt()
          : items.length;

      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _total = total;
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

  bool get _canLoadMore => _items.length < _total && !_loading;

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _load(reset: true);
    });
  }

  Future<void> _openCreate() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePatientPage()));

    if (!mounted) return;
    if (ok == true) {
      _load(reset: true);
    }
  }

  void _openDetails(Map<String, dynamic> p) {
    final id = (p['id'] ?? '').toString();
    if (id.isEmpty) return;

    final name = (p['fullName'] ?? '').toString();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailsPage(
          patientId: id,
          patientName: name.isEmpty ? null : name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المرضى'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () => _load(reset: true),
          ),
          IconButton(
            tooltip: 'إنشاء مريض',
            icon: const Icon(Icons.person_add_alt_rounded),
            onPressed: _openCreate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('إنشاء مريض'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _searchBar(theme),
            const SizedBox(height: 10),
            _filtersRow(theme),
            const SizedBox(height: 10),

            if (_error != null) ...[
              _errorBox(theme, _error!),
              const SizedBox(height: 10),
            ],

            _summary(theme),
            const SizedBox(height: 10),

            if (_items.isEmpty && !_loading && _error == null)
              _emptyCard(theme, 'لا يوجد نتائج.')
            else
              ..._items.map((p) => _patientTile(theme, p)),

            const SizedBox(height: 10),

            if (_loading) ...[
              const SizedBox(height: 6),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 6),
            ] else if (_canLoadMore) ...[
              FilledButton.icon(
                onPressed: () {
                  _offset += _limit;
                  _load(reset: false);
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('تحميل المزيد'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _searchBar(ThemeData theme) {
    return TextField(
      controller: _q,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'بحث بالاسم أو الهاتف...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _filtersRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            value: _isActiveOnly,
            onChanged: (v) {
              setState(() => _isActiveOnly = v);
              _load(reset: true);
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Active فقط'),
            subtitle: const Text('isActive=true'),
          ),
        ),
      ],
    );
  }

  Widget _summary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'المعروض: ${_items.length} من ${_total == 0 ? '—' : _total}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            'limit=$_limit',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientTile(ThemeData theme, Map<String, dynamic> p) {
    final id = (p['id'] ?? '').toString();
    final name = (p['fullName'] ?? '—').toString();
    final phone = (p['phone'] ?? '').toString().trim();
    final gender = (p['gender'] ?? '').toString().trim();
    final dob = (p['dateOfBirth'] ?? '').toString().trim();
    final isActive = p['isActive'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withAlpha(35)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary.withAlpha(22),
          child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _miniTag(theme, _shortId(id)),
              if (phone.isNotEmpty) _miniTag(theme, phone),
              if (gender.isNotEmpty) _miniTag(theme, gender),
              if (dob.isNotEmpty) _miniTag(theme, dob),
              _miniStatus(theme, isActive ? 'ACTIVE' : 'INACTIVE', isActive),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openDetails(p),
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

  Widget _miniStatus(ThemeData theme, String text, bool ok) {
    final c = ok ? theme.colorScheme.primary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withAlpha(16),
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
}
