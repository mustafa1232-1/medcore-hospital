import 'package:flutter/material.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../orders/data/api/rooms_api_service_v2.dart';
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
  final _q = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rooms = const [];

  bool _onlyActive = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
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

      if (!mounted) return;
      setState(() {
        _rooms = items;
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
    final title = (widget.departmentName?.trim().isNotEmpty ?? false)
        ? (widget.departmentName!.trim())
        : 'تفاصيل القسم';

    return V2ShellScaffold(
      title: title,
      actions: [
        IconButton(
          onPressed: _loadRooms,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _headerCard(context),

            const SizedBox(height: 12),

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
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(_error!, onRetry: _loadRooms)
            else if (_rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
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
              Icons.meeting_room_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'غرف القسم',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  code.isEmpty
                      ? 'اضغط على الغرفة لعرض الأسرة'
                      : '($code) اضغط على الغرفة لعرض الأسرة',
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
          '${code.isEmpty ? '' : code}${floorText}',
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
