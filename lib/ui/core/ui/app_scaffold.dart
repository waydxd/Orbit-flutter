import 'package:flutter/material.dart';

/// Base scaffold for consistent app structure
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool showAppBar;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  
  const AppScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.showAppBar = true,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}