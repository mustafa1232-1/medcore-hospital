import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/orders/data/api/users_api_service_v2.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _api = UsersApiServiceV2();
  final _q = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  String _status = 'ALL'; // ALL/ACTIVE/INACTIVE

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final active = _status == 'ALL'
          ? null
          : (_status == 'ACTIVE' ? true : false);

      final users = await _api.listUsers(q: _q.text, active: active);

      if (!mounted) return;
      setState(() {
        _users = users;
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

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'الموظفون',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'بحث (اسم/إيميل/هاتف/Staff ID)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _statusFilter(),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(_error!)
            else if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('لا توجد نتائج')),
              )
            else
              ..._users.map(_tile),
          ],
        ),
      ),
    );
  }

  Widget _statusFilter() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('الكل')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('نشط')),
            DropdownMenuItem(value: 'INACTIVE', child: Text('غير نشط')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _status = v);
            _load();
          },
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> u) {
    final name = (u['fullName'] ?? '').toString();
    final staffCode = (u['staffCode'] ?? '').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final isActive = (u['isActive'] == true);

    final roles = (u['roles'] is List) ? (u['roles'] as List).join(', ') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(
          name.isEmpty ? '—' : name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (staffCode.isNotEmpty) 'Staff: $staffCode',
            if (roles.isNotEmpty) 'Roles: $roles',
            if (email.isNotEmpty) email,
            if (phone.isNotEmpty) phone,
          ].join('\n'),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (v) async {
            await _api.setActive((u['id'] ?? '').toString(), v);
            _load();
          },
        ),
        onTap: () => _openActions(u),
      ),
    );
  }

  Future<void> _openActions(Map<String, dynamic> u) async {
    final id = (u['id'] ?? '').toString();
    final name = (u['fullName'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Reset Password'),
              onTap: () async {
                Navigator.pop(context);
                final newPass = await _askPassword();
                if (newPass == null) return;
                await _api.resetPassword(id, newPass);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث كلمة المرور')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askPassword() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('كلمة مرور جديدة'),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'على الأقل 6 أحرف'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    final v = (ok == true) ? c.text.trim() : null;
    c.dispose();
    if (v == null || v.length < 6) return null;
    return v;
  }

  Widget _errorBox(String e) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 10),
            Text(e, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
