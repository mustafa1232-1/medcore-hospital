import 'package:flutter/material.dart';
import 'v2_app_drawer.dart';

class V2ShellScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const V2ShellScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const V2AppDrawer(),
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
    );
  }
}
