// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

class PharmacyStockRequestEditorPage extends StatefulWidget {
  final String? requestId; // null => create new

  const PharmacyStockRequestEditorPage({super.key, this.requestId});

  @override
  State<PharmacyStockRequestEditorPage> createState() =>
      _PharmacyStockRequestEditorPageState();
}

class _PharmacyStockRequestEditorPageState
    extends State<PharmacyStockRequestEditorPage> {
  final _api = PharmacyApiService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _req;
  List<Map<String, dynamic>> _lines = const [];

  // Create form
  String _kind = 'RECEIPT';
  String? _warehouseId;

  // Add line form
  final _qtyCtrl = TextEditingController(text: '1');
  String? _drugId;
  List<Map<String, dynamic>> _drugs = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  bool get _isDraft {
    final s = (_req?['status'] ?? 'DRAFT').toString().trim().toUpperCase();
    return s == 'DRAFT';
  }

  String get _reqId => (_req?['id'] ?? '').toString();

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Warehouses (PHARMACY)
      final whs = await _api.listWarehouses(
        limit: 10,
        offset: 0,
        activeOnly: true,
      );
      if (whs.isEmpty) {
        throw Exception(
          'لا يوجد Warehouse. اطلب من الإدارة إنشاء Warehouse أولاً.',
        );
      }

      final firstWhId = (whs.first['id'] ?? '').toString().trim();
      if (firstWhId.isEmpty) {
        throw Exception('Warehouse غير صالح (id فارغ).');
      }
      _warehouseId = firstWhId;

      // Drugs list
      _drugs = await _api.listDrugs(limit: 200, offset: 0, activeOnly: true);
      if (_drugs.isNotEmpty) _drugId = (_drugs.first['id'] ?? '').toString();

      // If we have requestId => load existing
      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
        await _loadExisting(widget.requestId!);
      } else {
        // If already created in memory (e.g. hot reload), don't recreate
        if (_req == null) await _createDraft();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      final out = <String, dynamic>{};
      v.forEach((k, val) => out['$k'] = val);
      return out;
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map(_asMap).toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _loadExisting(String id) async {
    final details = await _api.getStockRequestDetails(id);
    _req = _asMap(details);

    _lines = _asListOfMap(details['lines']);
    _kind = (details['kind'] ?? _kind).toString();
  }

  Future<void> _createDraft() async {
    final whId = (_warehouseId ?? '').toString().trim();
    if (whId.isEmpty) throw Exception('WarehouseId فارغ. لا يمكن إنشاء Draft.');

    // Rules from backend:
    // RECEIPT/ADJUSTMENT_IN/RETURN => toWarehouseId required
    // DISPENSE/WASTE/ADJUSTMENT_OUT => fromWarehouseId required
    // TRANSFER_* => from + to required (لاحقاً)
    final created = await _api.createStockRequest(
      kind: _kind,
      toWarehouseId:
          (_kind == 'RECEIPT' || _kind == 'ADJUSTMENT_IN' || _kind == 'RETURN')
          ? whId
          : null,
      fromWarehouseId:
          (_kind == 'DISPENSE' || _kind == 'WASTE' || _kind == 'ADJUSTMENT_OUT')
          ? whId
          : null,
    );

    _req = _asMap(created);
    _lines = const [];
  }

  Future<void> _addLine() async {
    if (_req == null) return;

    if (!_isDraft) {
      setState(() => _error = 'لا يمكن تعديل الطلب لأنه ليس DRAFT.');
      return;
    }

    if (_drugId == null || _drugId!.isEmpty) {
      setState(() => _error = 'اختر دواء أولاً.');
      return;
    }

    final qty = num.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'الكمية يجب أن تكون أكبر من صفر.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _api.addStockRequestLine(
        requestId: _reqId,
        drugId: _drugId!,
        qty: qty,
      );

      await _loadExisting(_reqId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDelete() async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد حذف هذا السطر؟ لا يمكن التراجع.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _deleteLine(String lineId) async {
    if (_req == null) return;

    if (!_isDraft) {
      setState(() => _error = 'لا يمكن تعديل الطلب لأنه ليس DRAFT.');
      return;
    }

    final ok = await _confirmDelete();
    if (!ok) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _api.deleteStockRequestLine(requestId: _reqId, lineId: lineId);

      await _loadExisting(_reqId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_req == null) return;

    if (!_isDraft) {
      setState(() => _error = 'هذا الطلب ليس DRAFT، لا يمكن Submit.');
      return;
    }

    if (_lines.isEmpty) {
      setState(() => _error = 'لا يمكن Submit بدون أدوية (Lines).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _api.submitStockRequest(requestId: _reqId);
      if (!mounted) return;
      Navigator.of(context).pop(true); // changed
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final id = _reqId;
    if (id.isEmpty) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await _loadExisting(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _drugLabel(Map<String, dynamic> d) {
    final name = (d['name'] ?? d['genericName'] ?? d['label'] ?? '—')
        .toString()
        .trim();
    final code = (d['code'] ?? d['sku'] ?? '').toString().trim();
    return code.isEmpty ? name : '$name • $code';
  }

  String _drugNameById(String drugId) {
    for (final d in _drugs) {
      final id = (d['id'] ?? '').toString();
      if (id == drugId) return _drugLabel(d);
    }
    return 'drugId: $drugId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final reqId = (_req?['id'] ?? '—').toString();
    final status = (_req?['status'] ?? 'DRAFT').toString();
    final kind = (_req?['kind'] ?? _kind).toString();

    return V2ShellScaffold(
      title: widget.requestId == null ? 'إنشاء طلب (Draft)' : 'تفاصيل الطلب',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _loading || _busy ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _req == null
            ? _ErrorState(message: _error!, onRetry: _bootstrap)
            : RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: theme.colorScheme.error.withAlpha(12),
                              border: Border.all(
                                color: theme.colorScheme.error.withAlpha(70),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.dividerColor.withAlpha(45),
                            ),
                            color: theme.colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primary
                                    .withAlpha(18),
                                child: Icon(
                                  Icons.assignment_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request ID: $reqId',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: $status • Kind: $kind',
                                      style: TextStyle(
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withAlpha(180),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (!_isDraft) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'هذا الطلب للعرض فقط (غير قابل للتعديل).',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withAlpha(160),
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Add line (Draft فقط) - hidden if not draft
                        if (_isDraft) ...[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: theme.dividerColor.withAlpha(45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'إضافة دواء',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: _drugId,
                                    items: _drugs.map((d) {
                                      final id = (d['id'] ?? '').toString();
                                      return DropdownMenuItem(
                                        value: id,
                                        child: Text(
                                          _drugLabel(d),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _busy
                                        ? null
                                        : (v) {
                                            setState(() => _drugId = v);
                                          },
                                    decoration: InputDecoration(
                                      labelText: 'الدواء',
                                      prefixIcon: const Icon(
                                        Icons.medication_rounded,
                                      ),
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    enabled: !_busy,
                                    decoration: InputDecoration(
                                      labelText: 'الكمية',
                                      prefixIcon: const Icon(
                                        Icons.numbers_rounded,
                                      ),
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _busy ? null : _addLine,
                                    icon: _busy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.add_rounded),
                                    label: Text(
                                      _busy ? 'جارٍ الإضافة...' : 'إضافة',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Lines
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: theme.dividerColor.withAlpha(45),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الأدوية داخل الطلب',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_lines.isEmpty)
                                  Text(
                                    'لا يوجد Lines بعد.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withAlpha(180),
                                    ),
                                  )
                                else
                                  ..._lines.map((ln) {
                                    final m = _asMap(ln);
                                    final lineId = (m['id'] ?? '').toString();
                                    final drugId = (m['drugId'] ?? '')
                                        .toString();
                                    final qty = (m['qty'] ?? '').toString();

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: theme.dividerColor.withAlpha(
                                            45,
                                          ),
                                        ),
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withAlpha(60),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.medication_rounded),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _drugNameById(drugId),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Qty: $qty • Line: $lineId',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color
                                                            ?.withAlpha(180),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_isDraft)
                                            IconButton(
                                              tooltip: 'حذف',
                                              onPressed: (_busy)
                                                  ? null
                                                  : () => _deleteLine(lineId),
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 6),

                                // Submit (Draft only)
                                if (_isDraft)
                                  FilledButton.icon(
                                    onPressed: (_busy) ? null : _submit,
                                    icon: const Icon(Icons.send_rounded),
                                    label: const Text('Submit إلى الإدارة'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withAlpha(45)),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                'تعذر فتح الطلب',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
