// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';

class RegisterTenantPage extends StatefulWidget {
  const RegisterTenantPage({super.key});

  @override
  State<RegisterTenantPage> createState() => _RegisterTenantPageState();
}

class _RegisterTenantPageState extends State<RegisterTenantPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'hospital');
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _tenantCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _tenantCode = null;
    });

    try {
      final res = await AuthService.registerTenant(
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        adminFullName: _adminNameCtrl.text.trim(),
        adminEmail: _adminEmailCtrl.text.trim(),
        adminPhone: _adminPhoneCtrl.text.trim(),
        adminPassword: _adminPasswordCtrl.text,
      );

      final tenant = (res['tenant'] as Map?)?.cast<String, dynamic>();
      final code = tenant?['code']?.toString();

      if (code == null || code.isEmpty) {
        throw Exception('Missing tenant code');
      }

      setState(() {
        _tenantCode = code;
      });
    } catch (_) {
      setState(() {
        _error = 'فشل إنشاء المنشأة. تأكد من البيانات ثم أعد المحاولة.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء منشأة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'بيانات المنشأة',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _dec(
                              'اسم المنشأة',
                              hint: 'مثال: مستشفى بسماية',
                              icon: Icons.business,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _typeCtrl,
                            decoration: _dec(
                              'النوع',
                              hint: 'hospital / lab / pharmacy / warehouse',
                              icon: Icons.category_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: _dec(
                              'هاتف المنشأة (اختياري)',
                              hint: '07xxxxxxxxx',
                              icon: Icons.phone,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _dec(
                              'إيميل المنشأة (اختياري)',
                              hint: 'info@domain.com',
                              icon: Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 18),
                          Text(
                            'بيانات الأدمن',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminNameCtrl,
                            decoration: _dec(
                              'اسم الأدمن',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminEmailCtrl,
                            decoration: _dec(
                              'إيميل الأدمن (اختياري)',
                              icon: Icons.alternate_email,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminPhoneCtrl,
                            decoration: _dec(
                              'هاتف الأدمن (اختياري)',
                              icon: Icons.phone_iphone,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminPasswordCtrl,
                            decoration: _dec(
                              'كلمة مرور الأدمن',
                              icon: Icons.lock_outline,
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'على الأقل 6 أحرف'
                                : null,
                          ),

                          const SizedBox(height: 14),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('إنشاء'),
                          ),

                          if (_tenantCode != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: theme.colorScheme.primary.withOpacity(
                                  0.08,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'تم إنشاء المنشأة بنجاح',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _tenantCode!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'انسخ رمز المنشأة واستخدمه في تسجيل الدخول.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.login),
                                    label: const Text('العودة لتسجيل الدخول'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
