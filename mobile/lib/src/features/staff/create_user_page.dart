import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'users_api_service.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _useEmail = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final Set<String> _roles = {'DOCTOR'};
  final List<String> _allRoles = const [
    'ADMIN',
    'DOCTOR',
    'NURSE',
    'PHARMACY',
    'LAB',
    'RECEPTION',
    'WAREHOUSE',
  ];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(
    String label, {
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

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final roles = _roles.toList()..sort();

      await UsersApiService.createUser(
        fullName: _fullNameCtrl.text.trim(),
        email: _useEmail ? _emailCtrl.text.trim() : null,
        phone: !_useEmail ? _phoneCtrl.text.trim() : null,
        password: _passwordCtrl.text,
        roles: roles,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.create_user_success)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.create_user_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.dividerColor.withAlpha(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.create_user_section,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: _dec(
                          t.create_user_full_name,
                          icon: Icons.badge_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? t.common_confirm
                            : null,
                      ),

                      const SizedBox(height: 12),

                      _SwitchRow(
                        left: t.create_user_email,
                        right: t.create_user_phone,
                        value: _useEmail,
                        onChanged: (v) => setState(() => _useEmail = v),
                      ),
                      const SizedBox(height: 10),

                      if (_useEmail)
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _dec(
                            t.create_user_email,
                            hint: 'user@domain.com',
                            icon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              _useEmail && (v == null || v.trim().isEmpty)
                              ? t.common_confirm
                              : null,
                        )
                      else
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: _dec(
                            t.create_user_phone,
                            hint: '07xxxxxxxxx',
                            icon: Icons.phone_iphone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              !_useEmail && (v == null || v.trim().isEmpty)
                              ? t.common_confirm
                              : null,
                        ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: _dec(
                          t.create_user_password,
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        obscureText: _obscure,
                        validator: (v) => (v == null || v.length < 6)
                            ? t.resetPassword_short
                            : null,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        t.create_user_roles,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allRoles.map((r) {
                          final selected = _roles.contains(r);
                          return FilterChip(
                            label: Text(
                              r,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _roles.add(r);
                                } else {
                                  _roles.remove(r);
                                  if (_roles.isEmpty) _roles.add('DOCTOR');
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
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
                            : Text(t.create_user_submit),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
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
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? theme.colorScheme.primary.withAlpha(35)
            : Colors.transparent,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withAlpha(70)
              : theme.dividerColor.withAlpha(40),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isActive ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
