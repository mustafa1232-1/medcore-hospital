// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/patient/services/patient_join_service.dart';

class PatientJoinFacilityPage extends StatefulWidget {
  const PatientJoinFacilityPage({super.key});

  @override
  State<PatientJoinFacilityPage> createState() =>
      _PatientJoinFacilityPageState();
}

class _PatientJoinFacilityPageState extends State<PatientJoinFacilityPage> {
  final _tenantCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  final _qrCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tenantCtrl.dispose();
    _patientCtrl.dispose();
    _codeCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  void _applyQrJson() {
    final s = _qrCtrl.text.trim();
    if (s.isEmpty) return;

    try {
      final obj = json.decode(s);
      if (obj is Map) {
        final m = Map<String, dynamic>.from(obj);
        _tenantCtrl.text = (m['tenantId'] ?? '').toString();
        _patientCtrl.text = (m['patientId'] ?? '').toString();
        _codeCtrl.text = (m['joinCode'] ?? '').toString();
        setState(() => _error = null);
        return;
      }
      setState(() => _error = 'QR payload must be a JSON object');
    } catch (_) {
      setState(() => _error = 'Invalid JSON in QR payload');
    }
  }

  Future<void> _join() async {
    final tenantId = _tenantCtrl.text.trim();
    final patientId = _patientCtrl.text.trim();
    final joinCode = _codeCtrl.text.trim();

    if (tenantId.isEmpty || patientId.isEmpty || joinCode.isEmpty) {
      setState(() => _error = 'الرجاء إدخال tenantId + patientId + joinCode');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final out = await PatientJoinService.joinFacility(
        tenantId: tenantId,
        patientId: patientId,
        joinCode: joinCode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ربط الحساب بالمنشأة بنجاح')),
      );

      Navigator.pop<Map<String, dynamic>>(context, {
        'tenantId': tenantId,
        'patientId': patientId,
        'joinCode': joinCode,
        'server': out,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'ربط الحساب بمنشأة',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) _errorBox(theme, _error!),

          _card(
            theme,
            title: 'QR Payload (JSON)',
            child: Column(
              children: [
                TextField(
                  controller: _qrCtrl,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        '{"tenantId":"...","patientId":"...","joinCode":"..."}',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _applyQrJson,
                    child: const Text('تعبئة الحقول من QR JSON'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _card(
            theme,
            title: 'إدخال يدوي',
            child: Column(
              children: [
                TextField(
                  controller: _tenantCtrl,
                  decoration: const InputDecoration(labelText: 'Tenant ID'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _patientCtrl,
                  decoration: const InputDecoration(labelText: 'Patient ID'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Join Code'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _join,
                    child: const Text('تأكيد الربط'),
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
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
