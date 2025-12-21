// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'tasks_api_service.dart';

class MyTasksPage extends StatefulWidget {
  static const routeName = '/tasks/my';
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final _api = TasksApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  String? _status; // null = default (PENDING/STARTED)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.listMyTasks(status: _status);
      setState(() => _items = (res['items'] as List<dynamic>? ?? []));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _start(String id) async {
    try {
      await _api.startTask(id);
      await _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _complete(String id) async {
    final note = await _askNote();
    if (note == null) return;

    try {
      await _api.completeTask(
        id,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      await _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _askNote() async {
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملاحظة (اختياري)'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظة...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    c.dispose();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مهامي'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('الافتراضي (PENDING/STARTED)'),
                ),
                DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                DropdownMenuItem(value: 'STARTED', child: Text('STARTED')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
              ],
              onChanged: (v) => setState(() => _status = v),
              decoration: const InputDecoration(labelText: 'فلتر الحالة'),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _items.isEmpty
                ? const Center(child: Text('لا توجد مهام'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = _items[i] as Map<String, dynamic>;
                      final id = t['id']?.toString() ?? '';
                      final title = t['title']?.toString() ?? '';
                      final details = t['details']?.toString();
                      final status = t['status']?.toString() ?? '';

                      final canStart = status == 'PENDING';
                      final canComplete =
                          status == 'PENDING' || status == 'STARTED';

                      return ListTile(
                        title: Text(title),
                        subtitle: Text(
                          [
                            'status: $status',
                            if (details != null && details.trim().isNotEmpty)
                              details,
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (canStart)
                              OutlinedButton(
                                onPressed: () => _start(id),
                                child: const Text('Start'),
                              ),
                            if (canComplete)
                              FilledButton(
                                onPressed: () => _complete(id),
                                child: const Text('Complete'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
