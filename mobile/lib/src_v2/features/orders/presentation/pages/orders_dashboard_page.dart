import 'package:flutter/material.dart';
import 'package:mobile/src_v2/features/orders/data/services/orders_api_service.dart';
import '../../../../../src/l10n/app_localizations.dart';
import 'order_details_page.dart';

class OrdersDashboardPage extends StatefulWidget {
  const OrdersDashboardPage({super.key});

  @override
  State<OrdersDashboardPage> createState() => _OrdersDashboardPageState();
}

class _OrdersDashboardPageState extends State<OrdersDashboardPage> {
  final _api = OrdersApiService();
  final _search = TextEditingController();

  String _status = 'ALL';
  String _target = 'ALL';
  String _priority = 'ALL';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.listOrders(
        q: _search.text,
        status: _status,
        target: _target,
        priority: _priority,
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

  int _countBy(String s) =>
      _items.where((e) => (e['status']?.toString() ?? '') == s).length;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          // Search
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: t.orders_search_hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filters Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withAlpha(40)),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.staff_apply, // “تطبيق”
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _dropdown(
                  context,
                  label: 'Status',
                  value: _status,
                  items: const ['ALL', 'PENDING', 'STARTED', 'COMPLETED'],
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 10),
                _dropdown(
                  context,
                  label: t.orders_target,
                  value: _target,
                  items: const ['ALL', 'NURSE', 'LAB', 'PHARMACY'],
                  onChanged: (v) => setState(() => _target = v),
                ),
                const SizedBox(height: 10),
                _dropdown(
                  context,
                  label: t.orders_priority,
                  value: _priority,
                  items: const ['ALL', 'NORMAL', 'URGENT', 'STAT'],
                  onChanged: (v) => setState(() => _priority = v),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: Text(t.common_apply),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Summary chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip(context, 'PENDING', _countBy('PENDING')),
              _statChip(context, 'STARTED', _countBy('STARTED')),
              _statChip(context, 'COMPLETED', _countBy('COMPLETED')),
            ],
          ),

          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorBox(context, _error!, onRetry: _load)
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Center(child: Text(t.orders_no_results)),
            )
          else
            ..._items.map((e) => _orderTile(context, e)),
        ],
      ),
    );
  }

  Widget _dropdown(
    BuildContext context, {
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
              .map((x) => DropdownMenuItem<String>(value: x, child: Text(x)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, int count) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 10),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(BuildContext context, Map<String, dynamic> o) {
    final t = AppLocalizations.of(context);

    final id = (o['id'] ?? '').toString();
    final code = (o['code'] ?? o['orderCode'] ?? '').toString();
    final status = (o['status'] ?? '').toString();
    final patient = (o['patientName'] ?? o['patient'] ?? '').toString();
    final room = (o['roomCode'] ?? o['room'] ?? '').toString();
    final bed = (o['bedCode'] ?? o['bed'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(
          code.isNotEmpty ? code : id,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (patient.isNotEmpty) '${t.orders_patient}: $patient',
            if (room.isNotEmpty || bed.isNotEmpty)
              '${t.orders_room_bed}: $room / $bed',
            if (status.isNotEmpty) 'status: $status',
          ].join('\n'),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: id)),
          );
          _load();
        },
      ),
    );
  }

  Widget _errorBox(
    BuildContext context,
    String error, {
    required VoidCallback onRetry,
  }) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
