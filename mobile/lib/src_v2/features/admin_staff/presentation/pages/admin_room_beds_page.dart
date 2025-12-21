import 'package:flutter/material.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../orders/data/api/beds_api_service_v2.dart';

class AdminRoomBedsPage extends StatefulWidget {
  final String roomId;
  final String? roomCode;
  final String? roomName;

  const AdminRoomBedsPage({
    super.key,
    required this.roomId,
    this.roomCode,
    this.roomName,
  });

  @override
  State<AdminRoomBedsPage> createState() => _AdminRoomBedsPageState();
}

class _AdminRoomBedsPageState extends State<AdminRoomBedsPage> {
  final _bedsApi = BedsApiServiceV2();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _beds = const [];

  @override
  void initState() {
    super.initState();
    _loadBeds();
  }

  Future<void> _loadBeds() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _bedsApi.listBeds(
        roomId: widget.roomId,
        active: true,
      );
      if (!mounted) return;
      setState(() {
        _beds = items;
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
    final header = (widget.roomName?.trim().isNotEmpty ?? false)
        ? widget.roomName!.trim()
        : (widget.roomCode?.trim().isNotEmpty ?? false)
        ? widget.roomCode!.trim()
        : 'الأسرة';

    return V2ShellScaffold(
      title: header,
      actions: [
        IconButton(
          onPressed: _loadBeds,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadBeds,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _headerCard(context),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(_error!, onRetry: _loadBeds)
            else if (_beds.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('لا توجد أسرة')),
              )
            else
              ..._beds.map(_bedTile),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final roomCode = (widget.roomCode ?? '').trim();

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
            child: Icon(Icons.bed_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أسرة الغرفة',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  roomCode.isEmpty
                      ? 'عرض حالة كل سرير'
                      : '($roomCode) عرض حالة كل سرير',
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

  Widget _bedTile(Map<String, dynamic> b) {
    final code = (b['code'] ?? '').toString();
    final status = (b['status'] ?? '').toString(); // AVAILABLE/OCCUPIED/...
    final notes = (b['notes'] ?? '').toString();
    final isActive = (b['is_active'] ?? b['isActive'] ?? true) == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(18),
          child: Icon(
            Icons.bed_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          code.isEmpty ? 'Bed' : code,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          notes.isEmpty
              ? _statusLabel(status)
              : '${_statusLabel(status)} • $notes',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _statusChip(status, isActive: isActive),
      ),
    );
  }

  String _statusLabel(String s) {
    final v = s.toUpperCase().trim();
    if (v.isEmpty) return '—';
    switch (v) {
      case 'AVAILABLE':
        return 'متاح';
      case 'OCCUPIED':
        return 'مشغول';
      case 'CLEANING':
        return 'تنظيف';
      case 'MAINTENANCE':
        return 'صيانة';
      case 'RESERVED':
        return 'محجوز';
      case 'OUT_OF_SERVICE':
        return 'خارج الخدمة';
      default:
        return v;
    }
  }

  Widget _statusChip(String status, {required bool isActive}) {
    final theme = Theme.of(context);
    final s = status.toUpperCase().trim();

    Color border;
    Color fill;
    Color text;

    // بدون تحديد ألوان ثابتة "غريبة" — نعتمد على primary/error مع شفافية
    if (!isActive) {
      border = theme.colorScheme.error.withAlpha(70);
      fill = theme.colorScheme.error.withAlpha(10);
      text = theme.colorScheme.error;
    } else if (s == 'OCCUPIED') {
      border = theme.colorScheme.error.withAlpha(70);
      fill = theme.colorScheme.error.withAlpha(10);
      text = theme.colorScheme.error;
    } else {
      border = theme.colorScheme.primary.withAlpha(70);
      fill = theme.colorScheme.primary.withAlpha(10);
      text = theme.colorScheme.primary;
    }

    final label = !isActive ? 'INACTIVE' : (s.isEmpty ? '—' : s);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: text,
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
