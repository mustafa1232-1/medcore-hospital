import 'package:flutter/material.dart';
import 'package:mobile/src/l10n/app_localizations.dart';
import 'package:mobile/src_v2/features/orders/presentation/pages/create_medication_order_page.dart';

import '../../features/orders/presentation/pages/orders_dashboard_page.dart';

// ✅ غيّر المسار/الاسم حسب مشروعك

class DoctorOrdersDashboardPage extends StatelessWidget {
  const DoctorOrdersDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.orders_title),
        actions: [
          IconButton(
            tooltip: 'إنشاء طلب دواء',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateMedicationOrderPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: const OrdersDashboardPage(),
    );
  }
}
