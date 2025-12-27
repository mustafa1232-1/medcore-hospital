// lib/src_v2/features/admissions/presentation/pages/admit_any_patient_page.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_underscores

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import 'admit_patient_page.dart';

class AdmitAnyPatientPage extends StatefulWidget {
  const AdmitAnyPatientPage({super.key});

  @override
  State<AdmitAnyPatientPage> createState() => _AdmitAnyPatientPageState();
}

class _AdmitAnyPatientPageState extends State<AdmitAnyPatientPage> {
  final Dio _dio = ApiClient.dio;

  final _c = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get(
        '/api/lookups/patients',
        queryParameters: {'q': q.trim(), 'limit': 30},
      );

      final data = res.data;
      final itemsRaw = (data is Map && data['items'] is List)
          ? (data['items'] as List)
          : const [];
      final items = itemsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

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

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () => _load(v));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تنويم مريض')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            TextField(
              controller: _c,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'ابحث عن المريض بالاسم أو الهاتف...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) _errorBox(theme, _error!),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        final id = (it['id'] ?? '').toString().trim();
                        final label = (it['label'] ?? it['fullName'] ?? '')
                            .toString()
                            .trim();
                        final sub = (it['sub'] ?? it['phone'] ?? '')
                            .toString()
                            .trim();

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: theme.colorScheme.surface,
                          title: Text(
                            label.isEmpty ? '—' : label,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: id.isEmpty
                              ? null
                              : () async {
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => AdmitPatientPage(
                                            patientId: id,
                                            patientLabel: label.isEmpty
                                                ? null
                                                : label,
                                          ),
                                        ),
                                      );
                                  if (!mounted) return;
                                  Navigator.of(context).pop(result);
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(ThemeData theme, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
      ),
      child: Text(msg),
    );
  }
}
