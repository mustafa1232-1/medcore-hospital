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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final o = await _api.getOrder(widget.orderId);
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
            _kv('ID', widget.orderId),
            _kv(
              'code',
              (_order?['code'] ?? _order?['orderCode'] ?? '').toString(),
            ),
            _kv('status', (_order?['status'] ?? '').toString()),
            _kv(t.orders_patient, (_order?['patientName'] ?? '').toString()),
            _kv(
              t.orders_room_bed,
              '${_order?['roomCode'] ?? ''} / ${_order?['bedCode'] ?? ''}',
            ),
            _kv(t.orders_from_doctor, (_order?['fromName'] ?? '').toString()),
            _kv(t.orders_to, (_order?['toName'] ?? '').toString()),
            _kv(t.orders_priority, (_order?['priority'] ?? '').toString()),
            _kv(t.orders_notes, (_order?['notes'] ?? '').toString()),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final reason = await _askReason(
                      context,
                      t.orders_reason_optional,
                    );
                    try {
                      await _api.pingOrder(widget.orderId, reason: reason);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.orders_ping_done)),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(t.orders_ping),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final reason = await _askReason(
                      context,
                      t.orders_reason_optional,
                    );
                    try {
                      await _api.escalateOrder(widget.orderId, reason: reason);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.orders_escalate_done)),
                      );
                      _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  icon: const Icon(Icons.priority_high_rounded),
                  label: Text(t.orders_escalate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(40),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(v.isEmpty ? '-' : v),
          ],
        ),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context, String title) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).common_cancel),
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
