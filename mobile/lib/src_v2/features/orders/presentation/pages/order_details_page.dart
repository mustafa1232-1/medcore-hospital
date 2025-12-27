// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:mobile/src/l10n/app_localizations.dart';
import 'package:mobile/src_v2/features/orders/data/services/orders_api_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _api = const OrdersApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _pickOrder(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map) return data.cast<String, dynamic>();
    return raw;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _api.getOrderById(id: widget.orderId);
      final o = _pickOrder(raw);
      if (!mounted) return;
      setState(() {
        _order = o;
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
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.orders_details_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(t.common_retry),
                  ),
                ],
              ),
            )
          else ...[
            _detailsCard(),
            const SizedBox(height: 14),
            _actionsCard(),
          ],
        ],
      ),
    );
  }

  Widget _detailsCard() {
    final o = _order ?? {};
    final payload = (o['payload'] is Map)
        ? (o['payload'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final kind = (o['kind'] ?? '').toString();
    final status = (o['status'] ?? '').toString();

    String title = 'Order';
    if (kind == 'MEDICATION')
      title = 'طلب دواء: ${payload['medicationName'] ?? ''}';
    if (kind == 'LAB') title = 'طلب تحليل: ${payload['testName'] ?? ''}';
    if (kind == 'PROCEDURE')
      title = 'طلب إجراء: ${payload['procedureName'] ?? ''}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          _kv('ID', (o['id'] ?? '').toString()),
          _kv('Kind', kind),
          _kv('Status', status),
          _kv('Admission', (o['admissionId'] ?? '').toString()),
          _kv('Patient', (o['patientId'] ?? '').toString()),
          _kv('Notes', (o['notes'] ?? '').toString()),

          const Divider(height: 18),

          if (kind == 'MEDICATION') ...[
            _kv('Dose', (payload['dose'] ?? '').toString()),
            _kv('Route', (payload['route'] ?? '').toString()),
            _kv('Frequency', (payload['frequency'] ?? '').toString()),
            _kv('Duration', (payload['duration'] ?? '').toString()),
            _kv('Requested Qty', (payload['requestedQty'] ?? '').toString()),
            _kv('With Food', (payload['withFood'] ?? '').toString()),
          ],
          if (kind == 'LAB') ...[
            _kv('Priority', (payload['priority'] ?? '').toString()),
            _kv('Specimen', (payload['specimen'] ?? '').toString()),
          ],
          if (kind == 'PROCEDURE') ...[
            _kv('Urgency', (payload['urgency'] ?? '').toString()),
          ],
        ],
      ),
    );
  }

  Widget _actionsCard() {
    final t = AppLocalizations.of(context);
    final o = _order ?? {};
    final kind = (o['kind'] ?? '').toString();
    final status = (o['status'] ?? '').toString();

    final canCancel = status != 'CANCELLED' && status != 'COMPLETED';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          // Doctor: cancel
          FilledButton.icon(
            onPressed: canCancel
                ? () async {
                    final reason = await _askText(
                      context,
                      'سبب الإلغاء (اختياري)',
                    );
                    try {
                      await _api.cancelOrder(id: widget.orderId, notes: reason);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إلغاء الطلب')),
                      );
                      _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                : null,
            icon: const Icon(Icons.cancel_rounded),
            label: Text(t.common_cancel),
          ),

          const SizedBox(height: 10),

          if (kind == 'MEDICATION') ...[
            const Text(
              'Pharmacy',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () async {
                final notes = await _askText(context, 'ملاحظة (اختياري)');
                try {
                  await _api.pharmacyPrepare(
                    orderId: widget.orderId,
                    notes: notes,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تجهيز الطلب بالكامل')),
                  );
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Prepare (Full)'),
            ),

            OutlinedButton.icon(
              onPressed: () async {
                final qtyStr = await _askText(
                  context,
                  'الكمية المجهزة (مطلوب)',
                );
                final qty = num.tryParse((qtyStr ?? '').trim());
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الكمية غير صحيحة')),
                  );
                  return;
                }
                final notes = await _askText(context, 'ملاحظة (اختياري)');
                try {
                  await _api.pharmacyPartial(
                    orderId: widget.orderId,
                    preparedQty: qty,
                    notes: notes,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تجهيز الطلب جزئياً')),
                  );
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text('Partial'),
            ),

            OutlinedButton.icon(
              onPressed: () async {
                final notes = await _askText(context, 'ملاحظة (اختياري)');
                try {
                  await _api.pharmacyOutOfStock(
                    orderId: widget.orderId,
                    notes: notes,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم وضع الطلب: Out of stock')),
                  );
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Out of stock'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }

  Future<String?> _askText(BuildContext context, String title) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    final v = (ok == true) ? c.text.trim() : null;
    c.dispose();
    return (v != null && v.isEmpty) ? null : v;
  }
}
