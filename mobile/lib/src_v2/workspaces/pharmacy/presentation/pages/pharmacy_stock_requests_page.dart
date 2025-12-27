// ignore_for_file: unnecessary_underscores, unused_local_variable

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_shell_scaffold.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

import 'pharmacy_stock_request_editor_page.dart';

class PharmacyStockRequestsPage extends StatefulWidget {
  const PharmacyStockRequestsPage({super.key});

  @override
  State<PharmacyStockRequestsPage> createState() =>
      _PharmacyStockRequestsPageState();
}

class _PharmacyStockRequestsPageState extends State<PharmacyStockRequestsPage> {
  final _api = PharmacyApiService();

  bool _loading = true;
  String? _error;

  String _status = 'DRAFT';
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _api.listStockRequests(
        status: _status,
        limit: 50,
        offset: 0,
      );

      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({String? requestId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PharmacyStockRequestEditorPage(requestId: requestId),
      ),
    );

    if (changed == true) await _load();
  }

  String _fmtDate(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return '';
    // keep ISO string (no intl) to avoid breaking dependencies
    return s;
  }

  bool get _isDraftTab => _status.trim().toUpperCase() == 'DRAFT';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2ShellScaffold(
      title: 'طلبات المخزون',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (_isDraftTab)
          IconButton(
            tooltip: 'إنشاء طلب',
            onPressed: _loading ? null : () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DRAFT', label: Text('Draft')),
                ButtonSegment(value: 'SUBMITTED', label: Text('Submitted')),
                ButtonSegment(value: 'APPROVED', label: Text('Approved')),
                ButtonSegment(value: 'REJECTED', label: Text('Rejected')),
              ],
              selected: {_status},
              onSelectionChanged: (s) async {
                final next = s.first;
                if (next == _status) return;
                setState(() => _status = next);
                await _load();
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 140),
                          Center(child: Text('لا توجد طلبات حالياً.')),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _items[i];

                          final id = (r['id'] ?? '').toString();
                          final kind = (r['kind'] ?? '—').toString();
                          final status = (r['status'] ?? '—').toString();
                          final createdAt = _fmtDate(r['createdAt']);
                          final fromWh = (r['fromWarehouseId'] ?? '')
                              .toString();
                          final toWh = (r['toWarehouseId'] ?? '').toString();

                          final isDraft =
                              status.trim().toUpperCase() == 'DRAFT';

                          return InkWell(
                            onTap: () => _openEditor(requestId: id),
                            borderRadius: BorderRadius.circular(18),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                kind,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                            _StatusPill(status: status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'ID: $id${createdAt.isEmpty ? '' : ' • $createdAt'}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                    ?.withAlpha(170),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (fromWh.isNotEmpty ||
                                            toWh.isNotEmpty) ...[
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
                                        if (!isDraft) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'هذا الطلب للعرض فقط (غير قابل للتعديل).',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withAlpha(160),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status.trim().toUpperCase();

    final isDraft = s == 'DRAFT';
    final isSubmitted = s == 'SUBMITTED';
    final isApproved = s == 'APPROVED';
    final isRejected = s == 'REJECTED';

    final bg = isApproved
        ? theme.colorScheme.primary.withAlpha(18)
        : isRejected
        ? theme.colorScheme.error.withAlpha(12)
        : isSubmitted
        ? theme.colorScheme.tertiary.withAlpha(12)
        : theme.colorScheme.surfaceContainerHighest.withAlpha(70);

    final bd = isApproved
        ? theme.colorScheme.primary.withAlpha(70)
        : isRejected
        ? theme.colorScheme.error.withAlpha(60)
        : isSubmitted
        ? theme.colorScheme.tertiary.withAlpha(70)
        : theme.dividerColor.withAlpha(45);

    final fg = isApproved
        ? theme.colorScheme.primary
        : isRejected
        ? theme.colorScheme.error
        : isSubmitted
        ? theme.colorScheme.tertiary
        : theme.colorScheme.onSurface.withAlpha(200);

    final label = s.isEmpty ? '—' : s;

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
}
