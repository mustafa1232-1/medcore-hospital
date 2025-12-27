// lib/src_v2/features/admissions/presentation/pages/admit_patient_page.dart
// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';

import '../../../admissions/data/services/admissions_api_service.dart';
import '../../../../core/api/api_client.dart';

class AdmitPatientPage extends StatefulWidget {
  final String patientId;
  final String? patientLabel;

  const AdmitPatientPage({
    super.key,
    required this.patientId,
    this.patientLabel,
  });

  @override
  State<AdmitPatientPage> createState() => _AdmitPatientPageState();
}

class _AdmitPatientPageState extends State<AdmitPatientPage> {
  final _admissionsApi = const AdmissionsApiService();
  final _lookup = const _FacilityLookupApi();

  bool _loading = false;
  String? _error;

  String? _departmentId;
  String? _roomId;
  String? _bedId;

  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _rooms = const [];
  List<Map<String, dynamic>> _beds = const [];

  final _reason = TextEditingController(text: 'Inpatient admission');
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _lookup.listDepartments();
      if (!mounted) return;
      setState(() {
        _departments = items;
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

  Future<void> _loadRooms(String departmentId) async {
    setState(() {
      _loading = true;
      _error = null;
      _rooms = const [];
      _beds = const [];
      _roomId = null;
      _bedId = null;
    });
    try {
      final items = await _lookup.listRooms(departmentId: departmentId);
      if (!mounted) return;
      setState(() {
        _rooms = items;
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

  Future<void> _loadBeds(String roomId) async {
    setState(() {
      _loading = true;
      _error = null;
      _beds = const [];
      _bedId = null;
    });
    try {
      final items = await _lookup.listAvailableBeds(roomId: roomId);
      if (!mounted) return;
      setState(() {
        _beds = items;
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

  String _extractAdmissionId(dynamic createAdmissionResponse) {
    // Accept String, {id}, {admissionId}, {data:{id}}, {data:{admissionId}}
    if (createAdmissionResponse is String)
      return createAdmissionResponse.trim();

    if (createAdmissionResponse is Map) {
      final m = Map<String, dynamic>.from(createAdmissionResponse);
      if (m['data'] is Map) {
        final d = Map<String, dynamic>.from(m['data']);
        final v = (d['id'] ?? d['admissionId'] ?? '').toString().trim();
        if (v.isNotEmpty && v != 'null') return v;
      }
      final v = (m['id'] ?? m['admissionId'] ?? '').toString().trim();
      if (v.isNotEmpty && v != 'null') return v;
    }

    return '';
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_departmentId == null) {
      setState(() => _error = 'اختر القسم أولاً.');
      return;
    }
    if (_roomId == null) {
      setState(() => _error = 'اختر الغرفة أولاً.');
      return;
    }
    if (_bedId == null) {
      setState(() => _error = 'اختر سريراً متاحاً أولاً.');
      return;
    }

    setState(() => _loading = true);

    try {
      final active = await _admissionsApi.getActiveAdmissionIdForPatient(
        patientId: widget.patientId,
      );
      if (active != null) {
        setState(() {
          _loading = false;
          _error = 'هذا المريض لديه Admission نشط بالفعل.';
        });
        return;
      }

      // 1) create admission (doctor is now allowed in backend)
      final createRes = await _admissionsApi.createAdmission(
        patientId: widget.patientId,
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      final admissionId = _extractAdmissionId(createRes);
      if (admissionId.isEmpty) {
        throw Exception('Backend did not return admission id');
      }

      // 2) assign bed
      await _admissionsApi.assignBed(admissionId: admissionId, bedId: _bedId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنويم المريض وتعيين السرير بنجاح')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تنويم مريض')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if ((widget.patientLabel ?? '').trim().isNotEmpty)
            Text(
              'المريض: ${widget.patientLabel}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          const SizedBox(height: 10),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.error.withAlpha(90),
                ),
              ),
              child: Text(_error!),
            ),
            const SizedBox(height: 10),
          ],
          _dropdownCard(
            label: 'القسم',
            value: _departmentId,
            items: _departments,
            getId: (m) => (m['id'] ?? '').toString(),
            getLabel: (m) => _bestLabel(m, ['code', 'name', 'label']),
            onChanged: _loading
                ? null
                : (v) {
                    setState(() => _departmentId = v);
                    if (v != null) _loadRooms(v);
                  },
          ),
          const SizedBox(height: 10),
          _dropdownCard(
            label: 'الغرفة',
            value: _roomId,
            items: _rooms,
            getId: (m) => (m['id'] ?? '').toString(),
            getLabel: (m) => _bestLabel(m, ['code', 'name', 'label']),
            onChanged: (_loading || _rooms.isEmpty)
                ? null
                : (v) {
                    setState(() => _roomId = v);
                    if (v != null) _loadBeds(v);
                  },
          ),
          const SizedBox(height: 10),
          _dropdownCard(
            label: 'السرير (متاح)',
            value: _bedId,
            items: _beds,
            getId: (m) => (m['id'] ?? '').toString(),
            getLabel: (m) => _bestLabel(m, ['code', 'bedCode', 'label']),
            onChanged: (_loading || _beds.isEmpty)
                ? null
                : (v) => setState(() => _bedId = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            decoration: InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_loading ? 'جاري التنفيذ...' : 'تأكيد التنويم'),
          ),
        ],
      ),
    );
  }

  Widget _dropdownCard({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) getId,
    required String Function(Map<String, dynamic>) getLabel,
    required ValueChanged<String?>? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (m) => DropdownMenuItem<String>(
                  value: getId(m),
                  child: Text(getLabel(m)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _bestLabel(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return (m['id'] ?? '').toString();
  }
}

class _FacilityLookupApi {
  const _FacilityLookupApi();

  // ✅ new canonical paths
  static const String _departmentsPath = '/api/lookups/departments';
  static const String _roomsPath = '/api/lookups/rooms';
  static const String _bedsPath = '/api/lookups/beds';

  Future<List<Map<String, dynamic>>> listDepartments() async {
    final res = await ApiClient.dio.get(
      _departmentsPath,
      queryParameters: {'limit': 200},
    );
    return _extractList(res.data);
  }

  Future<List<Map<String, dynamic>>> listRooms({
    required String departmentId,
  }) async {
    final res = await ApiClient.dio.get(
      _roomsPath,
      queryParameters: {'departmentId': departmentId, 'limit': 300},
    );
    return _extractList(res.data);
  }

  Future<List<Map<String, dynamic>>> listAvailableBeds({
    required String roomId,
  }) async {
    final res = await ApiClient.dio.get(
      _bedsPath,
      queryParameters: {'roomId': roomId, 'onlyAvailable': true, 'limit': 500},
    );

    final beds = _extractList(res.data);

    // extra safety filter
    return beds.where((b) {
      final st = (b['status'] ?? '').toString().toUpperCase();
      if (st.isEmpty) return true;
      return st == 'AVAILABLE' || st == 'RESERVED';
    }).toList();
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final data = m['data'];

      if (m['items'] is List) {
        return (m['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (data is Map) {
        final dm = Map<String, dynamic>.from(data);
        if (dm['items'] is List) {
          return (dm['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    }
    return const [];
  }
}
