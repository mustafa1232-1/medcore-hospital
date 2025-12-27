// lib/src_v2/features/orders/presentation/pages/create_medication_order_page.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_underscores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/src_v2/features/orders/data/services/orders_api_service.dart';
import 'package:mobile/src_v2/features/admissions/data/services/admissions_api_service.dart';

class CreateMedicationOrderPage extends StatefulWidget {
  const CreateMedicationOrderPage({super.key});

  @override
  State<CreateMedicationOrderPage> createState() =>
      _CreateMedicationOrderPageState();
}

class _CreateMedicationOrderPageState extends State<CreateMedicationOrderPage> {
  final _ordersApi = const OrdersApiService();
  final _admissionsApi = const AdmissionsApiService();

  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _creatingVisit = false;
  String? _error;

  final _admissionId = TextEditingController();

  String? _patientId;
  String? _patientLabel;

  final _medicationName = TextEditingController();
  final _dose = TextEditingController();
  final _duration = TextEditingController();
  bool _startNow = true;

  String? _routeValue;
  String? _freqValue;
  final _routeFree = TextEditingController();
  final _freqFree = TextEditingController();

  String? _drugId;
  String? _drugLabel;

  final _requestedQty = TextEditingController();

  final _patientInstructionsAr = TextEditingController();
  final _patientInstructionsEn = TextEditingController();
  final _dosageText = TextEditingController();
  final _frequencyText = TextEditingController();
  final _durationText = TextEditingController();
  bool? _withFood;
  final _warningsText = TextEditingController();

  final _notes = TextEditingController();

  static const _routes = <String, String>{
    'ORAL': 'فموي (ORAL)',
    'IV': 'وريدي (IV)',
    'IM': 'عضلي (IM)',
    'SC': 'تحت الجلد (SC)',
    'INHALATION': 'استنشاق (INHALATION)',
    'TOPICAL': 'موضعي (TOPICAL)',
    'OTHER': 'أخرى',
  };

  static const _freqs = <String, String>{
    'STAT': 'حالاً (STAT)',
    'QD': 'مرة يومياً (QD)',
    'BID': 'مرتين يومياً (BID)',
    'TID': '3 مرات يومياً (TID)',
    'QID': '4 مرات يومياً (QID)',
    'Q6H': 'كل 6 ساعات (Q6H)',
    'Q8H': 'كل 8 ساعات (Q8H)',
    'Q12H': 'كل 12 ساعة (Q12H)',
    'PRN': 'عند اللزوم (PRN)',
    'OTHER': 'أخرى',
  };

  @override
  void dispose() {
    _admissionId.dispose();

    _medicationName.dispose();
    _dose.dispose();
    _duration.dispose();

    _routeFree.dispose();
    _freqFree.dispose();

    _requestedQty.dispose();

    _patientInstructionsAr.dispose();
    _patientInstructionsEn.dispose();
    _dosageText.dispose();
    _frequencyText.dispose();
    _durationText.dispose();
    _warningsText.dispose();

    _notes.dispose();
    super.dispose();
  }

