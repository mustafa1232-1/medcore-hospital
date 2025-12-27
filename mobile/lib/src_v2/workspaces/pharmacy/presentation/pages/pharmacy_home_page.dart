import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/presentation/pages/pages/pharmacy_orders_page.dart';
import '../../../../core/shell/v2_shell_scaffold.dart';

class PharmacyHomePageV2 extends StatefulWidget {
  const PharmacyHomePageV2({super.key});

  @override
  State<PharmacyHomePageV2> createState() => _PharmacyHomePageV2State();
}

class _PharmacyHomePageV2State extends State<PharmacyHomePageV2> {
  bool _loadingOrders = true;
  String? _ordersError;

  List<Map<String, dynamic>> _ordersPreview = const [];
  int _newCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrdersPreview();
  }

  Future<void> _loadOrdersPreview() async {
    setState(() {
      _loadingOrders = true;
      _ordersError = null;
    });

    try {
      // We preview ONLY NEW queue (CREATED)
      final res = await ApiClient.dio.get(
        '/api/orders',
        queryParameters: {
          'kind': 'MEDICATION',
          'status': 'CREATED',
          'limit': 5,
          'offset': 0,
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

      if (!mounted) return;
      setState(() {
        _ordersPreview = items;
        _newCount = total > 0 ? total : items.length;
        _loadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ordersError = e.toString();
        _loadingOrders = false;
      });
    }
  }

  Map<String, dynamic> _unwrapList(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return <String, dynamic>{'items': <dynamic>[], 'meta': <String, dynamic>{}};
  }

  @override
  Widget build(BuildContext context) {
    return V2ShellScaffold(
      title: 'لوحة الصيدلية',
      body: RefreshIndicator(
        onRefresh: _loadOrdersPreview,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _ActionCard(
              title: 'طلبات الأدوية',
              subtitle: 'طابور الصيدلية: جديد / جزئي / غير متوفر / مكتمل.',
              icon: Icons.medication_rounded,
              trailing: _loadingOrders
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (_newCount > 0 ? _Badge(text: '$_newCount جديد') : null),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PharmacyOrdersPage()),
                );
                if (mounted) _loadOrdersPreview();
              },
            ),
            const SizedBox(height: 10),

            _OrdersPreviewCard(
              loading: _loadingOrders,
              error: _ordersError,
              items: _ordersPreview,
              onRetry: _loadOrdersPreview,
              onOpenAll: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PharmacyOrdersPage()),
                );
                if (mounted) _loadOrdersPreview();
              },
            ),

            const SizedBox(height: 12),
            const _InfoCard(
              title: 'المخزون',
              subtitle: 'عرض المخزون حسب المخزن/الصنف/الدفعة (قريباً).',
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'طلبات المخزون',
              subtitle: 'Workflow: Draft / Submitted / Approved (قريباً).',
              icon: Icons.assignment_rounded,
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'حركات المخزون',
              subtitle:
                  'Ledger: Receipt / Dispense / Transfer / Adjustment / Waste (قريباً).',
              icon: Icons.swap_horiz_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersPreviewCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
  final VoidCallback onRetry;
  final VoidCallback onOpenAll;

  const _OrdersPreviewCard({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRetry,
    required this.onOpenAll,
  });

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
    final parts = [
      dose,
      route,
      freq,
    ].where((x) => x.trim().isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (error != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تعذر جلب الطلبات: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    } else if (items.isEmpty) {
      body = const Text('لا توجد طلبات دواء جديدة حالياً.');
    } else {
      body = Column(
        children: [
          for (final m in items) ...[
            _OrderRow(
              patient: _patientName(m),
              medication: _medName(m),
              subtitle: _subLine(m),
              status: (m['status'] ?? '—').toString(),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenAll,
              child: const Text('فتح طابور الطلبات'),
            ),
          ),
        ],
      );
    }

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
          const Text(
            'آخر طلبات الأدوية (جديد)',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String patient;
  final String medication;
  final String subtitle;
  final String status;

  const _OrderRow({
    required this.patient,
    required this.medication,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(medication, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: theme.hintColor)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: theme.colorScheme.primary.withAlpha(16),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
          ),
          child: Text(
            status,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withAlpha(40)),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withAlpha(25),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withAlpha(25),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
