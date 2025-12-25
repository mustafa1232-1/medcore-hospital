import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/role_utils.dart';

// ✅ نعيد استخدام AuthStore الحالي بدون تغييرات
import '../../../src/core/auth/auth_store.dart';

// ✅ LoginPage الحالية (V1) كما هي
import '../../../src/features/auth/login_page.dart';

// ✅ الصفحات الجديدة (V2 Workspaces)
import '../../workspaces/doctor/doctor_home_page.dart';
import '../../workspaces/nurse/nurse_home_page.dart';
import '../../workspaces/admin/admin_home_page.dart';

class V2Shell extends StatelessWidget {
  const V2Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ إن لم يكن مسجّل دخول: افتح LoginPage القديمة كما هي
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    final user = auth.user;
    final isAdmin = RoleUtils.hasRole(user, 'ADMIN');
    final isDoctor = RoleUtils.hasRole(user, 'DOCTOR');
    final isNurse = RoleUtils.hasRole(user, 'NURSE');

    // ✅ أولوية العرض:
    // Admin -> Doctor -> Nurse
    if (isAdmin) return const AdminHomePage();
    if (isDoctor) return const DoctorHomePage();
    if (isNurse) return const NurseHomePageV2();

    return const Scaffold(
      body: Center(child: Text('لا يوجد دور صالح لهذا المستخدم')),
    );
  }
}
