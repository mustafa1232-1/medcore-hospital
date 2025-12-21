import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/orders/data/api/lookups_api_service_v2.dart';
import 'package:mobile/src_v2/features/orders/data/api/users_api_service_v2.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';

class AdminCreateUserPage extends StatefulWidget {
  const AdminCreateUserPage({super.key});

  @override
  State<AdminCreateUserPage> createState() => _AdminCreateUserPageState();
}

class _AdminCreateUserPageState extends State<AdminCreateUserPage> {
  final _usersApi = UsersApiServiceV2();
  final _lookups = LookupsApiServiceV2();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String _role = 'DOCTOR'; // DOCTOR/NURSE/LAB/PHARMACY/RECEPTION
  String? _departmentId;

  bool _loadingDeps = true;
  List<Map<String, dynamic>> _departments = const [];

  bool _saving = false;
  String? _error;

  bool get _needsDept => (_role == 'DOCTOR' || _role == 'NURSE');

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _loadingDeps = true;
      _error = null;
    });

    try {
      final deps = await _lookups.listDepartments();
      if (!mounted) return;
      setState(() {
        _departments = deps;
        _loadingDeps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingDeps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'إضافة موظف',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) ...[
            _errorBox(_error!),
            const SizedBox(height: 12),
          ],

          _section('بيانات الموظف'),
          const SizedBox(height: 8),

          TextField(controller: _fullName, decoration: _dec('الاسم الكامل')),
          const SizedBox(height: 10),

          TextField(
            controller: _email,
            decoration: _dec('البريد الإلكتروني (اختياري)'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _phone,
            decoration: _dec('رقم الهاتف (اختياري)'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _password,
            decoration: _dec('كلمة المرور'),
            obscureText: true,
          ),

          const SizedBox(height: 14),
          _section('الوظيفة'),
          const SizedBox(height: 8),

          _roleDropdown(),
          const SizedBox(height: 10),

          if (_needsDept) _departmentDropdown(),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'جاري الإنشاء...' : 'إنشاء'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String t) => InputDecoration(
    labelText: t,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  Widget _section(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w900));

  Widget _roleDropdown() {
    final theme = Theme.of(context);
    const roles = ['DOCTOR', 'NURSE', 'LAB', 'PHARMACY', 'RECEPTION'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _role,
          isExpanded: true,
          items: roles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) {
            final next = v ?? 'DOCTOR';
            setState(() {
              _role = next;
              if (!(_role == 'DOCTOR' || _role == 'NURSE')) {
                _departmentId = null; // ✅ لا نخزن قسم لدور لا يحتاجه
              }
            });
          },
        ),
      ),
    );
  }

  String _depTitle(Map<String, dynamic> d) {
    final label = (d['label'] ?? '').toString().trim();
    final name = (d['name'] ?? '').toString().trim();
    final code = (d['code'] ?? '').toString().trim();
    if (label.isNotEmpty) return label;
    if (name.isNotEmpty) return name;
    if (code.isNotEmpty) return code;
    return 'قسم';
  }

  Widget _departmentDropdown() {
    final theme = Theme.of(context);

    if (_loadingDeps) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withAlpha(40)),
          color: theme.colorScheme.surface,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('جاري تحميل الأقسام...'),
          ],
        ),
      );
    }

    final items = _departments
        .where((d) => (d['id'] ?? '').toString().trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _departmentId,
          hint: const Text('اختر القسم (مطلوب للطبيب/الممرض)'),
          isExpanded: true,
          items: items.map((d) {
            final id = (d['id'] ?? '').toString();
            return DropdownMenuItem(value: id, child: Text(_depTitle(d)));
          }).toList(),
          onChanged: (v) => setState(() => _departmentId = v),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }

  Future<void> _submit() async {
    final fullName = _fullName.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;

    if (fullName.length < 2) {
      setState(() => _error = 'الاسم مطلوب');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (email.isEmpty && phone.isEmpty) {
      setState(() => _error = 'يجب إدخال الإيميل أو الهاتف');
      return;
    }

    if (_needsDept && (_departmentId == null || _departmentId!.isEmpty)) {
      setState(() => _error = 'اختيار القسم مطلوب للطبيب/الممرض');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _usersApi.createUser(
        fullName: fullName,
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        password: password,
        roles: [_role],
        departmentId: _needsDept ? _departmentId : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء المستخدم بنجاح')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
