import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_store.dart';

import '../../features/auth/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/staff/staff_page.dart';
import '../../features/account/account_page.dart';

import 'shell_page.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellPage _page = ShellPage.home;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    final Widget body = switch (_page) {
      ShellPage.home => const HomePage(),
      ShellPage.staff => const StaffPage(),
      ShellPage.account => const AccountPage(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Responsive: حصر عرض المحتوى على الشاشات الكبيرة
        final maxWidth = constraints.maxWidth >= 900 ? 980.0 : double.infinity;

        return Scaffold(
          // ✅ اسم ثابت (Brand) لا يتغير
          appBar: AppBar(title: const Text('CareSync')),

          drawer: AppDrawer(
            current: _page,
            onSelect: (p) {
              setState(() => _page = p);
              Navigator.of(context).pop(); // close drawer
            },
          ),

          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        );
      },
    );
  }
}
