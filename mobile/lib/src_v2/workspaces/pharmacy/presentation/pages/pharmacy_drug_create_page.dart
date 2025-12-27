// ignore_for_file: unused_element, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';
import 'package:mobile/src_v2/features/orders/data/services/orders_api_service.dart';

class PharmacyDrugCreatePage extends StatefulWidget {
  const PharmacyDrugCreatePage({super.key});

  @override
  State<PharmacyDrugCreatePage> createState() => _PharmacyDrugCreatePageState();
}

class _PharmacyDrugCreatePageState extends State<PharmacyDrugCreatePage> {
  final _api = PharmacyApiService();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  String? _error;

  // Identification
  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _atcCtrl = TextEditingController();
  final _rxcuiCtrl = TextEditingController();

  // Characteristics
  String _form = 'TABLET';
  String _route = 'ORAL';

  final _strengthValueCtrl = TextEditingController();
  String _strengthUnit = 'mg';

  final _concValueCtrl = TextEditingController();
  String _concUnit = 'mg/mL';

  // Packaging
  final _packSizeCtrl = TextEditingController();
  String _packUnit = 'tabs';

  final _storageCtrl = TextEditingController();

  // Operational
  bool _active = true;
  bool _controlled = false;
  bool _rxRequired = true;

  final _reorderLevelCtrl = TextEditingController();
  final _reorderQtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ✅ New DB fields (patient instructions & regimen)
  final _patientArCtrl = TextEditingController();
  final _patientEnCtrl = TextEditingController();
  final _dosageTextCtrl = TextEditingController(); // مثال: 1 قرص
  final _frequencyTextCtrl = TextEditingController(); // مثال: 3 مرات يومياً
  final _durationTextCtrl = TextEditingController(); // مثال: 5 أيام
  bool? _withFood; // null => غير محدد
  final _warningsTextCtrl = TextEditingController(); // تحذيرات مختصرة

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _brandCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _atcCtrl.dispose();
    _rxcuiCtrl.dispose();
    _strengthValueCtrl.dispose();
    _concValueCtrl.dispose();
    _packSizeCtrl.dispose();
    _storageCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _reorderQtyCtrl.dispose();
    _notesCtrl.dispose();

    _patientArCtrl.dispose();
    _patientEnCtrl.dispose();
    _dosageTextCtrl.dispose();
    _frequencyTextCtrl.dispose();
    _durationTextCtrl.dispose();
    _warningsTextCtrl.dispose();

