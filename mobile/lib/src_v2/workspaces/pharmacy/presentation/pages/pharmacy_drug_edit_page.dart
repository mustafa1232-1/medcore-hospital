// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

class PharmacyDrugEditPage extends StatefulWidget {
  final String drugId;

  const PharmacyDrugEditPage({super.key, required this.drugId});

  @override
  State<PharmacyDrugEditPage> createState() => _PharmacyDrugEditPageState();
}

class _PharmacyDrugEditPageState extends State<PharmacyDrugEditPage> {
  final _api = PharmacyApiService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _busy = false;
  String? _error;

  Map<String, dynamic>? _drug;

  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  String _form = 'TABLET';

  bool _active = true;
  final _notesCtrl = TextEditingController();

  // New DB fields
  final _patientArCtrl = TextEditingController();
  final _patientEnCtrl = TextEditingController();
  final _dosageTextCtrl = TextEditingController();
  final _frequencyTextCtrl = TextEditingController();
  final _durationTextCtrl = TextEditingController();
  bool? _withFood;
  final _warningsTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _brandCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _strengthCtrl.dispose();
    _routeCtrl.dispose();
    _notesCtrl.dispose();

    _patientArCtrl.dispose();
    _patientEnCtrl.dispose();
    _dosageTextCtrl.dispose();
    _frequencyTextCtrl.dispose();
    _durationTextCtrl.dispose();
    _warningsTextCtrl.dispose();
    super.dispose();
  }

  String _pick(dynamic a, dynamic b, dynamic c) {
    final s = (a ?? b ?? c ?? '').toString().trim();
    return s;
  }

  void _fillFromDrug(Map<String, dynamic> d) {
    _nameCtrl.text = _pick(d['name'], d['genericName'], d['generic_name']);
    _genericCtrl.text = _pick(d['genericName'], d['generic_name'], '');
    _brandCtrl.text = _pick(d['brandName'], d['brand_name'], '');
    _codeCtrl.text = _pick(d['code'], d['sku'], '');
    _barcodeCtrl.text = _pick(d['barcode'], d['gtin'], '');
    _strengthCtrl.text = _pick(d['strength'], '', '');
    _routeCtrl.text = _pick(d['route'], '', '');
    _form = _pick(d['form'], 'TABLET', 'TABLET');
    _active = (d['isActive'] ?? d['is_active'] ?? true) == true;
    _notesCtrl.text = _pick(d['notes'], '', '');

    _patientArCtrl.text = _pick(
      d['patient_instructions_ar'],
      d['patientInstructionsAr'],
      '',
    );
    _patientEnCtrl.text = _pick(
      d['patient_instructions_en'],
      d['patientInstructionsEn'],
      '',
    );
    _dosageTextCtrl.text = _pick(d['dosage_text'], d['dosageText'], '');
    _frequencyTextCtrl.text = _pick(
      d['frequency_text'],
      d['frequencyText'],
      '',
    );
    _durationTextCtrl.text = _pick(d['duration_text'], d['durationText'], '');

    final wf = d['with_food'] ?? d['withFood'];
    _withFood = (wf is bool) ? wf : null;

    _warningsTextCtrl.text = _pick(d['warnings_text'], d['warningsText'], '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final d = await _api.getDrugById(widget.drugId);
      _drug = d;
      _fillFromDrug(d);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _optTrim(TextEditingController c) {
    final s = c.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await _api.updateDrug(
        id: widget.drugId,
        name: _optTrim(_nameCtrl),
        genericName: _optTrim(_genericCtrl),
        brandName: _optTrim(_brandCtrl),
        code: _optTrim(_codeCtrl),
        barcode: _optTrim(_barcodeCtrl),
        form: _form,
        strength: _optTrim(_strengthCtrl),
        route: _optTrim(_routeCtrl),
        isActive: _active,
        notes: _optTrim(_notesCtrl),

        patientInstructionsAr: _optTrim(_patientArCtrl),
        patientInstructionsEn: _optTrim(_patientEnCtrl),
        dosageText: _optTrim(_dosageTextCtrl),
        frequencyText: _optTrim(_frequencyTextCtrl),
        durationText: _optTrim(_durationTextCtrl),
        withFood: _withFood,
        warningsText: _optTrim(_warningsTextCtrl),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'تعديل الدواء',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: (_loading || _busy) ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        TextButton(
          onPressed: (_loading || _busy) ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'حفظ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _drug == null
            ? _ErrorState(message: _error!, onRetry: _load)
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: theme.colorScheme.error.withAlpha(12),
                          border: Border.all(
                            color: theme.colorScheme.error.withAlpha(70),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _sectionTitle(context, 'معلومات أساسية'),
                    _text(
                      _nameCtrl,
                      label: 'الاسم *',
                      icon: Icons.badge_rounded,
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return 'الاسم مطلوب';
                        return null;
                      },
                    ),
                    _text(
                      _genericCtrl,
                      label: 'الاسم العلمي',
                      icon: Icons.science_rounded,
                    ),
                    _text(
                      _brandCtrl,
                      label: 'الاسم التجاري',
                      icon: Icons.local_offer_rounded,
                    ),
                    _text(
                      _codeCtrl,
                      label: 'SKU',
                      icon: Icons.qr_code_2_rounded,
                    ),
                    _text(
                      _barcodeCtrl,
                      label: 'Barcode',
                      icon: Icons.qr_code_rounded,
                    ),

                    const SizedBox(height: 10),
                    _sectionTitle(context, 'خصائص دوائية'),
                    _dropdown(
                      value: _form,
                      label: 'الشكل الدوائي',
                      icon: Icons.category_rounded,
                      items: const [
                        'TABLET',
                        'CAPSULE',
                        'SYRUP',
                        'INJECTION',
                        'DROPS',
                        'CREAM',
                        'OINTMENT',
                        'SUPPOSITORY',
                        'IV_BAG',
                        'INHALER',
                        'OTHER',
                      ],
                      onChanged: (_loading || _busy)
                          ? null
                          : (v) => setState(() => _form = v),
                    ),
                    _text(
                      _strengthCtrl,
                      label: 'القوة/التركيز (Strength)',
                      icon: Icons.straighten_rounded,
                    ),
                    _text(
                      _routeCtrl,
                      label: 'طريقة الإعطاء (Route)',
                      icon: Icons.route_rounded,
                    ),

                    const SizedBox(height: 10),
                    _sectionTitle(context, 'تعليمات للمريض / الجرعة'),
                    _text(
                      _patientArCtrl,
                      label: 'تعليمات بالعربية',
                      icon: Icons.translate_rounded,
                      maxLines: 3,
                    ),
                    _text(
                      _patientEnCtrl,
                      label: 'تعليمات بالإنجليزية',
                      icon: Icons.language_rounded,
                      maxLines: 3,
                    ),
                    _text(
                      _dosageTextCtrl,
                      label: 'الجرعة (مثال: 1 قرص)',
                      icon: Icons.medication_rounded,
                    ),
                    _text(
                      _frequencyTextCtrl,
                      label: 'التكرار (مثال: 3 مرات يومياً)',
                      icon: Icons.repeat_rounded,
                    ),
                    _text(
                      _durationTextCtrl,
                      label: 'المدة (مثال: 5 أيام)',
                      icon: Icons.timelapse_rounded,
                    ),
                    _withFoodPicker(theme),
                    _text(
                      _warningsTextCtrl,
                      label: 'تحذيرات مختصرة',
                      icon: Icons.warning_amber_rounded,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 10),
                    _sectionTitle(context, 'تشغيلي'),
                    SwitchListTile(
                      value: _active,
                      onChanged: (_loading || _busy)
                          ? null
                          : (v) => setState(() => _active = v),
                      title: const Text('Active'),
                    ),
                    _text(
                      _notesCtrl,
                      label: 'ملاحظات',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: (_loading || _busy) ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ التعديلات'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _withFoodPicker(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'مع الأكل؟',
          prefixIcon: const Icon(Icons.restaurant_rounded),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<bool?>(
            isExpanded: true,
            value: _withFood,
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('غير محدد')),
              DropdownMenuItem<bool?>(
                value: true,
                child: Text('نعم (مع الأكل)'),
              ),
              DropdownMenuItem<bool?>(
                value: false,
                child: Text('لا (بدون أكل)'),
              ),
            ],
            onChanged: (_loading || _busy)
                ? null
                : (v) => setState(() => _withFood = v),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _text(
    TextEditingController c, {
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        enabled: !(_loading || _busy),
        keyboardType: keyboard,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String v)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged == null ? null : (v) => onChanged(v!),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withAlpha(45)),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                'تعذر فتح الدواء',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
