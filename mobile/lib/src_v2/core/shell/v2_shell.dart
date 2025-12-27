// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/role_utils.dart';
import '../auth/auth_store.dart';
import '../auth/patient_session_store.dart'; // ✅ add
import '../../features/auth/login_page.dart';

import '../../workspaces/doctor/doctor_home_page.dart';
import '../../workspaces/nurse/nurse_home_page.dart';
import '../../workspaces/admin/admin_home_page.dart';
import '../../workspaces/pharmacy/presentation/pages/pharmacy_home_page.dart';
import '../../workspaces/reception/reception_home_page.dart';

// ✅ Patient entry
import '../../workspaces/patient/presentation/pages/patient_facilities_page.dart';

class V2Shell extends StatelessWidget {
  const V2Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final patientSession = context.watch<PatientSessionStore>();

    // ✅ Wait both stores to be ready
    if (!auth.isReady || !patientSession.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Staff wins if authenticated
    if (auth.isAuthenticated) {
      final user = auth.user;

      final isAdmin = RoleUtils.hasRole(user, 'ADMIN');
      final isDoctor = RoleUtils.hasRole(user, 'DOCTOR');
      final isNurse = RoleUtils.hasRole(user, 'NURSE');
      final isPharmacy = RoleUtils.hasRole(user, 'PHARMACY');
      final isReception = RoleUtils.hasRole(user, 'RECEPTION');

      if (isAdmin) return const AdminHomePage();
      if (isDoctor) return const DoctorHomePage();
      if (isNurse) return const NurseHomePageV2();
      if (isPharmacy) return const PharmacyHomePageV2();
      if (isReception) return const ReceptionHomePage();

      return const Scaffold(
        body: Center(child: Text('لا يوجد دور صالح لهذا المستخدم')),
      );
    }

    // ✅ If patient token exists, open patient portal
    if (patientSession.isAuthenticated) {
      return const PatientFacilitiesPage();
    }

    // ✅ Otherwise show unified login
    return const LoginPage();
  }
}
