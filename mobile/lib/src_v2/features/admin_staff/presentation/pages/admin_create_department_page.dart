import 'package:flutter/material.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../orders/data/api/departments_api_service_v2.dart';

class AdminCreateDepartmentPage extends StatefulWidget {
  const AdminCreateDepartmentPage({super.key});

  @override
  State<AdminCreateDepartmentPage> createState() =>
      _AdminCreateDepartmentPageState();
}

class _AdminCreateDepartmentPageState extends State<AdminCreateDepartmentPage> {
  final _api = DepartmentsApiServiceV2();

  final _name = TextEditingController();
  final _code = TextEditingController();

  // ✅ NEW
  final _roomsCount = TextEditingController(text: '1');
  final _bedsPerRoom = TextEditingController(text: '1');

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _roomsCount.dispose();
    _bedsPerRoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rooms = int.tryParse(_roomsCount.text.trim()) ?? 0;
    final beds = int.tryParse(_bedsPerRoom.text.trim()) ?? 0;
    final totalBeds = (rooms > 0 && beds > 0) ? rooms * beds : 0;

    return V2ShellScaffold(
      title: 'إضافة قسم',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) ...[
            _errorBox(_error!),
            const SizedBox(height: 12),
          ],

          const Text(
            'بيانات القسم',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'اسم القسم',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _code,
            decoration: InputDecoration(
              labelText: 'كود القسم (اختياري)',
              hintText: 'اتركه فارغاً وسيتم توليده تلقائياً',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✅ NEW: Rooms & Beds setup
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withAlpha(40)),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تهيئة الغرف والأسِرّة',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'حدد عدد الغرف داخل القسم وعدد الأسرّة داخل كل غرفة. سيتم إنشاء الغرف والأسِرّة تلقائياً بعد إنشاء القسم.',
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roomsCount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'عدد الغرف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _bedsPerRoom,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'عدد الأسرّة لكل غرفة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.primary.withAlpha(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bed_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          totalBeds > 0
                              ? 'الإجمالي المتوقع: $totalBeds سرير'
                              : 'أدخل أرقام صحيحة لإظهار الإجمالي',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'إنشاء القسم'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final code = _code.text.trim();

    final roomsCount = int.tryParse(_roomsCount.text.trim());
    final bedsPerRoom = int.tryParse(_bedsPerRoom.text.trim());

    if (name.length < 2) {
      setState(() => _error = 'اسم القسم مطلوب');
      return;
    }

    // ✅ NEW validation
    if (roomsCount == null || roomsCount < 1) {
      setState(() => _error = 'عدد الغرف يجب أن يكون 1 أو أكثر');
      return;
    }
    if (bedsPerRoom == null || bedsPerRoom < 1) {
      setState(() => _error = 'عدد الأسرّة لكل غرفة يجب أن يكون 1 أو أكثر');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _api.createDepartment(
        name: name,
        code: code.isEmpty ? null : code,
        isActive: true,

        // ✅ NEW payload
        roomsCount: roomsCount,
        bedsPerRoom: bedsPerRoom,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء القسم بنجاح')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
