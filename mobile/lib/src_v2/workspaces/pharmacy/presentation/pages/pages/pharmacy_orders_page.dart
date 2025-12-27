// lib/src_v2/workspaces/pharmacy/presentation/pages/pages/pharmacy_orders_page.dart
// ignore_for_file: use_build_context_synchronously, prefer_final_fields, unnecessary_underscores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/presentation/pages/pages/pharmacy_order_details_page.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _items = [];
  int _limit = 25;
  int _offset = 0;
  int _total = 0;
  bool _hasMore = true;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void initState() {
    super.initState();

    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _load(reset: true);
    });

    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        final v = _searchCtrl.text.trim();
        if (v == _search) return;
        setState(() => _search = v);
        _load(reset: true);
      });
    });

    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  String _statusForTab(int idx) {
    switch (idx) {
      case 0:
        return 'CREATED';
      case 1:
        return 'PARTIALLY_COMPLETED';
      case 2:
        return 'OUT_OF_STOCK';
      case 3:
        return 'COMPLETED';
      default:
        return 'CREATED';
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _offset = 0;
        _total = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final status = _statusForTab(_tabs.index);

      final res = await ApiClient.dio.get(
        '/api/orders',
        queryParameters: {
          'kind': 'MEDICATION',
          'status': status,
          'limit': _limit,
          'offset': _offset,
          // Optional: if you implement search on backend later
          // 'q': _search,
        },
      );

      final data = _unwrapList(res.data);

      final itemsRaw = data['items'] is List
          ? (data['items'] as List)
          : const [];
      final items = itemsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final meta = data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'])
          : <String, dynamic>{};
      final total = (meta['total'] is num) ? (meta['total'] as num).toInt() : 0;

      // Local search fallback (if backend doesn't support q)
      final filtered = _search.trim().isEmpty
          ? items
          : items.where((m) {
              final patient = _patientName(m).toLowerCase();
              final med = _medName(m).toLowerCase();
              final s = _search.toLowerCase();
              return patient.contains(s) || med.contains(s);
            }).toList();

      if (!mounted) return;
      setState(() {
        _items.addAll(filtered);
        _total = total;
        _loading = false;

        if (total > 0) {
          _hasMore = (_items.length < total);
        } else {
          _hasMore = items.length == _limit; // best-effort
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _offset += _limit;
    await _load(reset: false);
  }

  Map<String, dynamic> _unwrapList(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return <String, dynamic>{'items': <dynamic>[], 'meta': <String, dynamic>{}};
  }

  Map<String, dynamic> _payload(Map<String, dynamic> m) {
    final p = m['payload'];
    if (p is Map) return Map<String, dynamic>.from(p);
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

  String _subLine(Map<String, dynamic> m) {
    final p = _payload(m);
    final dose = (p['dose'] ?? '').toString();
    final route = (p['route'] ?? '').toString();
    final freq = (p['frequency'] ?? '').toString();
    final dur = (p['duration'] ?? '').toString();

    final parts = <String>[
      if (dose.trim().isNotEmpty) 'Dose: $dose',
      if (route.trim().isNotEmpty) 'Route: $route',
      if (freq.trim().isNotEmpty) 'Freq: $freq',
      if (dur.trim().isNotEmpty) 'Dur: $dur',
    ];

    return parts.join(' • ');
  }

  String _qtyLine(Map<String, dynamic> m) {
    final p = _payload(m);
    final rq = p['requestedQty'];
    if (rq == null) return '';
    return 'Requested: $rq';
  }

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'طلبات الأدوية (الصيدلية)',
      body: Column(
        children: [
          _topBar(context),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _errorBox(context, _error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('لا توجد طلبات ضمن هذا التبويب'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 240) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (i >= _items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: _loading
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('تحميل المزيد'),
                                      ),
                              ),
                            );
                          }

                          final m = _items[i];
                          final id = (m['id'] ?? '').toString();
                          final status = (m['status'] ?? '—').toString();

                          final patient = _patientName(m);
                          final med = _medName(m);
                          final sub = _subLine(m);
                          final qty = _qtyLine(m);

                          return _orderCard(
                            context,
                            m,
                            orderId: id,
                            patient: patient,
                            drug: med,
                            subtitle: sub,
                            qtyLine: qty,
                            status: status,
                          );
                        },
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              children: [
                Text(
                  _total > 0
                      ? 'الإجمالي: $_total'
                      : 'عدد ظاهر: ${_items.length}',
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'بحث باسم المريض أو اسم الدواء…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'جديد'),
            Tab(text: 'جزئي'),
            Tab(text: 'غير متوفر'),
            Tab(text: 'مكتمل'),
          ],
        ),
      ],
    );
  }

  Widget _orderCard(
    BuildContext context,
    Map<String, dynamic> raw, {
    required String orderId,
    required String patient,
    required String drug,
    required String subtitle,
    required String qtyLine,
    required String status,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: orderId.isEmpty
          ? null
          : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PharmacyOrderDetailsPage(orderRaw: raw),
                ),
              );
              if (mounted) _load(reset: true);
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withAlpha(40)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    patient,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _pill(theme, status),
              ],
            ),
            const SizedBox(height: 6),
            Text(drug, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: theme.hintColor)),
            ],
            if (qtyLine.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(qtyLine),
            ],
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.open_in_new_rounded, size: 18),
                SizedBox(width: 6),
                Text('فتح التفاصيل'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withAlpha(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _errorBox(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }
}