    super.dispose();
  }

  num? _num(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  int? _int(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String? _optionalTrim(TextEditingController c) {
    final s = c.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await _api.createDrug(
        // Core
        name: _nameCtrl.text,
        genericName: _optionalTrim(_genericCtrl),
        brandName: _optionalTrim(_brandCtrl),
        code: _optionalTrim(_codeCtrl),
        barcode: _optionalTrim(_barcodeCtrl),

        // Common pharma (these may be ignored by backend if not supported)
        form: _form,
        route: _route,
        // Keep strength as combined text if backend expects "strength" string
        strength: _strengthValueCtrl.text.trim().isEmpty
            ? null
            : '${_strengthValueCtrl.text.trim()} $_strengthUnit',

        // ✅ New DB columns (snake_case supported by service method)
        patientInstructionsAr: _optionalTrim(_patientArCtrl),
        patientInstructionsEn: _optionalTrim(_patientEnCtrl),
        dosageText: _optionalTrim(_dosageTextCtrl),
        frequencyText: _optionalTrim(_frequencyTextCtrl),
        durationText: _optionalTrim(_durationTextCtrl),
        withFood: _withFood,
        warningsText: _optionalTrim(_warningsTextCtrl),

        // Operational
        isActive: _active,
        notes: _optionalTrim(_notesCtrl),
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
      title: 'تسجيل دواء جديد',
      actions: [
        TextButton(
          onPressed: _busy ? null : _save,
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
        child: Form(
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

              _sectionTitle(context, 'التعريف (Identification)'),
              _text(
                _nameCtrl,
                label: 'الاسم (Name) *',
                icon: Icons.badge_rounded,
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'الاسم مطلوب';
                  if ((v ?? '').trim().length < 2) return 'الاسم قصير جداً';
                  return null;
                },
              ),
              _text(
                _genericCtrl,
                label: 'الاسم العلمي (Generic name)',
                icon: Icons.science_rounded,
              ),
              _text(
                _brandCtrl,
                label: 'الاسم التجاري (Brand name)',
                icon: Icons.local_offer_rounded,
              ),
              _text(
                _codeCtrl,
                label: 'كود داخلي (SKU)',
                icon: Icons.qr_code_2_rounded,
              ),
              _text(
                _barcodeCtrl,
                label: 'باركود (GTIN)',
                icon: Icons.qr_code_rounded,
              ),

              Row(
                children: [
                  Expanded(
                    child: _text(
                      _atcCtrl,
                      label: 'ATC code (اختياري)',
                      icon: Icons.account_tree_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _text(
                      _rxcuiCtrl,
                      label: 'RxCUI (اختياري)',
                      icon: Icons.link_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'الخصائص الدوائية (Pharmaceutical)'),
              _dropdown(
                value: _form,
                label: 'الشكل الدوائي (Dosage form)',
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
                onChanged: _busy ? null : (v) => setState(() => _form = v),
              ),
              _dropdown(
                value: _route,
                label: 'طريقة الإعطاء (Route)',
                icon: Icons.route_rounded,
                items: const [
                  'ORAL',
                  'IV',
                  'IM',
                  'SC',
                  'TOPICAL',
                  'INHALATION',
                  'RECTAL',
                  'VAGINAL',
                  'OPHTHALMIC',
                  'OTIC',
                  'NASAL',
                  'OTHER',
                ],
                onChanged: _busy ? null : (v) => setState(() => _route = v),
              ),

              Row(
                children: [
                  Expanded(
                    child: _text(
                      _strengthValueCtrl,
                      label: 'القوة/التركيز (Strength value)',
                      icon: Icons.straighten_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown(
                      value: _strengthUnit,
                      label: 'وحدة القوة (Unit)',
                      icon: Icons.scale_rounded,
                      items: const ['mg', 'g', 'mcg', 'IU', 'mEq', '%'],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _strengthUnit = v),
                    ),
                  ),
                ],
              ),

              // تركنا concentration كما هو (اختياري) بدون إرسال منفصل للبك اند
              // حتى لا نكسر التوافق مع createDrug الحالية
              Row(
                children: [
                  Expanded(
                    child: _text(
                      _concValueCtrl,
                      label: 'Concentration value (اختياري)',
                      icon: Icons.opacity_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown(
                      value: _concUnit,
                      label: 'Conc. unit',
                      icon: Icons.water_drop_rounded,
                      items: const ['mg/mL', 'mcg/mL', 'g/L', '%'],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _concUnit = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'التعبئة والحفظ (Packaging & Storage)'),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      _packSizeCtrl,
                      label: 'حجم العبوة (Pack size)',
                      icon: Icons.inventory_2_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown(
                      value: _packUnit,
                      label: 'وحدة العبوة (Pack unit)',
                      icon: Icons.stacked_bar_chart_rounded,
                      items: const [
                        'tabs',
                        'caps',
                        'mL',
                        'ampoules',
                        'vials',
                        'bags',
                        'units',
                        'other',
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _packUnit = v),
                    ),
                  ),
                ],
              ),
              _text(
                _storageCtrl,
                label: 'شروط الخزن (Storage conditions)',
                icon: Icons.thermostat_rounded,
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'تعليمات للمريض (Patient Instructions)'),
              _text(
                _patientArCtrl,
                label: 'تعليمات بالعربية (patient_instructions_ar)',
                icon: Icons.translate_rounded,
                maxLines: 3,
              ),
              _text(
                _patientEnCtrl,
                label: 'تعليمات بالإنجليزية (patient_instructions_en)',
                icon: Icons.language_rounded,
                maxLines: 3,
              ),
              _text(
                _dosageTextCtrl,
                label: 'الجرعة (dosage_text) مثال: 1 قرص',
                icon: Icons.medication_rounded,
              ),
              _text(
                _frequencyTextCtrl,
                label: 'التكرار (frequency_text) مثال: 3 مرات يومياً',
                icon: Icons.repeat_rounded,
              ),
              _text(
                _durationTextCtrl,
                label: 'المدة (duration_text) مثال: 5 أيام',
                icon: Icons.timelapse_rounded,
              ),
              _withFoodPicker(theme),
              _text(
                _warningsTextCtrl,
                label: 'تحذيرات مختصرة (warnings_text)',
                icon: Icons.warning_amber_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'تشغيلي (Operational)'),
              SwitchListTile(
                value: _active,
                onChanged: _busy ? null : (v) => setState(() => _active = v),
                title: const Text('Active'),
              ),
              SwitchListTile(
                value: _controlled,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _controlled = v),
                title: const Text('Controlled / Narcotic'),
              ),
              SwitchListTile(
                value: _rxRequired,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _rxRequired = v),
                title: const Text('Prescription required'),
              ),

              Row(
                children: [
                  Expanded(
                    child: _text(
                      _reorderLevelCtrl,
                      label: 'Reorder level (اختياري)',
                      icon: Icons.warning_amber_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _text(
                      _reorderQtyCtrl,
                      label: 'Reorder qty (اختياري)',
                      icon: Icons.shopping_cart_checkout_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _text(
                _notesCtrl,
                label: 'ملاحظات (Notes)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ الدواء'),
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
          labelText: 'مع الأكل؟ (with_food)',
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
            onChanged: _busy ? null : (v) => setState(() => _withFood = v),
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
        enabled: !_busy,
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
