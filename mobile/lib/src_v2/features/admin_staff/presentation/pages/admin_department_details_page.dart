// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/auth/auth_store.dart';
import 'package:provider/provider.dart';

import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../../core/rbac/role_utils.dart';

import '../../../orders/data/api/rooms_api_service_v2.dart';
import '../../../orders/data/api/departments_api_service_v2.dart';
import '../../../orders/data/api/users_api_service_v2.dart';

import 'admin_room_beds_page.dart';

class AdminDepartmentDetailsPage extends StatefulWidget {
  final String departmentId;
  final String? departmentName;
  final String? departmentCode;

  const AdminDepartmentDetailsPage({
    super.key,
    required this.departmentId,
    this.departmentName,
    this.departmentCode,
  });

  @override
  State<AdminDepartmentDetailsPage> createState() =>
      _AdminDepartmentDetailsPageState();
}

class _AdminDepartmentDetailsPageState
    extends State<AdminDepartmentDetailsPage> {
  final _roomsApi = RoomsApiServiceV2();
  final _depsApi = DepartmentsApiServiceV2();
  final _usersApi = UsersApiServiceV2();

  final _q = TextEditingController();

  bool _disposed = false;
  bool get _alive => mounted && !_disposed;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rooms = const [];
  bool _onlyActive = true;

  bool _staffLoading = true;
  String? _staffError;
  List<Map<String, dynamic>> _doctors = const [];
  List<Map<String, dynamic>> _nurses = const [];

  List<Map<String, dynamic>> _allActiveDepartments = const [];
  bool _depsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _disposed = true;
    _q.dispose();
    super.dispose();
  }

  bool _isAdmin(AuthStore auth) => RoleUtils.hasRole(auth.user, 'ADMIN');
  bool _isDoctor(AuthStore auth) => RoleUtils.hasRole(auth.user, 'DOCTOR');

  String _currentUserId(AuthStore auth) => (auth.user?['id'] ?? '').toString();

  bool _canManageDoctors(AuthStore auth) => _isAdmin(auth);
  bool _canManageNurses(AuthStore auth) => _isAdmin(auth) || _isDoctor(auth);

  bool _isSelf(AuthStore auth, Map<String, dynamic> staffUser) {
    final me = _currentUserId(auth);
    final uid = (staffUser['id'] ?? '').toString();
    return me.isNotEmpty && uid.isNotEmpty && me == uid;
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadRooms(), _loadStaff()]);
  }

  Future<void> _loadStaff() async {
    if (!_alive) return;

    setState(() {
      _staffLoading = true;
      _staffError = null;
    });

    try {
      final ov = await _depsApi.getDepartmentOverview(widget.departmentId);

      final staff = (ov['staff'] is Map) ? (ov['staff'] as Map) : const {};
      final doctors = (staff['doctors'] is List)
          ? (staff['doctors'] as List)
          : const [];
      final nurses = (staff['nurses'] is List)
          ? (staff['nurses'] as List)
          : const [];

      final docs = doctors
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      final nrs = nurses
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      if (!_alive) return;
      setState(() {
        _doctors = docs;
        _nurses = nrs;
        _staffLoading = false;
      });
    } catch (e) {
      if (!_alive) return;
      setState(() {
        _staffError = e.toString();
        _staffLoading = false;
      });
    }
  }

  Future<void> _loadRooms() async {
    if (!_alive) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _roomsApi.listRooms(
        departmentId: widget.departmentId,
        query: _q.text,
        active: _onlyActive ? true : null,
      );

      if (!_alive) return;
      setState(() {
        _rooms = items;
        _loading = false;
      });
    } catch (e) {
      if (!_alive) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // =========================
  // ✅ Add rooms (count only) - FIXED (no controller)
  // =========================
  Future<void> _addRoomsCountOnly() async {
    if (!_alive) return;

    String countText = '1';

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocal) => AlertDialog(
            title: const Text('إضافة غرف'),
            content: TextFormField(
              initialValue: countText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الغرف',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setLocal(() => countText = v),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(ctx2).unfocus(); // ✅ مهم
                  Navigator.pop(ctx2, false);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  FocusScope.of(ctx2).unfocus(); // ✅ مهم
                  Navigator.pop(ctx2, true);
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        );
      },
    );

    if (!_alive) return;
    if (ok != true) return;

    final n = int.tryParse(countText.trim()) ?? 0;
    if (n <= 0) {
      _showErrSnack('أدخل رقم صحيح');
      return;
    }

    try {
      _showBusySnack('جارٍ الإضافة...');

      final existing = await _roomsApi.listRooms(
        departmentId: widget.departmentId,
        query: '',
        active: null,
      );
      final startIndex = existing.length;

      for (int i = 1; i <= n; i++) {
        final seq = startIndex + i;
        await _roomsApi.createRoom(
          departmentId: widget.departmentId,
          name: 'غرفة $seq',
          code: '', // backend generates
          floor: null,
          isActive: true,
        );
      }

      if (!_alive) return;
      _showOkSnack('تمت إضافة $n غرفة');
      await _loadRooms();
    } catch (e) {
      if (!_alive) return;
      _showErrSnack(e.toString());
    }
  }

  Future<void> _ensureDepartmentsLoaded() async {
    if (_allActiveDepartments.isNotEmpty || _depsLoading) return;
    if (!_alive) return;

    setState(() => _depsLoading = true);
    try {
      final deps = await _depsApi.listDepartments(active: true);
      if (!_alive) return;

      final filtered = deps.where((d) {
        final id = (d['id'] ?? '').toString();
        return id.isNotEmpty && id != widget.departmentId;
      }).toList();

      setState(() => _allActiveDepartments = filtered);
    } catch (_) {
      // silent
    } finally {
      if (_alive) setState(() => _depsLoading = false);
    }
  }

  Future<void> _removeFromDepartment(Map<String, dynamic> staff) async {
    if (!_alive) return;

    final uid = (staff['id'] ?? '').toString();
    final name = (staff['fullName'] ?? staff['full_name'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة من القسم'),
        content: Text('هل تريد إزالة "$name" من هذا القسم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (!_alive) return;
    if (ok != true) return;

    try {
      _showBusySnack('جارٍ الإزالة...');
      await _usersApi.updateUserDepartment(userId: uid, departmentId: null);
      if (!_alive) return;
      _showOkSnack('تمت الإزالة');
      await _loadStaff();
    } catch (e) {
      if (!_alive) return;
      _showErrSnack(e.toString());
    }
  }

  Future<void> _moveToAnotherDepartment(Map<String, dynamic> staff) async {
    if (!_alive) return;

    await _ensureDepartmentsLoaded();

    final uid = (staff['id'] ?? '').toString();
    final name = (staff['fullName'] ?? staff['full_name'] ?? '').toString();

    String? selectedDeptId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocal) => AlertDialog(
            title: const Text('تحويل إلى قسم آخر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('اختر القسم الجديد لـ "$name":'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: _allActiveDepartments.map<DropdownMenuItem<String>>((
                    d,
                  ) {
                    final id = (d['id'] ?? '').toString();
                    final code = (d['code'] ?? '').toString();
                    final depName = (d['name'] ?? '').toString();
                    final label = depName.isEmpty
                        ? (code.isEmpty ? id : code)
                        : depName;
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (v) => setLocal(() => selectedDeptId = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'اختر القسم',
                  ),
                ),
                if (_allActiveDepartments.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('لا توجد أقسام أخرى فعّالة.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: selectedDeptId == null
                    ? null
                    : () => Navigator.pop(ctx2, true),
                child: const Text('تحويل'),
              ),
            ],
          ),
        );
      },
    );

    if (!_alive) return;
    if (ok != true || selectedDeptId == null) return;

    try {
      _showBusySnack('جارٍ التحويل...');
      await _usersApi.updateUserDepartment(
        userId: uid,
        departmentId: selectedDeptId,
      );
      if (!_alive) return;
      _showOkSnack('تم التحويل');
      await _loadStaff();
    } catch (e) {
      if (!_alive) return;
      _showErrSnack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    final title = (widget.departmentName?.trim().isNotEmpty ?? false)
        ? widget.departmentName!.trim()
        : 'تفاصيل القسم';

    return V2ShellScaffold(
      title: title,
      actions: [
        if (_isAdmin(auth))
          IconButton(
            onPressed: _addRoomsCountOnly,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة غرف',
          ),
        IconButton(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _headerCard(context),
            const SizedBox(height: 12),
            _staffCard(context, auth),
            const SizedBox(height: 14),

            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadRooms(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'بحث بالغرفة (اسم/كود)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                FilterChip(
                  selected: _onlyActive,
                  label: const Text('فعّالة فقط'),
                  onSelected: (v) {
                    setState(() => _onlyActive = v);
                    _loadRooms();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(_error!, onRetry: _loadRooms)
            else if (_rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Center(child: Text('لا توجد غرف لهذا القسم')),
              )
            else
              ..._rooms.map(_roomTile),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final code = (widget.departmentCode ?? '').trim();
    final subtitle = code.isEmpty
        ? 'استعرض الكادر والغرف.'
        : '($code) استعرض الكادر والغرف.';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نظرة عامة على القسم',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffCard(BuildContext context, AuthStore auth) {
    final theme = Theme.of(context);

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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withAlpha(25),
                child: Icon(
                  Icons.groups_2_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الكادر المرتبط بالقسم',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: _loadStaff,
                tooltip: 'تحديث الكادر',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_staffLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_staffError != null)
            _miniError(_staffError!, onRetry: _loadStaff)
          else ...[
            _staffSection(
              auth: auth,
              title: 'الأطباء',
              count: _doctors.length,
              icon: Icons.medical_services_rounded,
              items: _doctors,
              canManage: _canManageDoctors(auth),
            ),
            const SizedBox(height: 10),
            _staffSection(
              auth: auth,
              title: 'الممرضون',
              count: _nurses.length,
              icon: Icons.healing_rounded,
              items: _nurses,
              canManage: _canManageNurses(auth),
            ),
          ],
        ],
      ),
    );
  }

  Widget _staffSection({
    required AuthStore auth,
    required String title,
    required int count,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required bool canManage,
  }) {
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primary.withAlpha(18),
        child: Icon(icon, color: theme.colorScheme.primary, size: 18),
      ),
      title: Text(
        '$title ($count)',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        canManage ? 'اضغط لعرض القائمة وإدارة التوزيع' : 'اضغط لعرض القائمة',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withAlpha(170),
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('لا يوجد عناصر'),
            ),
          )
        else
          ...items.map(
            (u) => _staffTile(auth: auth, staff: u, canManage: canManage),
          ),
      ],
    );
  }

  Widget _staffTile({
    required AuthStore auth,
    required Map<String, dynamic> staff,
    required bool canManage,
  }) {
    final fullName = (staff['fullName'] ?? staff['full_name'] ?? '')
        .toString()
        .trim();
    final staffCode = (staff['staffCode'] ?? staff['staff_code'] ?? '')
        .toString()
        .trim();
    final phone = (staff['phone'] ?? '').toString().trim();
    final email = (staff['email'] ?? '').toString().trim();

    final title = fullName.isEmpty ? '—' : fullName;

    final parts = <String>[];
    if (staffCode.isNotEmpty) parts.add(staffCode);
    if (phone.isNotEmpty) parts.add(phone);
    if (email.isNotEmpty) parts.add(email);

    final subtitle = parts.join(' • ');

    final isSelf = _isSelf(auth, staff);
    final allowActions = canManage && !isSelf;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(18),
          child: Icon(
            Icons.person_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          enabled: allowActions,
          tooltip: allowActions
              ? 'إدارة'
              : (isSelf ? 'لا يمكن تعديل نفسك' : 'لا تملك صلاحية'),
          onSelected: (v) async {
            if (v == 'move') {
              await _moveToAnotherDepartment(staff);
            } else if (v == 'remove') {
              await _removeFromDepartment(staff);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'move',
              enabled: allowActions,
              child: const Text('تحويل إلى قسم آخر'),
            ),
            PopupMenuItem(
              value: 'remove',
              enabled: allowActions,
              child: const Text('إزالة من القسم'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomTile(Map<String, dynamic> r) {
    final id = (r['id'] ?? '').toString();
    final code = (r['code'] ?? '').toString();
    final name = (r['name'] ?? '').toString();
    final floor = r['floor'];
    final isActive = (r['is_active'] ?? r['isActive'] ?? true) == true;

    final floorText = (floor == null) ? '' : ' • طابق: ${floor.toString()}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AdminRoomBedsPage(roomId: id, roomCode: code, roomName: name),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(18),
          child: Icon(
            Icons.meeting_room_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          name.isEmpty ? (code.isEmpty ? 'غرفة' : code) : name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${code.isEmpty ? '' : code}$floorText',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusPill(isActive ? 'ACTIVE' : 'INACTIVE'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String text) {
    final theme = Theme.of(context);
    final isOk = text == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isOk ? theme.colorScheme.primary : theme.colorScheme.error)
              .withAlpha(60),
        ),
        color: (isOk ? theme.colorScheme.primary : theme.colorScheme.error)
            .withAlpha(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: isOk ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _miniError(String msg, {required VoidCallback onRetry}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(60)),
        color: theme.colorScheme.error.withAlpha(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
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

  void _showBusySnack(String msg) {
    if (!_alive) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  void _showOkSnack(String msg) {
    if (!_alive) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showErrSnack(String msg) {
    if (!_alive) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
