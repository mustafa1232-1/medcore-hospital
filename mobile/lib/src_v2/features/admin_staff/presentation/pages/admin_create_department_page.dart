import 'package:flutter/material.dart';

import '../../../orders/data/api/departments_api_service_v2.dart';
import '../../../orders/data/api/lookups_api_service_v2.dart';

class AdminCreateDepartmentPage extends StatefulWidget {
  const AdminCreateDepartmentPage({super.key});

  @override
  State<AdminCreateDepartmentPage> createState() =>
      _AdminCreateDepartmentPageState();
}

class _AdminCreateDepartmentPageState extends State<AdminCreateDepartmentPage> {
  final _formKey = GlobalKey<FormState>();

  final _departmentsApi = DepartmentsApiServiceV2();
  final _lookupsApi = LookupsApiServiceV2();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _systemDepartments = [];
  String? _selectedSystemDepartmentId;

  int _roomsCount = 1;
  int _bedsPerRoom = 1;

  @override
  void initState() {
    super.initState();
    _loadSystemDepartments();
  }

  Future<void> _loadSystemDepartments() async {
    try {
      setState(() => _loading = true);
      final items = await _lookupsApi.listSystemDepartments();
      setState(() {
        _systemDepartments = items;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الأقسام';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSystemDepartmentId == null) return;

    try {
      setState(() => _saving = true);

      await _departmentsApi.activateDepartment(
        systemDepartmentId: _selectedSystemDepartmentId!,
        roomsCount: _roomsCount,
        bedsPerRoom: _bedsPerRoom,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'فشل تفعيل القسم';
      });
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل قسم')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],

                    // ======================
                    // System Department
                    // ======================
                    const Text(
                      'القسم',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),

                    DropdownButtonFormField<String>(
                      value: _selectedSystemDepartmentId,
                      items: _systemDepartments
                          .map<DropdownMenuItem<String>>(
                            (d) => DropdownMenuItem<String>(
                              value: d['id'] as String,
                              child: Text(
                                (d['name_ar'] ?? d['name'] ?? d['code'])
                                    .toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedSystemDepartmentId = v);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر القسم',
                      ),
                      validator: (v) => v == null ? 'القسم مطلوب' : null,
                    ),

                    const SizedBox(height: 20),

                    // ======================
                    // Rooms count
                    // ======================
                    _NumberField(
                      label: 'عدد الغرف',
                      value: _roomsCount,
                      onChanged: (v) => setState(() => _roomsCount = v),
                    ),

                    const SizedBox(height: 16),

                    // ======================
                    // Beds per room
                    // ======================
                    _NumberField(
                      label: 'عدد الأسرة في كل غرفة',
                      value: _bedsPerRoom,
                      onChanged: (v) => setState(() => _bedsPerRoom = v),
                    ),

                    const SizedBox(height: 28),

                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('تفعيل القسم'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ======================
// Reusable number field
// ======================
class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < 1) {
          return 'أدخل رقمًا صحيحًا ≥ 1';
        }
        return null;
      },
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null && n >= 1) {
          onChanged(n);
        }
      },
    );
  }
}
