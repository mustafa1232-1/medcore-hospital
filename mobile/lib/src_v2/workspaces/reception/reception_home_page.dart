// lib/workspaces/reception/reception_home_page.dart
// ✅ Reception Home Page (Workspace style) - stable, no dynamic calls, no extra logic.

import 'package:flutter/material.dart';
import 'package:mobile/src_v2/core/shell/v2_app_drawer.dart';

import 'package:mobile/src_v2/features/patients/presentation/pages/patients_list_page.dart';
import 'package:mobile/src_v2/features/patients/presentation/pages/create_patient_page.dart';

class ReceptionHomePage extends StatefulWidget {
  const ReceptionHomePage({super.key});

  @override
  State<ReceptionHomePage> createState() => _ReceptionHomePageState();
}

class _ReceptionHomePageState extends State<ReceptionHomePage> {
  Future<void> _openCreatePatient() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePatientPage()));

    if (!mounted) return;

    if (ok == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء المريض')));

      // ✅ لا نعمل refresh هنا حتى لا نكسر أي لوجك
      // إذا تريد تحديث تلقائي: نضيفه لاحقاً داخل PatientsListPage بشكل رسمي.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const V2AppDrawer(),
      appBar: AppBar(
        title: const Text('الاستقبال'),
        actions: [
          IconButton(
            tooltip: 'إنشاء مريض',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _openCreatePatient,
          ),
        ],
      ),

      // ✅ كل شغل الاستقبال داخل المرضى مباشرة
      body: const PatientsListPage(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePatient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إنشاء مريض'),
      ),
    );
  }
}
