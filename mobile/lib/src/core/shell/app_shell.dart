import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src_v2/core/auth/auth_store.dart';

import '../../../src_v2/features/auth/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/staff/staff_page.dart';
import '../../features/account/account_page.dart';

// ✅ New
import '../../features/orders/create_order_page.dart';
import '../../features/tasks/my_tasks_page.dart';

import 'shell_page.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellPage _page = ShellPage.home;

  List<String> _rolesOf(AuthStore auth) {
    final u = auth.user;
    if (u is Map<String, dynamic>) {
      final raw = u['roles'];
      if (raw is List) {
        return raw.map((e) => e.toString().toUpperCase().trim()).toList();
      }
    }
    return const [];
  }

  bool _hasRole(AuthStore auth, String role) {
    final roles = _rolesOf(auth);
    return roles.contains(role.toUpperCase().trim());
  }

  Set<ShellPage> _allowedPages(AuthStore auth) {
    final isAdmin = _hasRole(auth, 'ADMIN');
    final isDoctor = _hasRole(auth, 'DOCTOR');
    final isNurse = _hasRole(auth, 'NURSE');

    return <ShellPage>{
      ShellPage.home,
      ShellPage.account,
      if (isAdmin) ShellPage.staff,
      if (isDoctor) ShellPage.orders,
      if (isNurse) ShellPage.tasks,
    };
  }

  ShellPage _fallback(Set<ShellPage> allowed) {
    const order = [
      ShellPage.home,
      ShellPage.orders,
      ShellPage.tasks,
      ShellPage.staff,
      ShellPage.account,
    ];
    for (final p in order) {
      if (allowed.contains(p)) return p;
    }
    return ShellPage.home;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    final allowed = _allowedPages(auth);

    if (!allowed.contains(_page)) {
      _page = _fallback(allowed);
    }

    final Widget body = switch (_page) {
      ShellPage.home => const HomePage(),
      ShellPage.staff => const StaffPage(),
      ShellPage.orders => const CreateOrderPage(),
      ShellPage.tasks => const MyTasksPage(),
      ShellPage.account => const AccountPage(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 900 ? 980.0 : double.infinity;

        return Scaffold(
          appBar: AppBar(title: const Text('CareSync')),
          drawer: AppDrawer(
            current: _page,
            onSelect: (p) {
              if (!allowed.contains(p)) return;
              setState(() => _page = p);
              Navigator.of(context).pop();
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
