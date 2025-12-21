import 'package:flutter/material.dart';

import '../../../../core/shell/v2_shell_scaffold.dart';
import '../../../orders/data/api/departments_api_service_v2.dart';

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

class _AdminDepartmentDetailsPageState extends State<AdminDepartmentDetailsPage>
    with SingleTickerProviderStateMixin {
  final _api = DepartmentsApiServiceV2();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _data;

  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getDepartmentOverview(widget.departmentId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

    final title = widget.departmentName?.trim().isNotEmpty == true
        ? widget.departmentName!.trim()
        : 'تفاصيل القسم';

    return V2ShellScaffold(
      title: title,
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث',
        ),
      ],
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(icon: Icon(Icons.groups_2_rounded), text: 'الكادر'),
                Tab(icon: Icon(Icons.bed_rounded), text: 'الغرف والأسرة'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      children: [
                        SizedBox(height: 160),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : (_error != null)
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [_ErrorBox(msg: _error!, onRetry: _load)],
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _StaffTab(data: _data ?? const {}),
                        _RoomsBedsTab(data: _data ?? const {}),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StaffTab({required this.data});

  List<Map<String, dynamic>> _asList(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final staff = (data['staff'] is Map)
        ? (data['staff'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final doctors = _asList(staff['doctors']);
    final nurses = _asList(staff['nurses']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      children: [
        _section('الأطباء', doctors, icon: Icons.medical_services_rounded),
        const SizedBox(height: 12),
        _section('التمريض', nurses, icon: Icons.health_and_safety_rounded),
      ],
    );
  }

  Widget _section(
    String title,
    List<Map<String, dynamic>> items, {
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Icon(icon, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('لا يوجد'),
              )
            else
              ...items.map((u) {
                final fullName = (u['fullName'] ?? '').toString();
                final staffCode = (u['staffCode'] ?? '').toString();
                final phone = (u['phone'] ?? '').toString();
                final email = (u['email'] ?? '').toString();

                final sub = staffCode.isNotEmpty
                    ? staffCode
                    : (phone.isNotEmpty ? phone : email);

                return ListTile(
                  dense: true,
                  title: Text(
                    fullName.isEmpty ? '-' : fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(sub),
                  leading: const Icon(Icons.person_rounded),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _RoomsBedsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RoomsBedsTab({required this.data});

  List<Map<String, dynamic>> _asList(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _asList(data['rooms']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      children: [
        if (rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('لا توجد غرف/أسرة لهذا القسم')),
          )
        else
          ...rooms.map((r) => _roomCard(context, r)).toList(),
      ],
    );
  }

  Widget _roomCard(BuildContext context, Map<String, dynamic> r) {
    final theme = Theme.of(context);

    final code = (r['code'] ?? '').toString();
    final name = (r['name'] ?? '').toString();
    final floor = r['floor'];

    final beds = _asList(r['beds']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name.isNotEmpty
                        ? '$name  (${code.isEmpty ? '-' : code})'
                        : (code.isEmpty ? 'Room' : code),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (floor != null) Text('طابق: $floor'),
              ],
            ),
            const SizedBox(height: 10),
            ...beds.map((b) {
              final bedCode = (b['code'] ?? '').toString();
              final status = (b['status'] ?? '').toString();

              final occupant = (b['occupant'] is Map)
                  ? (b['occupant'] as Map).cast<String, dynamic>()
                  : null;
              final patientName =
                  occupant?['patientFullName']?.toString() ?? '';
              final patientPhone = occupant?['patientPhone']?.toString() ?? '';

              final hasPatient =
                  occupant != null && patientName.trim().isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bed_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bedCode.isEmpty ? '-' : bedCode,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasPatient
                                ? (patientPhone.isNotEmpty
                                      ? '$patientName — $patientPhone'
                                      : patientName)
                                : 'لا يوجد مريض على السرير',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusChip(status),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.trim().isEmpty ? '—' : status.trim();
    return Chip(
      label: Text(s, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorBox({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
    );
  }
}
