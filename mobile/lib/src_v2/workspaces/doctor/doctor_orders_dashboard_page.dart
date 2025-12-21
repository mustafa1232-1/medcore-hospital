import 'package:flutter/material.dart';
import 'package:mobile/src/l10n/app_localizations.dart';

import '../../features/orders/presentation/pages/orders_dashboard_page.dart';

class DoctorOrdersDashboardPage extends StatelessWidget {
  const DoctorOrdersDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // لا نكرر UI هنا، نخلي صفحة الداشبورد هي المصدر الوحيد
    return Scaffold(
      appBar: AppBar(title: Text(t.orders_title)),
      body: const OrdersDashboardPage(),
    );
  }
}
