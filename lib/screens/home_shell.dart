import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/screens/home_screen.dart';
import 'package:yvl/widgets/main_layout.dart';

/// Post-login shell. MainLayout already wraps with GlobalBackground + Scaffold
/// + MiniPlayer + NavBar. Do NOT add another GlobalBackground here.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MainLayout(
      key: ValueKey('main_layout_shell'),
      child: HomeScreen(),
    );
  }
}
