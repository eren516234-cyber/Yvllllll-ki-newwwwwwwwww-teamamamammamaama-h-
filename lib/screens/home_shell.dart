import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/screens/home_screen.dart';
import 'package:yvl/widgets/global_background.dart';
import 'package:yvl/widgets/main_layout.dart';

/// Full shell: GlobalBackground + MainLayout + HomeScreen.
/// Used as the primary post-login destination so the layout
/// wrapper is always correct regardless of how we navigate here.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GlobalBackground(
      child: MainLayout(
        key: ValueKey('main_layout_shell'),
        child: HomeScreen(),
      ),
    );
  }
}
