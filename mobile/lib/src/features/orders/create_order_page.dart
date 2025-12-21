import 'package:flutter/material.dart';
import 'orders_api_service.dart';

enum OrderKind { medication, lab, procedure }

class CreateOrderPage extends StatefulWidget {
  static const routeName = '/orders/create';
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _orders = OrdersApiService();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  OrderKind _kind = OrderKind.medication;

  // shared
  final _admissionId = TextEditingController();
  final _notes = TextEditingController();

  // medication
  final _medName = TextEditingController();
  final _dose = TextEditingController();
  final _route = TextEditingController(text: 'IV');
  final _frequency = TextEditingController(text: 'BID');
  final _duration = TextEditingController();

  // lab
  final _testName = TextEditingController();
  String _priority = 'ROUTINE';
  final _specimen = TextEditingController(text: 'BLOOD');

  // procedure
  final _procedureName = TextEditingController();
  String _urgency = 'NORMAL';

  @override
  void dispose() {
    _admissionId.dispose();
    _notes.dispose();
    _medName.dispose();
    _dose.dispose();
    _route.dispose();
    _frequency.dispose();
    _duration.dispose();
    _testName.dispose();
    _specimen.dispose();
    _procedureName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _result = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      Map<String, dynamic> res;

      final admissionId = _admissionId.text.trim();
      final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();

      switch (_kind) {
        case OrderKind.medication:
          res = await _orders.createMedicationOrder(
            admissionId: admissionId,
            medicationName: _medName.text.trim(),
            dose: _dose.text.trim(),
            route: _route.text.trim(),
            frequency: _frequency.text.trim(),
            duration: _duration.text.trim().isEmpty
                ? null
                : _duration.text.trim(),
            startNow: true,
            notes: notes,
          );
          break;

        case OrderKind.lab:
          res = await _orders.createLabOrder(
            admissionId: admissionId,
            testName: _testName.text.trim(),
            priority: _priority,
            specimen: _specimen.text.trim(),
            notes: notes,
          );
          break;

        case OrderKind.procedure:
          res = await _orders.createProcedureOrder(
            admissionId: admissionId,
            procedureName: _procedureName.text.trim(),
            urgency: _urgency,
            notes: notes,
          );
          break;
      }

      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController c,
    String? hint,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (v) {
        if (requiredField && (v == null || v.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _kindSelector() {
    return SegmentedButton<OrderKind>(
      segments: const [
        ButtonSegment(value: OrderKind.medication, label: Text('دواء')),
        ButtonSegment(value: OrderKind.lab, label: Text('تحليل')),
        ButtonSegment(value: OrderKind.procedure, label: Text('إجراء')),
      ],
      selected: {_kind},
      onSelectionChanged: (s) => setState(() => _kind = s.first),
    );
  }

  Widget _kindFields() {
    switch (_kind) {
      case OrderKind.medication:
        return Column(
          children: [
            _field(label: 'اسم الدواء', c: _medName, requiredField: true),
            _field(
              label: 'الجرعة',
              c: _dose,
              hint: '500mg',
              requiredField: true,
            ),
            _field(
              label: 'الطريق',
              c: _route,
              hint: 'IV / PO',
              requiredField: true,
            ),
            _field(
              label: 'التكرار',
              c: _frequency,
              hint: 'BID / TID / q8h',
              requiredField: true,
            ),
            _field(label: 'المدة', c: _duration, hint: '5 days'),
          ],
        );

      case OrderKind.lab:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              label: 'اسم التحليل',
              c: _testName,
              hint: 'CBC',
              requiredField: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              items: const [
                DropdownMenuItem(value: 'ROUTINE', child: Text('ROUTINE')),
                DropdownMenuItem(value: 'STAT', child: Text('STAT')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'ROUTINE'),
              decoration: const InputDecoration(labelText: 'الأولوية'),
            ),
            _field(
              label: 'نوع العينة',
              c: _specimen,
              hint: 'BLOOD',
              requiredField: true,
            ),
          ],
        );

      case OrderKind.procedure:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              label: 'اسم الإجراء',
              c: _procedureName,
              requiredField: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _urgency,
              items: const [
                DropdownMenuItem(value: 'NORMAL', child: Text('NORMAL')),
                DropdownMenuItem(value: 'URGENT', child: Text('URGENT')),
              ],
              onChanged: (v) => setState(() => _urgency = v ?? 'NORMAL'),
              decoration: const InputDecoration(labelText: 'الاستعجال'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء أمر')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _kindSelector(),
              const SizedBox(height: 16),
              _field(
                label: 'Admission ID',
                c: _admissionId,
                requiredField: true,
              ),
              const SizedBox(height: 12),
              _kindFields(),
              const SizedBox(height: 12),
              _field(label: 'ملاحظات', c: _notes),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'جاري الإرسال...' : 'إرسال الأمر'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'النتيجة:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_result.toString()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
