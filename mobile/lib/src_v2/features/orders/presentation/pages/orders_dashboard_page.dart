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
  final _api = const OrdersApiService();
  final _admissionId = TextEditingController();
  final _patientId = TextEditingController();

  String _kind = 'ALL'; // ALL | MEDICATION | LAB | PROCEDURE
  String _status =
      'ALL'; // ALL | CREATED | PARTIALLY_COMPLETED | COMPLETED | OUT_OF_STOCK | CANCELLED | IN_PROGRESS

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
    _admissionId.dispose();
    _patientId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _api.listOrders(
        admissionId: _admissionId.text.trim().isEmpty
            ? null
            : _admissionId.text.trim(),
        patientId: _patientId.text.trim().isEmpty
            ? null
            : _patientId.text.trim(),
        kind: _kind == 'ALL' ? null : _kind,
        status: _status == 'ALL' ? null : _status,
        limit: 50,
        offset: 0,
      );

      final itemsAny = raw['items'];
      final items = (itemsAny is List)
          ? itemsAny.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

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
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _admissionId,
                  decoration: InputDecoration(
                    labelText: 'Admission ID (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _patientId,
                  decoration: InputDecoration(
                    labelText: 'Patient ID (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _dropdown(
                  context,
                  label: 'Kind',
                  value: _kind,
                  items: const ['ALL', 'MEDICATION', 'LAB', 'PROCEDURE'],
                  onChanged: (v) => setState(() => _kind = v),
                ),
                const SizedBox(height: 10),

                _dropdown(
                  context,
                  label: 'Status',
                  value: _status,
                  items: const [
                    'ALL',
                    'CREATED',
                    'IN_PROGRESS',
                    'PARTIALLY_COMPLETED',
                    'COMPLETED',
                    'OUT_OF_STOCK',
                    'CANCELLED',
                  ],
                  onChanged: (v) => setState(() => _status = v),
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

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip(context, 'CREATED', _countBy('CREATED')),
              _statChip(
                context,
                'PARTIALLY_COMPLETED',
                _countBy('PARTIALLY_COMPLETED'),
              ),
              _statChip(context, 'COMPLETED', _countBy('COMPLETED')),
              _statChip(context, 'OUT_OF_STOCK', _countBy('OUT_OF_STOCK')),
              _statChip(context, 'CANCELLED', _countBy('CANCELLED')),
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
    final id = (o['id'] ?? '').toString();
    final kind = (o['kind'] ?? '').toString();
    final status = (o['status'] ?? '').toString();
    final payload = (o['payload'] is Map)
        ? (o['payload'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    String title = id;
    if (kind == 'MEDICATION') title = 'MED: ${payload['medicationName'] ?? ''}';
    if (kind == 'LAB') title = 'LAB: ${payload['testName'] ?? ''}';
    if (kind == 'PROCEDURE') title = 'PROC: ${payload['procedureName'] ?? ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('Kind: $kind\nStatus: $status'),
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
