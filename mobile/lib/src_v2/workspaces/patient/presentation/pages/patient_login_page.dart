// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_auth_service.dart';
import 'package:mobile/src_v2/workspaces/patient/presentation/pages/patient_facilities_page.dart';

class PatientLoginPage extends StatefulWidget {
  static const routeName = '/patient/login';
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _useEmail = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await PatientAuthService.login(
        phone: _useEmail ? null : _phoneCtrl.text,
        email: _useEmail ? _emailCtrl.text : null,
        password: _passCtrl.text,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, PatientFacilitiesPage.routeName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'تسجيل دخول المريض',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) _errorBox(theme, _error!),

          _card(
            theme,
            title: 'بيانات الدخول',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Phone')),
                          ButtonSegment(value: true, label: Text('Email')),
                        ],
                        selected: {_useEmail},
                        onSelectionChanged: (s) =>
                            setState(() => _useEmail = s.first),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!_useEmail)
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '+9647xxxxxxxxx',
                    ),
                  )
                else
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@mail.com',
                    ),
                  ),

                const SizedBox(height: 10),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: const Text('تسجيل الدخول'),
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

          _card(
            theme,
            title: 'معلومات',
            child: const Text(
              'بعد تسجيل الدخول يمكنك ربط حسابك بأي منشأة عبر Join Code أو QR.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }
}
