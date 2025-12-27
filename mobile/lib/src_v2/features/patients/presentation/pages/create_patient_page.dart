// lib/src_v2/features/patients/presentation/pages/create_patient_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/patients/data/services/patients_api_service.dart';
import 'package:mobile/src_v2/features/admissions/presentation/pages/create_admission_page.dart';

class CreatePatientPage extends StatefulWidget {
  const CreatePatientPage({super.key});

  @override
  State<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends State<CreatePatientPage> {
  final _api = PatientsApiService();

  bool _saving = false;
  String? _error;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _gender; // MALE/FEMALE/OTHER
  final _dob = TextEditingController(); // yyyy-mm-dd
  final _nationalId = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _dob.dispose();
    _nationalId.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء مريض')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) ...[
            _errorBox(theme, _error!),
            const SizedBox(height: 10),
          ],

          _sectionTitle('معلومات أساسية'),
          const SizedBox(height: 8),

          _text(
            controller: _fullName,
            label: 'الاسم الكامل *',
            hint: 'مثال: أحمد محمد',
          ),
          const SizedBox(height: 10),

          _text(
            controller: _phone,
            label: 'الهاتف (اختياري)',
            hint: '07xxxxxxxxx',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),

          _text(
            controller: _email,
            label: 'Email (اختياري)',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),
          _genderPicker(),

          const SizedBox(height: 10),
          _text(
            controller: _dob,
            label: 'تاريخ الميلاد (اختياري)',
            hint: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
          ),

          const SizedBox(height: 14),
          _divider(),

          _sectionTitle('معلومات إضافية'),
          const SizedBox(height: 8),

          _text(
            controller: _nationalId,
            label: 'الرقم الوطني / هوية (اختياري)',
            hint: 'ID / National ID',
          ),
          const SizedBox(height: 10),

          _multiline(
            controller: _address,
            label: 'العنوان (اختياري)',
            hint: 'المدينة - المنطقة - أقرب نقطة...',
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 10),

          _multiline(
            controller: _notes,
            label: 'ملاحظات (اختياري)',
            hint: 'أي معلومات مهمة للاستقبال/الطبيب...',
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
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'جاري الحفظ...' : 'إنشاء ثم تعيين طبيب'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final fullName = _fullName.text.trim();
    if (fullName.isEmpty) {
      setState(() {
        _saving = false;
        _error = 'الاسم الكامل مطلوب.';
      });
      return;
    }

    try {
      // ✅ مهم: خزّن نتيجة الإنشاء
      final created = await _api.createPatient(
        fullName: fullName,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        gender: (_gender == null || _gender!.trim().isEmpty) ? null : _gender,
        dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
        nationalId: _nationalId.text.trim().isEmpty
            ? null
            : _nationalId.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      if (!mounted) return;

      final patientId = (created['id'] ?? '').toString().trim();
      final patientLabel =
          (created['fullName'] ?? created['full_name'] ?? fullName)
              .toString()
              .trim();

      if (patientId.isEmpty) {
        setState(() {
          _error =
              'تم إنشاء المريض لكن لم يصل patientId من السيرفر. راجع Response.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء المريض. الآن عيّن الطبيب وافتح Admission.'),
        ),
      );

      // ✅ افتح صفحة Create Admission
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateAdmissionPage(
            patientId: patientId,
            patientLabel: patientLabel.isEmpty ? patientId : patientLabel,
          ),
        ),
      );

      if (!mounted) return;

      // ✅ ارجع true حتى تعمل Refresh لقائمة المرضى
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- UI helpers ----------------

  Widget _sectionTitle(String s) =>
      Text(s, style: const TextStyle(fontWeight: FontWeight.w900));

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Divider(height: 1),
  );

  Widget _text({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _genderPicker() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'الجنس (اختياري)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _gender,
          isExpanded: true,
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('غير محدد')),
            DropdownMenuItem<String?>(value: 'MALE', child: Text('ذكر - MALE')),
            DropdownMenuItem<String?>(
              value: 'FEMALE',
              child: Text('أنثى - FEMALE'),
            ),
            DropdownMenuItem<String?>(
              value: 'OTHER',
              child: Text('Other - OTHER'),
            ),
          ],
          onChanged: (v) => setState(() => _gender = v),
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
}
