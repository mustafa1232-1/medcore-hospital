// lib/src_v2/features/pharmacy_admin/presentation/pages/admin_warehouses_page.dart
// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

import 'admin_create_warehouse_page.dart';
import 'admin_stock_requests_page.dart';

class AdminWarehousesPage extends StatefulWidget {
  const AdminWarehousesPage({super.key});

  @override
  State<AdminWarehousesPage> createState() => _AdminWarehousesPageState();
}

class _AdminWarehousesPageState extends State<AdminWarehousesPage> {
  final _api = PharmacyApiService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _warehouse;
  int _pendingCount = 0;

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
      final w = await _api.getFirstWarehouse();
      _warehouse = w;

      // count pending requests (SUBMITTED)
      if (w != null) {
        // ✅ IMPORTANT:
        // listStockRequests() returns List(items) in your new service.
        // For meta.total we must use listStockRequestsRaw().
        final out = await _api.listStockRequestsRaw(
          status: 'SUBMITTED',
          limit: 1,
          offset: 0,
        );

        final meta = (out['meta'] is Map) ? (out['meta'] as Map) : const {};
        final total = meta['total'];

        _pendingCount = total is int
            ? total
            : int.tryParse(total?.toString() ?? '') ?? 0;
      } else {
        _pendingCount = 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _goCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCreateWarehousePage()),
    );
    if (created == true) {
      await _load();
    }
  }

  void _goApprovals() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminStockRequestsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'ملخص المستودع',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'إنشاء مستودع',
          onPressed: _loading ? null : _goCreate,
          icon: const Icon(Icons.add_home_work_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : _warehouse == null
            ? _EmptyState(onCreate: _goCreate)
            : _OverviewCard(
                warehouse: _warehouse!,
                pendingCount: _pendingCount,
                onApprovals: _goApprovals,
              ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Map<String, dynamic> warehouse;
  final int pendingCount;
  final VoidCallback onApprovals;

  const _OverviewCard({
    required this.warehouse,
    required this.pendingCount,
    required this.onApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = (warehouse['name'] ?? '—').toString().trim();
    final code = (warehouse['code'] ?? '').toString().trim();
    final isActive = warehouse['isActive'] == true;

    final pharmacistName = (warehouse['pharmacistName'] ?? '')
        .toString()
        .trim();
    final pharmacistStaffCode = (warehouse['pharmacistStaffCode'] ?? '')
        .toString()
        .trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withAlpha(45)),
                color: theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withAlpha(18),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? '—' : name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill(
                              context,
                              isActive ? 'Active' : 'Inactive',
                              isActive,
                            ),
                            if (code.isNotEmpty) _chip(context, 'Code: $code'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor.withAlpha(45)),
                color: theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withAlpha(200),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pharmacistName.isEmpty
                          ? 'لا يوجد صيدلي معيّن'
                          : 'الصيدلي: $pharmacistName'
                                '${pharmacistStaffCode.isEmpty ? '' : ' • $pharmacistStaffCode'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor.withAlpha(45)),
                color: theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withAlpha(200),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الطلبات المعلقة (SUBMITTED): $pendingCount',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onApprovals,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('الموافقة'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ملاحظة: الأدمن لا يعرض المخزون أو تفاصيل المستودع. دوره الموافقة على الطلبات فقط.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(170),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, bool ok) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: ok
            ? theme.colorScheme.primary.withAlpha(18)
            : theme.colorScheme.error.withAlpha(12),
        border: Border.all(
          color: ok
              ? theme.colorScheme.primary.withAlpha(70)
              : theme.colorScheme.error.withAlpha(60),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: ok ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
        border: Border.all(color: theme.dividerColor.withAlpha(45)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

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
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withAlpha(18),
                child: Icon(
                  Icons.home_work_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لا يوجد مستودع بعد',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'أنشئ مستودع وعيّن صيدلي عليه حتى تعمل عمليات الصيدلية.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_home_work_rounded),
                label: const Text('إنشاء مستودع'),
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
                color: theme.colorScheme.error,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'تعذر تحميل الملخص',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
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
    );
  }
}
