import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/src/l10n/app_localizations.dart';
import 'package:mobile/src_v2/features/orders/data/services/orders_api_service.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _api = const OrdersApiService();

  String? _patientId;
  String? _patientLabel;

  String? _assigneeId;
  String? _assigneeLabel;

  String _target = 'NURSE';
  String _priority = 'NORMAL';

  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.orders_create)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) ...[
            _errorBox(_error!),
            const SizedBox(height: 10),
          ],

          _pickerTile(
            label: t.orders_pick_patient,
            value: _patientLabel,
            onPick: () async {
              final picked = await _pickFromLookup(
                title: t.orders_pick_patient,
                searchHint: t.orders_search_patient_hint,
                loader: (q) => _api.lookupPatients(q: q),
              );
              if (picked == null) return;

              setState(() {
                _patientId = (picked['id'] ?? '').toString();
                _patientLabel = _labelOfPicked(picked);
              });
            },
          ),
          const SizedBox(height: 10),

          _pickerTile(
            label: t.orders_pick_assignee,
            value: _assigneeLabel,
            onPick: () async {
              final picked = await _pickFromLookup(
                title: t.orders_pick_assignee,
                searchHint: t.orders_pick_assignee_hint,
                loader: (q) => _api.lookupStaff(role: _target, q: q),
              );
              if (picked == null) return;

              setState(() {
                _assigneeId = (picked['id'] ?? '').toString();
                _assigneeLabel = _labelOfPicked(picked);
              });
            },
          ),
          const SizedBox(height: 10),

          _dropdown(
            label: t.orders_target,
            value: _target,
            items: const ['NURSE', 'LAB', 'PHARMACY'],
            onChanged: (v) {
              // ✅ مهم: عند تغيير target صفّر اختيار الموظف لأن القائمة تتغير
              setState(() {
                _target = v;
                _assigneeId = null;
                _assigneeLabel = null;
              });
            },
          ),
          const SizedBox(height: 10),

          _dropdown(
            label: t.orders_priority,
            value: _priority,
            items: const ['NORMAL', 'URGENT', 'STAT'],
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: t.orders_notes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_saving ? t.orders_sending : t.orders_submit),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);

    if (_patientId == null || _patientId!.isEmpty) {
      setState(() => _error = t.orders_patient_required);
      return;
    }
    if (_assigneeId == null || _assigneeId!.isEmpty) {
      setState(() => _error = t.orders_assignee_required);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _api.createOrder(
        patientId: _patientId!,
        assigneeUserId: _assigneeId!,
        target: _target,
        priority: _priority,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.orders_create_done)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----------------------------
  // UI helpers
  // ----------------------------

  Widget _pickerTile({
    required String label,
    required String? value,
    required VoidCallback onPick,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: Theme.of(context).colorScheme.surface,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text((value ?? '').isEmpty ? '-' : value!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onPick,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((x) => DropdownMenuItem(value: x, child: Text(x)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withAlpha(90),
        ),
      ),
      child: Text(msg),
    );
  }

  // ----------------------------
  // Picker (BottomSheet) ✅
  // ----------------------------

  String _labelOfPicked(Map<String, dynamic> it) {
    final label = (it['label'] ?? '').toString().trim();
    if (label.isNotEmpty) return label;

    final fullName = (it['fullName'] ?? it['name'] ?? '').toString().trim();
    final staffCode = (it['staffCode'] ?? '').toString().trim();
    final phone = (it['phone'] ?? '').toString().trim();
    return [
      fullName,
      if (staffCode.isNotEmpty) '($staffCode)',
      if (phone.isNotEmpty) phone,
    ].where((x) => x.trim().isNotEmpty).join(' ');
  }

  Future<Map<String, dynamic>?> _pickFromLookup({
    required String title,
    required String searchHint,
    required Future<List<Map<String, dynamic>>> Function(String q) loader,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) =>
          _LookupSheet(title: title, searchHint: searchHint, loader: loader),
    );
  }
}

class _LookupSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<Map<String, dynamic>>> Function(String q) loader;

  const _LookupSheet({
    required this.title,
    required this.searchHint,
    required this.loader,
  });

  @override
  State<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<_LookupSheet> {
  final _c = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.loader(q.trim());
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

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _load(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          top: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _load,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: widget.searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                  ? Center(child: Text(_error!, textAlign: TextAlign.center))
                  : (_items.isEmpty)
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        final label =
                            (it['label'] ?? it['fullName'] ?? it['name'] ?? '')
                                .toString();

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: theme.colorScheme.surface,
                          title: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(it),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
