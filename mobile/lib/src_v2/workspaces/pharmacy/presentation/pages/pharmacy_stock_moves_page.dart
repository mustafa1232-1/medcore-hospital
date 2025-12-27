import 'package:flutter/material.dart';

class PharmacyStockMovesPage extends StatelessWidget {
  const PharmacyStockMovesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حركات المخزون')),
      body: const Center(
        child: Text(
          'سنربط هذه الصفحة مع Stock Moves Ledger.\n'
          'ثم نضيف Filters + pagination.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
