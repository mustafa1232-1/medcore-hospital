import 'package:flutter/material.dart';
import 'package:mobile/src/core/settings/app_settings_store.dart';
import 'package:provider/provider.dart';

import 'v2_app_drawer.dart';

class V2ShellScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  // ✅ new: common Scaffold features
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool showDrawer;
  final bool centerTitle;

  const V2ShellScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.showDrawer = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsStore>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
      ),

      // ✅ Keep your existing drawer logic
      drawer: showDrawer ? (drawer ?? const V2AppDrawer()) : null,

      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaleFactor: settings.textScale),
        child: body,
      ),

      // ✅ now supported
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
