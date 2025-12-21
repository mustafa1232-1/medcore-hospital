import 'package:flutter/material.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../orders/data/api/departments_api_service_v2.dart';
import 'admin_create_department_page.dart';

// ✅ NEW: details page
import 'admin_department_details_page.dart';

class AdminDepartmentsPage extends StatefulWidget {
  const AdminDepartmentsPage({super.key});

  @override
  State<AdminDepartmentsPage> createState() => _AdminDepartmentsPageState();
}

class _AdminDepartmentsPageState extends State<AdminDepartmentsPage> {
  final _api = DepartmentsApiServiceV2();
  final _q = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool _onlyActive = true;

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
      final items = await _api.listDepartments(
        query: _q.text,
        active: _onlyActive ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'الأقسام',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _headerCard(theme),

            const SizedBox(height: 12),

            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'بحث بالاسم أو الكود',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: _onlyActive,
                    label: const Text('فعّالة فقط'),
                    onSelected: (v) {
                      setState(() => _onlyActive = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminCreateDepartmentPage(),
                      ),
                    );
                    if (ok == true) _load();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة قسم'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(_error!, onRetry: _load)
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('لا توجد أقسام')),
              )
            else
              ..._items.map((d) => _depTile(d)),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withAlpha(25),
            child: Icon(
              Icons.apartment_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الأقسام',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'أنشئ أقسام المنشأة لتفعيل توزيع الأطباء والممرضين عليها.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _depTile(Map<String, dynamic> d) {
    final id = (d['id'] ?? '').toString();
    final code = (d['code'] ?? '').toString();
    final name = (d['name'] ?? '').toString();
    final isActive = (d['is_active'] ?? d['isActive'] ?? true) == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        // ✅ NEW: enter department details
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminDepartmentDetailsPage(
                departmentId: id,
                departmentName: name,
                departmentCode: code,
              ),
            ),
          );
        },
        title: Text(
          name.isEmpty ? '-' : name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(code.isEmpty ? '' : code),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'disable') {
              await _confirmDisable(id, name);
            } else if (v == 'enable') {
              await _setActive(id, true);
            }
          },
          itemBuilder: (_) => [
            if (isActive)
              const PopupMenuItem(value: 'disable', child: Text('تعطيل القسم'))
            else
              const PopupMenuItem(value: 'enable', child: Text('تفعيل القسم')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisable(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعطيل القسم'),
        content: Text('هل تريد تعطيل القسم: "$name" ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _api.deleteDepartment(id);
        if (!mounted) return;
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _setActive(String id, bool isActive) async {
    try {
      await _api.updateDepartment(id: id, isActive: isActive);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _errorBox(String msg, {required VoidCallback onRetry}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
