// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_store.dart';
import '../../core/auth/patient_session_store.dart';

import '../../workspaces/patient/services/patient_auth_service.dart';
import '../../workspaces/patient/services/patient_register_service.dart';

// ✅ NEW: go to PatientHomePage directly (profile works without joining)
import '../../workspaces/patient/presentation/pages/patient_home_page.dart';

import 'register_tenant_page.dart';

enum _LoginMode { staff, patient }

enum _PatientView { login, register }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKeyStaff = GlobalKey<FormState>();
  final _formKeyPatient = GlobalKey<FormState>();

  // Staff controllers
  final _tenantCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Patient controllers
  final _pEmailCtrl = TextEditingController();
  final _pPhoneCtrl = TextEditingController();
  final _pPasswordCtrl = TextEditingController();

  final _pFullNameCtrl = TextEditingController(); // register
  final _pRegisterPassCtrl = TextEditingController(); // register

  bool _useEmail = true; // staff
  bool _pUseEmail = false; // patient

  bool _obscure = true; // staff
  bool _pObscure = true; // patient

  bool _loading = false;
  String? _error;

  _LoginMode _mode = _LoginMode.staff;
  _PatientView _patientView = _PatientView.login;

  @override
  void dispose() {
    _tenantCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();

    _pEmailCtrl.dispose();
    _pPhoneCtrl.dispose();
    _pPasswordCtrl.dispose();
    _pFullNameCtrl.dispose();
    _pRegisterPassCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _loading = v);
  }

  void _goPatientHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientHomePage(
          tenantId: null, // ✅ not required for profile
        ),
      ),
    );
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  // =========================
  // Staff submit
  // =========================
  Future<void> _submitStaff() async {
    if (!_formKeyStaff.currentState!.validate()) return;

    _setLoading(true);
    _setError(null);

    try {
      await context.read<AuthStore>().login(
        tenant: _tenantCtrl.text.trim(),
        email: _useEmail ? _emailCtrl.text.trim() : null,
        phone: !_useEmail ? _phoneCtrl.text.trim() : null,
        password: _passwordCtrl.text,
      );
      // ✅ V2Shell will redirect to staff workspace automatically
    } catch (_) {
      _setError('فشل تسجيل الدخول. تأكد من رمز المنشأة وبيانات الحساب.');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // Patient Login submit
  // =========================
  Future<void> _submitPatientLogin() async {
    if (!_formKeyPatient.currentState!.validate()) return;

    _setLoading(true);
    _setError(null);

    try {
      await PatientAuthService.login(
        phone: _pUseEmail ? null : _pPhoneCtrl.text.trim(),
        email: _pUseEmail ? _pEmailCtrl.text.trim() : null,
        password: _pPasswordCtrl.text,
      );

      await context.read<PatientSessionStore>().refresh();

      if (!mounted) return;

      // ✅ NEW: patient sees portal + profile even without joining a facility
      _goPatientHome();
    } catch (_) {
      _setError('فشل دخول المريض. تحقق من البيانات أو أنشئ حساباً جديداً.');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // Patient Register submit
  // =========================
  Future<void> _submitPatientRegister() async {
    if (!_formKeyPatient.currentState!.validate()) return;

    _setLoading(true);
    _setError(null);

    try {
      await PatientRegisterService.register(
        fullName: _pFullNameCtrl.text.trim(),
        phone: _pUseEmail ? null : _pPhoneCtrl.text.trim(),
        email: _pUseEmail ? _pEmailCtrl.text.trim() : null,
        password: _pRegisterPassCtrl.text,
      );

      await context.read<PatientSessionStore>().refresh();

      if (!mounted) return;

      // ✅ NEW: go to portal
      _goPatientHome();
    } catch (_) {
      _setError('فشل إنشاء الحساب. قد يكون البريد/الهاتف مستخدم مسبقاً.');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // Build
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.secondary.withOpacity(0.10),
              Colors.transparent,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      title: 'Medcore',
                      subtitle:
                          'نظام موحّد للمستشفيات، المختبرات، الصيدليات، والمذاخر',
                    ),
                    const SizedBox(height: 12),

                    _ModeSelector(
                      value: _mode,
                      onChanged: (m) {
                        setState(() {
                          _mode = m;
                          _error = null;
                          if (m == _LoginMode.staff) {
                            _patientView = _PatientView.login;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),

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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: (_mode == _LoginMode.staff)
                              ? _buildStaffForm(theme)
                              : _buildPatientBlock(theme),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      _mode == _LoginMode.staff
                          ? 'ملاحظة: رمز المنشأة خاص بالكادر فقط.'
                          : 'ملاحظة: بوابة المريض تعمل بدون ربط منشأة. الربط يتم لاحقاً عبر QR / Join Code عند الحاجة.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // Staff form
  // =========================
  Widget _buildStaffForm(ThemeData theme) {
    return Form(
      key: _formKeyStaff,
      child: Column(
        key: const ValueKey('staffForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل الدخول (كادر)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _tenantCtrl,
            decoration: _dec(
              label: 'رمز المنشأة',
              hint: 'مثال: bismaya-4k7q (أو الصق UUID وسيعمل)',
              icon: Icons.apartment_rounded,
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),

          _SwitchRow(
            left: 'Email',
            right: 'Phone',
            value: _useEmail,
            onChanged: (v) => setState(() {
              _useEmail = v;
              _error = null;
            }),
          ),
          const SizedBox(height: 10),

          if (_useEmail)
            TextFormField(
              controller: _emailCtrl,
              decoration: _dec(
                label: 'البريد الإلكتروني',
                hint: 'admin@domain.com',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _useEmail && (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            )
          else
            TextFormField(
              controller: _phoneCtrl,
              decoration: _dec(
                label: 'رقم الهاتف',
                hint: '07xxxxxxxxx',
                icon: Icons.phone_iphone,
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) => !_useEmail && (v == null || v.trim().isEmpty)
                  ? 'مطلوب'
                  : null,
            ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _passwordCtrl,
            decoration: _dec(
              label: 'كلمة المرور',
              icon: Icons.lock_outline,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
            onFieldSubmitted: (_) => _loading ? null : _submitStaff(),
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
            onPressed: _loading ? null : _submitStaff,
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('دخول'),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterTenantPage()),
              );
            },
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('إنشاء منشأة جديدة (أدمن)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Patient block (login/register)
  // =========================
  Widget _buildPatientBlock(ThemeData theme) {
    final isRegister = _patientView == _PatientView.register;

    return Column(
      key: const ValueKey('patientBlock'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isRegister ? 'إنشاء حساب مريض' : 'تسجيل دخول المريض',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                      _error = null;
                      _patientView = isRegister
                          ? _PatientView.login
                          : _PatientView.register;
                    }),
              child: Text(isRegister ? 'لدي حساب' : 'إنشاء حساب'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Phone')),
                  ButtonSegment(value: true, label: Text('Email')),
                ],
                selected: {_pUseEmail},
                onSelectionChanged: (s) => setState(() {
                  _pUseEmail = s.first;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Form(
          key: _formKeyPatient,
          child: Column(
            children: [
              if (!_pUseEmail)
                TextFormField(
                  controller: _pPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(
                    label: 'رقم الهاتف',
                    hint: '+9647xxxxxxxxx',
                    icon: Icons.phone_iphone,
                  ),
                  validator: (v) {
                    if (_pUseEmail) return null;
                    return (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
                  },
                )
              else
                TextFormField(
                  controller: _pEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec(
                    label: 'البريد الإلكتروني',
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (!_pUseEmail) return null;
                    return (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
                  },
                ),

              const SizedBox(height: 12),

              if (isRegister) ...[
                TextFormField(
                  controller: _pFullNameCtrl,
                  decoration: _dec(
                    label: 'الاسم الكامل',
                    hint: 'مثال: أحمد علي حسين',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'مطلوب';
                    if (s.length < 2) return 'الاسم قصير جداً';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: isRegister ? _pRegisterPassCtrl : _pPasswordCtrl,
                obscureText: _pObscure,
                decoration: _dec(
                  label: 'كلمة المرور',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    onPressed: () => setState(() => _pObscure = !_pObscure),
                    icon: Icon(
                      _pObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (v) {
                  final s = (v ?? '');
                  if (s.isEmpty) return 'مطلوب';
                  if (isRegister && s.length < 6)
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  return null;
                },
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

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : (isRegister
                            ? _submitPatientRegister
                            : _submitPatientLogin),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isRegister ? 'إنشاء الحساب' : 'تسجيل الدخول'),
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: const Text(
            'بعد الدخول يمكنك استخدام بوابة المريض مباشرة. وربط منشأة عبر Join Code / QR متاح عند الحاجة.',
          ),
        ),
      ],
    );
  }
}

// =========================
// Widgets
// =========================

class _ModeSelector extends StatelessWidget {
  final _LoginMode value;
  final ValueChanged<_LoginMode> onChanged;

  const _ModeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill(String text, bool active) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: active
                ? theme.colorScheme.primary.withOpacity(0.16)
                : Colors.transparent,
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withOpacity(0.45)
                  : theme.dividerColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(_LoginMode.staff),
            child: pill('كادر', value == _LoginMode.staff),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onChanged(_LoginMode.patient),
            child: pill('مريض', value == _LoginMode.patient),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.85),
                    theme.colorScheme.tertiary.withOpacity(0.70),
                  ],
                ),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String left;
  final String right;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: _pill(context, left, isActive: value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: _pill(context, right, isActive: !value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text, {required bool isActive}) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? theme.colorScheme.primary.withOpacity(0.16)
            : Colors.transparent,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.45)
              : theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isActive ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
