// lib/src_v2/workspaces/pharmacy/presentation/pages/pages/pharmacy_order_details_page.dart
// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';

class PharmacyOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderRaw;

  const PharmacyOrderDetailsPage({super.key, required this.orderRaw});

  @override
  State<PharmacyOrderDetailsPage> createState() =>
      _PharmacyOrderDetailsPageState();
}

class _PharmacyOrderDetailsPageState extends State<PharmacyOrderDetailsPage> {
  late Map<String, dynamic> _order;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.orderRaw);
    _refreshFromServerBestEffort();
  }

  String get _orderId => (_order['id'] ?? '').toString();

  Map<String, dynamic> _payload(Map<String, dynamic> m) {
    final p = m['payload'];
    if (p is Map) return Map<String, dynamic>.from(p);
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _pharmacy(Map<String, dynamic> m) {
    final p = _payload(m);
    final ph = p['pharmacy'];
    if (ph is Map) return Map<String, dynamic>.from(ph);
    return const <String, dynamic>{};
  }

  String _patientName(Map<String, dynamic> m) {
    final v =
        m['patientName'] ??
        m['patientFullName'] ??
        m['patient']?['fullName'] ??
        m['patient']?['name'];
    return (v == null || v.toString().trim().isEmpty) ? '—' : v.toString();
  }

  String _medName(Map<String, dynamic> m) {
    final p = _payload(m);
    final v =
        m['medicationName'] ??
        m['drugName'] ??
        p['medicationName'] ??
        p['drugName'];
    return (v == null || v.toString().trim().isEmpty) ? '—' : v.toString();
  }

  Future<void> _refreshFromServerBestEffort() async {
    if (_orderId.isEmpty) return;
    try {
      final res = await ApiClient.dio.get('/api/orders/$_orderId');
      final raw = res.data;
      final m = _unwrapOne(raw);
      if (!mounted) return;
      if (m.isNotEmpty) setState(() => _order = m);
    } catch (_) {
      // keep local snapshot
    }
  }

  Map<String, dynamic> _unwrapOne(dynamic raw) {
    // Accept:
    // - { data: order }
    // - { data: { order: ... } }
    // - order itself
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);

      if (m['data'] is Map) {
        final d = Map<String, dynamic>.from(m['data'] as Map);

        // If controller returned { data: { order: ... } }
        if (d['order'] is Map)
          return Map<String, dynamic>.from(d['order'] as Map);

        return d;
      }

      return m;
    }
    return const <String, dynamic>{};
  }

  String _fmtDt(String iso) {
    final s = iso.trim();
    if (s.isEmpty) return '—';
    // Keep as-is (server ISO) to avoid locale/timezone surprises in UI
    return s;
  }

  String _fmtBool(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    final s = v.toString().trim().toLowerCase();
    if (s == 'true') return 'Yes';
    if (s == 'false') return 'No';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = _payload(_order);
    final ph = _pharmacy(_order);

    final status = (_order['status'] ?? '—').toString().trim();

    final dose = (p['dose'] ?? '').toString();
    final route = (p['route'] ?? '').toString();
    final frequency = (p['frequency'] ?? '').toString();
    final duration = (p['duration'] ?? '').toString();
    final requestedQty = p['requestedQty'];

    final instrAr = (p['patientInstructionsAr'] ?? '').toString();
    final warnings = (p['warningsText'] ?? '').toString();
    final withFood = p['withFood'];

    final preparedQty = ph['preparedQty'];
    final preparedAt = (ph['preparedAt'] ?? '').toString();
    final mode = (ph['mode'] ?? '').toString().trim();
    final notes = (ph['notes'] ?? '').toString();
    final outOfStockAt = (ph['outOfStockAt'] ?? '').toString();

    // ===== NEW LOGIC (visibility) =====
    // Completed if:
    // - status COMPLETED
    // - OR pharmacy.mode FULL
    final isCompleted = status == 'COMPLETED' || mode == 'FULL';
    final isCancelled = status == 'CANCELLED';
    final isOutOfStock = status == 'OUT_OF_STOCK' || mode == 'OUT_OF_STOCK';
    final isPartial = status == 'PARTIALLY_COMPLETED' || mode == 'PARTIAL';

    return V2ShellScaffold(
      title: 'تفاصيل طلب دواء',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          if (_error != null) _errorBox(context, _error!),
          _sectionCard(
            context,
            title: 'ملخص',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Order ID', _orderId.isEmpty ? '—' : _orderId),
                _kv('Status', status.isEmpty ? '—' : status),
                const Divider(),
                _kv('Patient', _patientName(_order)),
                _kv('Medication', _medName(_order)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _sectionCard(
            context,
            title: 'تفاصيل الجرعة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Dose', dose.isEmpty ? '—' : dose),
                _kv('Route', route.isEmpty ? '—' : route),
                _kv('Frequency', frequency.isEmpty ? '—' : frequency),
                _kv('Duration', duration.isEmpty ? '—' : duration),
                _kv(
                  'Requested Qty',
                  requestedQty == null ? '—' : requestedQty.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _sectionCard(
            context,
            title: 'تعليمات وتحذيرات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('With food', _fmtBool(withFood)),
                const SizedBox(height: 8),
                _block('Instructions (AR)', instrAr),
                const SizedBox(height: 8),
                _block('Warnings', warnings),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _sectionCard(
            context,
            title: 'حالة الصيدلية',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Mode', mode.isEmpty ? '—' : mode),
                _kv(
                  'Prepared Qty',
                  preparedQty == null ? '—' : preparedQty.toString(),
                ),
                _kv(
                  'Prepared At',
                  preparedAt.isEmpty ? '—' : _fmtDt(preparedAt),
                ),
                _kv(
                  'Out Of Stock At',
                  outOfStockAt.isEmpty ? '—' : _fmtDt(outOfStockAt),
                ),
                const SizedBox(height: 8),
                _block('Pharmacy Notes', notes),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== Actions (NEW) =====
          _sectionCard(
            context,
            title: 'إجراءات',
            child: _buildActions(
              context,
              isCompleted: isCompleted,
              isCancelled: isCancelled,
              isOutOfStock: isOutOfStock,
              isPartial: isPartial,
              preparedQty: preparedQty,
              preparedAt: preparedAt,
              outOfStockAt: outOfStockAt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context, {
    required bool isCompleted,
    required bool isCancelled,
    required bool isOutOfStock,
    required bool isPartial,
    required dynamic preparedQty,
    required String preparedAt,
    required String outOfStockAt,
  }) {
    // Priority:
    // Cancelled -> banner
    // Completed -> banner
    // OutOfStock -> banner
    // Otherwise -> buttons
    if (isCancelled) {
      return _stateBanner(
        context,
        label: 'ملغي',
        subtitle: 'لا يمكن تنفيذ أي إجراء على هذا الطلب.',
        icon: Icons.block_rounded,
      );
    }

    if (isCompleted) {
      final subtitle = [
        if (preparedQty != null) 'الكمية المحضّرة: $preparedQty',
        if (preparedAt.trim().isNotEmpty) 'وقت التحضير: ${_fmtDt(preparedAt)}',
      ].join(' | ').trim();

      return _stateBanner(
        context,
        label: 'محضّر',
        subtitle: subtitle.isEmpty ? null : subtitle,
        icon: Icons.verified_rounded,
      );
    }

    if (isOutOfStock) {
      final subtitle = outOfStockAt.trim().isEmpty
          ? 'تم تعليم الطلب كغير متوفر.'
          : 'غير متوفر منذ: ${_fmtDt(outOfStockAt)}';

      return _stateBanner(
        context,
        label: 'غير متوفر',
        subtitle: subtitle,
        icon: Icons.warning_amber_rounded,
      );
    }

    // If partial: you can choose to hide "partial" button.
    // This implementation keeps both buttons unless you prefer otherwise.
    // If you want: hide partial when already partial -> set allowPartial = !isPartial
    final allowPartial = !isPartial;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (_loading || _orderId.isEmpty) ? null : _actPrepare,
                child: const Text('تحضير كامل'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: (!allowPartial || _loading || _orderId.isEmpty)
                    ? null
                    : _actPartial,
                child: const Text('تحضير جزئي'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: (_loading || _orderId.isEmpty) ? null : _actOutOfStock,
            child: const Text('غير متوفر'),
          ),
        ),
        if (_loading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _stateBanner(
    BuildContext context, {
    required String label,
    String? subtitle,
    IconData icon = Icons.info_outline_rounded,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withAlpha(60)),
        color: theme.colorScheme.primary.withAlpha(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle.trim(), style: TextStyle(color: theme.hintColor)),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _block(String title, String text) {
    final t = text.trim().isEmpty ? '—' : text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(t),
      ],
    );
  }

  Widget _errorBox(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }

  Future<String?> _askNotes({required String title}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'ملاحظة (اختياري)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    return ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
  }

  Future<void> _actPrepare() async {
    final notes = await _askNotes(title: 'تحضير كامل');
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.dio.post(
        '/api/orders/$_orderId/pharmacy/prepare',
        data: {'notes': notes},
      );

      final m = _unwrapOne(res.data);
      if (m.isNotEmpty) setState(() => _order = m);

      await _refreshFromServerBestEffort();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التحضير بالكامل')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _actOutOfStock() async {
    final notes = await _askNotes(title: 'غير متوفر');
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.dio.post(
        '/api/orders/$_orderId/pharmacy/out-of-stock',
        data: {'notes': notes},
      );

      final m = _unwrapOne(res.data);
      if (m.isNotEmpty) setState(() => _order = m);

      await _refreshFromServerBestEffort();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعليم الطلب: غير متوفر')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _actPartial() async {
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحضير جزئي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prepared Qty'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final preparedQty = num.tryParse(qtyCtrl.text.trim());
    if (preparedQty == null || preparedQty <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prepared Qty غير صحيح')));
      return;
    }

    final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.dio.post(
        '/api/orders/$_orderId/pharmacy/partial',
        data: {'preparedQty': preparedQty, 'notes': notes},
      );

      final m = _unwrapOne(res.data);
      if (m.isNotEmpty) setState(() => _order = m);

      await _refreshFromServerBestEffort();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التحضير الجزئي')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }
}
