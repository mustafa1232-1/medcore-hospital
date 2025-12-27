// lib/src_v2/features/pharmacy_admin/presentation/pages/admin_create_warehouse_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

class AdminCreateWarehousePage extends StatefulWidget {
  const AdminCreateWarehousePage({super.key});

  @override
  State<AdminCreateWarehousePage> createState() =>
      _AdminCreateWarehousePageState();
}

class _AdminCreateWarehousePageState extends State<AdminCreateWarehousePage> {
  final _api = PharmacyApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _pharmacists = const [];
  String? _selectedPharmacistId;

  @override
  void initState() {
    super.initState();
    _loadPharmacists();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacists() async {
    setState(() {
      _error = null;
      _pharmacists = const [];
      _selectedPharmacistId = null;
    });

    try {
      final items = await _api.listPharmacists(limit: 200, offset: 0);
      setState(() {
        _pharmacists = items;
        if (items.isNotEmpty) {
          _selectedPharmacistId = (items.first['id'] ?? '').toString();
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _labelOf(Map<String, dynamic> u) {
    final fullName = (u['fullName'] ?? u['name'] ?? '').toString().trim();
    final staffCode = (u['staffCode'] ?? '').toString().trim();
    final email = (u['email'] ?? '').toString().trim();
    final phone = (u['phone'] ?? '').toString().trim();

    final left = fullName.isEmpty ? '—' : fullName;
    final right = staffCode.isNotEmpty
        ? staffCode
        : (email.isNotEmpty ? email : (phone.isNotEmpty ? phone : ''));
    return right.isEmpty ? left : '$left • $right';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPharmacistId == null || _selectedPharmacistId!.isEmpty) {
      setState(() => _error = 'يجب اختيار صيدلي لتعيينه على المستودع.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.createWarehouse(
        name: _nameCtrl.text,
        code: _codeCtrl.text,
        pharmacistUserId: _selectedPharmacistId!,
        isActive: true,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // created
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'إنشاء مستودع',
      actions: [
        IconButton(
          tooltip: 'تحديث قائمة الصيادلة',
          onPressed: _loading ? null : _loadPharmacists,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor.withAlpha(45)),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withAlpha(18),
                      child: Icon(
                        Icons.warehouse_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يجب تعيين صيدلي على المستودع (Mandatory).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.dividerColor.withAlpha(45)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'بيانات المستودع',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _dec(
                            context,
                            label: 'اسم المستودع',
                            hint: 'مثال: Main Pharmacy Warehouse',
                            icon: Icons.local_pharmacy_rounded,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'اسم المستودع مطلوب (على الأقل حرفين).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _codeCtrl,
                          decoration: _dec(
                            context,
                            label: 'رمز المستودع (اختياري)',
                            hint: 'مثال: PHARM-MAIN',
                            icon: Icons.qr_code_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'تعيين الصيدلي (إجباري)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                        _pharmacists.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withAlpha(
                                      70,
                                    ),
                                  ),
                                  color: theme.colorScheme.error.withAlpha(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'لا يوجد صيادلة حالياً.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'أنشئ موظف بدور PHARMACY أولاً، ثم عد هنا.',
                                      style: TextStyle(
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withAlpha(190),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : _loadPharmacists,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('تحديث القائمة'),
                                    ),
                                  ],
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedPharmacistId,
                                items: _pharmacists.map((u) {
                                  final id = (u['id'] ?? '').toString();
                                  return DropdownMenuItem(
                                    value: id,
                                    child: Text(
                                      _labelOf(u),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() {
                                        _selectedPharmacistId = v;
                                      }),
                                decoration: _dec(
                                  context,
                                  label: 'الصيدلي',
                                  hint: 'اختر صيدلي',
                                  icon: Icons.medical_services_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'اختيار الصيدلي مطلوب.';
                                  }
                                  return null;
                                },
                              ),

                        const SizedBox(height: 16),

                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(_loading ? 'جارٍ الإنشاء...' : 'إنشاء'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
