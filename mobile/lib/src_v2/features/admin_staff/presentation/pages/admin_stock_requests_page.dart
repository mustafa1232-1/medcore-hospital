// lib/src_v2/features/pharmacy_admin/presentation/pages/admin_stock_requests_page.dart
// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

class AdminStockRequestsPage extends StatefulWidget {
  const AdminStockRequestsPage({super.key});

  @override
  State<AdminStockRequestsPage> createState() => _AdminStockRequestsPageState();
}

class _AdminStockRequestsPageState extends State<AdminStockRequestsPage> {
  final _api = PharmacyApiService();

  bool _loading = true;
  bool _acting = false;
  String? _error;

  List<Map<String, dynamic>> _items = const [];

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
      // ✅ الآن هذه ترجع List<Map> جاهزة
      final out = await _api.listStockRequests(
        status: 'SUBMITTED',
        limit: 50,
        offset: 0,
      );

      if (!mounted) return;
      setState(() => _items = out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndApprove(Map<String, dynamic> r) async {
    final id = (r['id'] ?? '').toString();
    if (id.isEmpty || _acting) return;

    final ok = await _confirmDialog(
      title: 'تأكيد الموافقة',
      message: 'هل تريد الموافقة على هذا الطلب؟',
      confirmText: 'موافقة',
    );
    if (ok != true) return;

    setState(() => _acting = true);
    try {
      await _api.approveStockRequest(id: id);
      await _load();
      if (!mounted) return;
      _toast('تمت الموافقة');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmAndReject(Map<String, dynamic> r) async {
    final id = (r['id'] ?? '').toString();
    if (id.isEmpty || _acting) return;

    final ok = await _confirmDialog(
      title: 'تأكيد الرفض',
      message: 'هل تريد رفض هذا الطلب؟',
      confirmText: 'رفض',
      destructive: true,
    );
    if (ok != true) return;

    setState(() => _acting = true);
    try {
      await _api.rejectStockRequest(id: id);
      await _load();
      if (!mounted) return;
      _toast('تم الرفض');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? theme.colorScheme.error : null,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _toast(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'طلبات المخزون (موافقة/رفض)',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: (_loading || _acting) ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : _items.isEmpty
            ? _EmptyState(onRefresh: _load)
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = _items[i];

                  final id = (r['id'] ?? '').toString();
                  final kind = (r['kind'] ?? '—').toString();
                  final createdAt = (r['createdAt'] ?? '').toString();
                  final fromWh = (r['fromWarehouseId'] ?? '').toString();
                  final toWh = (r['toWarehouseId'] ?? '').toString();
                  final status = (r['status'] ?? 'SUBMITTED').toString();

                  return Opacity(
                    opacity: _acting ? 0.65 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.dividerColor.withAlpha(45),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        kind,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    _statusPill(context, status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ID: $id${createdAt.isEmpty ? '' : ' • $createdAt'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withAlpha(170),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (fromWh.isNotEmpty || toWh.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (fromWh.isNotEmpty)
                                        _chip(context, 'From: $fromWh'),
                                      if (toWh.isNotEmpty)
                                        _chip(context, 'To: $toWh'),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'رفض',
                                onPressed: _acting
                                    ? null
                                    : () => _confirmAndReject(r),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              IconButton(
                                tooltip: 'موافقة',
                                onPressed: _acting
                                    ? null
                                    : () => _confirmAndApprove(r),
                                icon: Icon(
                                  Icons.check_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.trim().toUpperCase();

    final isApproved = s == 'APPROVED';
    final isRejected = s == 'REJECTED';

    final bg = isApproved
        ? theme.colorScheme.primary.withAlpha(18)
        : isRejected
        ? theme.colorScheme.error.withAlpha(12)
        : theme.colorScheme.tertiary.withAlpha(12);

    final bd = isApproved
        ? theme.colorScheme.primary.withAlpha(70)
        : isRejected
        ? theme.colorScheme.error.withAlpha(60)
        : theme.colorScheme.tertiary.withAlpha(70);

    final fg = isApproved
        ? theme.colorScheme.primary
        : isRejected
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    final label = (s.isEmpty) ? 'SUBMITTED' : s;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: bd),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 12),
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
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

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
                  Icons.assignment_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد طلبات حالياً',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ستظهر هنا الطلبات بحالة SUBMITTED لتقوم بالموافقة أو الرفض.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
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
                'تعذر تحميل الطلبات',
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
