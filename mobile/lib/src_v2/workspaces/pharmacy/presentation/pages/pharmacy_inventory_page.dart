// lib/src_v2/features/pharmacy/presentation/pages/pharmacy_inventory_page.dart
import 'package:flutter/material.dart';
import 'package:mobile/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart';

import 'pharmacy_drug_create_page.dart';
import 'pharmacy_drug_edit_page.dart';

class PharmacyInventoryPage extends StatefulWidget {
  const PharmacyInventoryPage({super.key});

  @override
  State<PharmacyInventoryPage> createState() => _PharmacyInventoryPageState();
}

class _PharmacyInventoryPageState extends State<PharmacyInventoryPage> {
  final _api = PharmacyApiService();
  final _search = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _warehouses = const [];
  String? _warehouseId;

  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final whs = await _api.listWarehouses();
      if (!mounted) return;

      String? selected;
      if (whs.isNotEmpty) {
        selected = (whs.first['id'] ?? whs.first['warehouseId'] ?? '')
            .toString();
        if (selected.isEmpty) selected = null;
      }

      setState(() {
        _warehouses = whs;
        _warehouseId = selected;
      });

      if (selected != null) {
        await _loadSnapshot();
      } else {
        setState(() {
          _items = const [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSnapshot() async {
    final wid = _warehouseId;
    if (wid == null || wid.isEmpty) {
      setState(() {
        _items = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.getInventorySnapshot(
        warehouseId: wid,
        q: _search.text.trim(),
        limit: 200,
        offset: 0,
      );

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

  Future<void> _openCreateDrug() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PharmacyDrugCreatePage()),
    );

    if (changed == true) {
      if (_warehouseId == null) {
        await _bootstrap();
      } else {
        await _loadSnapshot();
      }
    }
  }

  String _whLabel(Map<String, dynamic> w) {
    final name = (w['name'] ?? '').toString().trim();
    final code = (w['code'] ?? '').toString().trim();
    if (name.isEmpty && code.isEmpty) return 'Warehouse';
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$name ($code)';
  }

  String _drugLabel(Map<String, dynamic> it) {
    final generic =
        (it['genericName'] ?? it['generic_name'] ?? it['name'] ?? '')
            .toString()
            .trim();
    final brand = (it['brandName'] ?? it['brand_name'] ?? '').toString().trim();
    final strength = (it['strength'] ?? '').toString().trim();
    final form = (it['form'] ?? '').toString().trim();

    final parts = <String>[
      if (generic.isNotEmpty) generic,
      if (brand.isNotEmpty) brand,
      if (strength.isNotEmpty) strength,
      if (form.isNotEmpty) form,
    ];
    return parts.isEmpty ? 'Drug' : parts.join(' • ');
  }

  String _qtyText(Map<String, dynamic> it) {
    final v =
        it['onHand'] ??
        it['on_hand'] ??
        it['qty'] ??
        it['quantity'] ??
        it['balance'] ??
        it['available'];

    if (v == null) return '—';
    return v.toString();
  }

  // ✅ NEW: extract drugId from different possible API shapes
  String? _extractDrugId(Map<String, dynamic> it) {
    final v =
        it['drugId'] ??
        it['drug_id'] ??
        it['drugCatalogId'] ??
        it['drug_catalog_id'] ??
        it['drug_catalog_id'] ??
        (it['drug'] is Map ? (it['drug']['id']) : null) ??
        (it['drugCatalog'] is Map ? (it['drugCatalog']['id']) : null);

    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _openEditDrug(String drugId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PharmacyDrugEditPage(drugId: drugId)),
    );

    // لا نغيّر منطق الكمية؛ فقط نحدّث قائمة العرض لأن الاسم/الجرعة قد تتغير
    if (changed == true) {
      if (_warehouseId == null) {
        await _bootstrap();
      } else {
        await _loadSnapshot();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _openCreateDrug,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'إضافة دواء',
          ),
          IconButton(
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_warehouses.isEmpty) {
            await _bootstrap();
          } else {
            await _loadSnapshot();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            _warehousePicker(theme),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadSnapshot(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'ابحث عن دواء...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 26),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorBox(
                theme,
                _error!,
                onRetry: () {
                  if (_warehouses.isEmpty) {
                    _bootstrap();
                  } else {
                    _loadSnapshot();
                  }
                },
              )
            else if (_warehouseId == null)
              _emptyBox(
                theme,
                title: 'لا يوجد Warehouse',
                subtitle: 'لازم يكون عند المنشأة Warehouse واحد على الأقل.',
              )
            else if (_items.isEmpty)
              _emptyBox(
                theme,
                title: 'لا يوجد نتائج',
                subtitle: 'جرّب بحث مختلف أو أضف أصناف/حركات مخزون.',
              )
            else
              ..._items.map((it) => _inventoryTile(theme, it)),
          ],
        ),
      ),
    );
  }

  Widget _warehousePicker(ThemeData theme) {
    return Container(
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
            'Warehouse',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _warehouseId,
                hint: const Text('اختر Warehouse'),
                items: _warehouses.map((w) {
                  final id = (w['id'] ?? w['warehouseId'] ?? '').toString();
                  return DropdownMenuItem(value: id, child: Text(_whLabel(w)));
                }).toList(),
                onChanged: (v) async {
                  setState(() => _warehouseId = v);
                  await _loadSnapshot();
                },
              ),
            ),
          ),
          if (_warehouses.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'لا توجد Warehouses (أو endpoint غير مطابق).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inventoryTile(ThemeData theme, Map<String, dynamic> it) {
    final label = _drugLabel(it);
    final qty = _qtyText(it);

    final lot = (it['lotNumber'] ?? it['lot_number'] ?? '').toString().trim();
    final exp = (it['expiryDate'] ?? it['expiry_date'] ?? '').toString().trim();

    final drugId = _extractDrugId(it);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: drugId == null ? null : () => _openEditDrug(drugId),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          [
            if (lot.isNotEmpty) 'LOT: $lot',
            if (exp.isNotEmpty) 'EXP: $exp',
            if (drugId == null) 'ملاحظة: لم يتم العثور على drugId لهذا السطر.',
          ].join('   '),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.dividerColor.withAlpha(40)),
            color: theme.colorScheme.surface,
          ),
          child: Text(qty, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _emptyBox(
    ThemeData theme, {
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 44),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(
    ThemeData theme,
    String error, {
    required VoidCallback onRetry,
  }) {
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
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 10),
            Text(
              'ملاحظة: إذا ظهرت رسالة 404/Not Found فمعناه مسار endpoint مختلف.\n'
              'عدّل routes داخل PharmacyApiService.',
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
}
