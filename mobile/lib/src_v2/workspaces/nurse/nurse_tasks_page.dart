import 'package:flutter/material.dart';
import '../../../src/l10n/app_localizations.dart';

class NurseTasksPage extends StatelessWidget {
  const NurseTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.tasks_title)),
      body: Center(
        child: Text(
          'هذه نسخة V2. سنربطها بـ /api/tasks/my لاحقًا.\n'
          'ثم نضيف بحث/فلترة/Start/Complete بشكل كامل.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