  bool get _hasAdmission => _admissionId.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _buildPreviewText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء طلب دواء'),
        actions: [
          IconButton(
            tooltip: 'تفريغ الحقول',
            onPressed: _saving ? null : _clearAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            if (_error != null) ...[
              _errorBox(theme, _error!),
              const SizedBox(height: 10),
            ],

            _sectionHeader(
              title: 'اختيارات سريعة',
              subtitle: 'اختر المريض والدواء لتعبئة بعض الحقول تلقائياً',
            ),
            const SizedBox(height: 8),

            _pickerTile(
              label: 'المريض',
              value: _patientLabel,
              onPick: () async {
                final picked = await _pickFromLookup(
                  title: 'اختيار المريض',
                  searchHint: 'ابحث باسم المريض...',
                  loader: (q) => _ordersApi.lookupPatients(q: q),
                );
                if (picked == null) return;

                final pid = (picked['id'] ?? picked['patientId'] ?? '')
                    .toString()
                    .trim();

                setState(() {
                  _error = null;
                  _patientId = pid.isEmpty ? null : pid;
                  _patientLabel = _labelOfPicked(picked);
                  _admissionId.clear();
                });

                // 1) if lookup already returns admission, use it
                final fromLookup =
                    (picked['activeAdmissionId'] ?? picked['admissionId'] ?? '')
                        .toString()
                        .trim();
                if (fromLookup.isNotEmpty) {
                  setState(() => _admissionId.text = fromLookup);
                  return;
                }

                // 2) else ask backend (Doctor endpoint)
                if (_patientId != null) {
                  try {
                    final adm = await _admissionsApi
                        .getActiveAdmissionIdForPatient(patientId: _patientId!);
                    if (!mounted) return;
                    if (adm != null) {
                      setState(() => _admissionId.text = adm);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _error = e.toString());
                  }
                }
              },
              onClear: _patientLabel == null
                  ? null
                  : () => setState(() {
                      _patientLabel = null;
                      _patientId = null;
                      _admissionId.clear();
                    }),
            ),

            const SizedBox(height: 10),

            if (_patientId != null && !_hasAdmission) ...[
              _noAdmissionCard(),
              const SizedBox(height: 10),
            ] else if (_hasAdmission) ...[
              _admissionReadonlyCard(theme),
              const SizedBox(height: 10),
            ],

            _pickerTile(
              label: 'الدواء',
              value: _drugLabel,
              onPick: () async {
                final picked = await _pickFromLookup(
                  title: 'اختيار الدواء',
                  searchHint: 'ابحث باسم الدواء...',
                  loader: (q) => _ordersApi.lookupDrugs(q: q),
                );
                if (picked == null) return;

                final drugId = (picked['id'] ?? '').toString().trim();
                final drugName =
                    (picked['name'] ??
                            picked['label'] ??
                            picked['genericName'] ??
                            '')
                        .toString()
                        .trim();

                setState(() {
                  _drugId = drugId.isEmpty ? null : drugId;
                  _drugLabel = _labelOfPicked(picked);

                  if (drugName.isNotEmpty) _medicationName.text = drugName;

                  _patientInstructionsAr.text =
                      (picked['patientInstructionsAr'] ?? '').toString();
                  _patientInstructionsEn.text =
                      (picked['patientInstructionsEn'] ?? '').toString();
                  _dosageText.text = (picked['dosageText'] ?? '').toString();
                  _frequencyText.text = (picked['frequencyText'] ?? '')
                      .toString();
                  _durationText.text = (picked['durationText'] ?? '')
                      .toString();
                  _warningsText.text = (picked['warningsText'] ?? '')
                      .toString();

                  final wf = picked['withFood'];
                  if (wf == null) {
                    _withFood = null;
                  } else if (wf is bool) {
                    _withFood = wf;
                  } else {
                    final s = wf.toString().toLowerCase();
                    _withFood = (s == 'true' || s == '1');
                  }
                });
              },
              onClear: _drugLabel == null
                  ? null
                  : () => setState(() {
                      _drugLabel = null;
                      _drugId = null;
                    }),
            ),

            const SizedBox(height: 14),

            _sectionHeader(
              title: 'معاينة الوصفة',
              subtitle: 'تحقق سريعاً قبل الإرسال لتقليل الأخطاء',
            ),
            const SizedBox(height: 8),
            _previewCard(preview),
            const SizedBox(height: 14),

            _sectionHeader(
              title: 'معلومات أساسية (مطلوبة)',
              subtitle: 'هذه الحقول مطلوبة لإنشاء الطلب',
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _admissionId,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Admission ID (Auto)',
                hintText: 'اختر المريض أولاً',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  tooltip: 'نسخ',
                  onPressed: _admissionId.text.trim().isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _admissionId.text.trim()),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ Admission ID'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'اختر مريضاً ثم أنشئ زيارة/Admission';
                }
                return null;
              },
            ),

            const SizedBox(height: 10),

            _textForm(
              controller: _medicationName,
              label: 'اسم الدواء',
              hint: 'اختره من الأعلى أو اكتبه هنا',
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'اسم الدواء مطلوب' : null,
            ),
            const SizedBox(height: 10),

            _textForm(
              controller: _dose,
              label: 'الجرعة',
              hint: 'مثال: 1 قرص أو 500 mg',
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'الجرعة مطلوبة' : null,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _dropdownForm(
                    label: 'طريقة الإعطاء',
                    value: _routeValue,
                    items: _routes,
                    hint: 'اختر',
                    onChanged: (v) {
                      setState(() {
                        _routeValue = v;
                        if (v != 'OTHER') _routeFree.clear();
                      });
                    },
                    validator: (_) => _effectiveRoute().trim().isEmpty
                        ? 'طريقة الإعطاء مطلوبة'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdownForm(
                    label: 'التكرار',
                    value: _freqValue,
                    items: _freqs,
                    hint: 'اختر',
                    onChanged: (v) {
                      setState(() {
                        _freqValue = v;
                        if (v != 'OTHER') _freqFree.clear();
                      });
                    },
                    validator: (_) => _effectiveFrequency().trim().isEmpty
                        ? 'التكرار مطلوب'
                        : null,
                  ),
                ),
              ],
            ),

            if (_routeValue == 'OTHER') ...[
              const SizedBox(height: 10),
              _textForm(
                controller: _routeFree,
                label: 'طريقة الإعطاء (أخرى)',
                hint: 'اكتب طريقة الإعطاء',
                validator: (v) {
                  if (_routeValue != 'OTHER') return null;
                  return (v ?? '').trim().isEmpty ? 'اكتب طريقة الإعطاء' : null;
                },
              ),
            ],

            if (_freqValue == 'OTHER') ...[
              const SizedBox(height: 10),
              _textForm(
                controller: _freqFree,
                label: 'التكرار (أخرى)',
                hint: 'اكتب التكرار',
                validator: (v) {
                  if (_freqValue != 'OTHER') return null;
                  return (v ?? '').trim().isEmpty ? 'اكتب التكرار' : null;
                },
              ),
            ],

            const SizedBox(height: 10),

            _textForm(
              controller: _duration,
              label: 'المدة (اختياري)',
              hint: 'مثال: 5 أيام',
            ),

            const SizedBox(height: 6),
            SwitchListTile(
              value: _startNow,
              onChanged: _saving ? null : (v) => setState(() => _startNow = v),
              title: const Text('ابدأ الآن'),
              subtitle: const Text('startNow'),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 14),
            _divider(),

            _sectionHeader(
              title: 'ربط اختياري بالمخزون',
              subtitle: 'اختياري: يساعد الصيدلية على خصم الكمية عند التجهيز',
            ),
            const SizedBox(height: 8),

            _kvTile('Drug ID', _drugId ?? '-'),
            const SizedBox(height: 10),

            _textForm(
              controller: _requestedQty,
              label: 'الكمية المطلوبة (اختياري)',
              hint: 'مثال: 10',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                final n = num.tryParse(s);
                if (n == null || n <= 0) return 'الكمية غير صالحة';
                return null;
              },
            ),

            const SizedBox(height: 14),
            _divider(),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'تفاصيل إضافية (اختيارية)',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('تعليمات للمريض، تحذيرات، وملاحظات داخلية'),
              children: [
                const SizedBox(height: 8),

                _multiline(
                  controller: _patientInstructionsAr,
                  label: 'تعليمات للمريض (عربي)',
                ),
                const SizedBox(height: 10),

                _multiline(
                  controller: _patientInstructionsEn,
                  label: 'Patient instructions (EN)',
                ),
                const SizedBox(height: 10),

                _textForm(controller: _dosageText, label: 'Dosage text'),
                const SizedBox(height: 10),

                _textForm(controller: _frequencyText, label: 'Frequency text'),
                const SizedBox(height: 10),

                _textForm(controller: _durationText, label: 'Duration text'),
                const SizedBox(height: 10),

                _withFoodPicker(),
                const SizedBox(height: 10),

                _multiline(controller: _warningsText, label: 'تحذيرات'),
                const SizedBox(height: 14),

                _multiline(
                  controller: _notes,
                  label: 'Notes (داخلية)',
                  hint: 'ملاحظات للطبيب/الصيدلية...',
                  minLines: 3,
                  maxLines: 6,
                ),
                const SizedBox(height: 6),
              ],
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
                  : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'جاري الإرسال...' : 'إنشاء الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _admissionReadonlyCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admission موجود:\n${_admissionId.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noAdmissionCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.error.withAlpha(70)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لا يوجد Admission نشط لهذا المريض',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'لإنشاء طلب دواء يجب إنشاء زيارة (Outpatient) أو تنويم (Inpatient).',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _creatingVisit ? null : _createOutpatientVisit,
            icon: _creatingVisit
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline_rounded),
            label: Text(
              _creatingVisit
                  ? 'جاري إنشاء الزيارة...'
                  : 'إنشاء زيارة Outpatient (بدون سرير)',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createOutpatientVisit() async {
    if (_patientId == null) return;

    setState(() {
      _creatingVisit = true;
      _error = null;
    });

    try {
      final id = await _admissionsApi.createOutpatientVisit(
        patientId: _patientId!,
        notes: 'Medication-only visit',
      );

      if (!mounted) return;
      setState(() => _admissionId.text = id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء زيارة Outpatient بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creatingVisit = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_patientId == null) {
      setState(() => _error = 'اختيار المريض مطلوب.');
      return;
    }
    if (!_hasAdmission) {
      setState(
        () => _error =
            'لا يوجد Admission. أنشئ زيارة Outpatient ثم أعد المحاولة.',
      );
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => _error = 'يرجى تصحيح الحقول المميزة بالأحمر.');
      return;
    }

    setState(() => _saving = true);

    final admissionId = _admissionId.text.trim();
    final medicationName = _medicationName.text.trim();
    final dose = _dose.text.trim();
    final route = _effectiveRoute().trim();
    final frequency = _effectiveFrequency().trim();
    final duration = _duration.text.trim().isEmpty
        ? null
        : _duration.text.trim();

    num? requestedQty;
    final rq = _requestedQty.text.trim();
    if (rq.isNotEmpty) requestedQty = num.tryParse(rq);

    try {
      await _ordersApi.createMedicationOrder(
        admissionId: admissionId,
        medicationName: medicationName,
        dose: dose,
        route: route,
        frequency: frequency,
        duration: duration,
        startNow: _startNow,
        drugId: _drugId,
        requestedQty: requestedQty,
        patientInstructionsAr: _nullIfEmpty(_patientInstructionsAr.text.trim()),
        patientInstructionsEn: _nullIfEmpty(_patientInstructionsEn.text.trim()),
        dosageText: _nullIfEmpty(_dosageText.text.trim()),
        frequencyText: _nullIfEmpty(_frequencyText.text.trim()),
        durationText: _nullIfEmpty(_durationText.text.trim()),
        withFood: _withFood,
        warningsText: _nullIfEmpty(_warningsText.text.trim()),
        notes: _nullIfEmpty(_notes.text.trim()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء طلب الدواء بنجاح')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _effectiveRoute() {
    if (_routeValue == null) return '';
    if (_routeValue == 'OTHER') return _routeFree.text.trim();
    return _routeValue!.trim();
  }

  String _effectiveFrequency() {
    if (_freqValue == null) return '';
    if (_freqValue == 'OTHER') return _freqFree.text.trim();
    return _freqValue!.trim();
  }

  String _buildPreviewText() {
    final med = _medicationName.text.trim().isEmpty
        ? '—'
        : _medicationName.text.trim();
    final dose = _dose.text.trim().isEmpty ? '—' : _dose.text.trim();

    final route = _effectiveRoute();
    final routeLabel = route.isEmpty ? '—' : (_routes[route] ?? route);

    final freq = _effectiveFrequency();
    final freqLabel = freq.isEmpty ? '—' : (_freqs[freq] ?? freq);

    final dur = _duration.text.trim().isEmpty ? '—' : _duration.text.trim();

    final start = _startNow ? 'يبدأ الآن' : 'مجدول لاحقاً';
    final qty = _requestedQty.text.trim().isEmpty
        ? null
        : _requestedQty.text.trim();
    final inv = (qty == null) ? '' : '\nالكمية المطلوبة: $qty';

    final patient = (_patientLabel ?? '').trim().isEmpty ? null : _patientLabel;

    return [
      if (patient != null) 'المريض: $patient',
      'Admission: ${_hasAdmission ? _admissionId.text.trim() : '—'}',
      'الدواء: $med',
      'الجرعة: $dose',
      'الطريقة: $routeLabel',
      'التكرار: $freqLabel',
      'المدة: $dur',
      start,
      if (inv.isNotEmpty) inv.trim(),
    ].join('\n');
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor)),
      ],
    );
  }

  Widget _previewCard(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.receipt_long_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Divider(height: 1),
  );

  Widget _kvTile(String k, String v) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(v.isEmpty ? '-' : v),
        ],
      ),
    );
  }

  Widget _textForm({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        suffixIcon: suffix,
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
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _dropdownForm({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (state) {
        final theme = Theme.of(context);
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: state.errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) {
                      onChanged(v);
                      state.didChange(v);
                      setState(() {});
                    },
              icon: Icon(Icons.arrow_drop_down_rounded, color: theme.hintColor),
            ),
          ),
        );
      },
    );
  }

  Widget _withFoodPicker() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'مع الطعام؟ (withFood)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool?>(
          value: _withFood,
          isExpanded: true,
          items: const [
            DropdownMenuItem<bool?>(value: null, child: Text('غير محدد')),
            DropdownMenuItem<bool?>(
              value: true,
              child: Text('نعم - مع الطعام'),
            ),
            DropdownMenuItem<bool?>(
              value: false,
              child: Text('لا - بدون طعام'),
            ),
          ],
          onChanged: _saving ? null : (v) => setState(() => _withFood = v),
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

  Widget _pickerTile({
    required String label,
    required String? value,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final v = (value ?? '').trim();
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: theme.colorScheme.surface,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(v.isEmpty ? '-' : v),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              tooltip: 'مسح',
              onPressed: _saving ? null : onClear,
              icon: const Icon(Icons.clear_rounded),
            ),
          const Icon(Icons.search_rounded),
        ],
      ),
      onTap: _saving ? null : onPick,
    );
  }

  String _labelOfPicked(Map<String, dynamic> it) {
    final label = (it['label'] ?? '').toString().trim();
    if (label.isNotEmpty) return label;

    final name =
        (it['fullName'] ??
                it['name'] ??
                it['genericName'] ??
                it['brandName'] ??
                '')
            .toString()
            .trim();
    final code = (it['code'] ?? it['mrn'] ?? it['staffCode'] ?? '')
        .toString()
        .trim();

    return [
      name,
      if (code.isNotEmpty) '($code)',
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

  void _clearAll() {
    setState(() {
      _error = null;

      _patientId = null;
      _patientLabel = null;

      _drugId = null;
      _drugLabel = null;

      _admissionId.clear();
      _medicationName.clear();
      _dose.clear();
      _duration.clear();

      _routeValue = null;
      _freqValue = null;
      _routeFree.clear();
      _freqFree.clear();

      _requestedQty.clear();

      _patientInstructionsAr.clear();
      _patientInstructionsEn.clear();
      _dosageText.clear();
      _frequencyText.clear();
      _durationText.clear();
      _withFood = null;
      _warningsText.clear();

      _notes.clear();
      _startNow = true;
    });
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();
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
                                    it['fullName'] ??
                                    it['name'] ??
                                    it['genericName'] ??
                                    it['brandName'] ??
                                    '')
                                .toString();

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: theme.colorScheme.surface,
                          title: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
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
