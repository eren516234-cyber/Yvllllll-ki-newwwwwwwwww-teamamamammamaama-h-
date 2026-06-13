import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/navigation_provider.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/providers/theme_provider.dart';
import 'package:yvl/providers/search_provider.dart';
import 'package:yvl/screens/search_screen.dart';
import 'package:yvl/widgets/mini_player.dart';
import 'package:yvl/widgets/sync_progress_dialog.dart';
import 'package:yvl/services/share_service.dart';
import 'package:yvl/widgets/global_background.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/widgets/glass_snackbar.dart';
import 'package:yvl/services/navigator_key.dart';
import 'package:yvl/providers/overlay_provider.dart';
import 'package:yvl/services/auth_service.dart';
import 'package:app_links/app_links.dart';
import 'package:yvl/widgets/floating_sleep_timer.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with SingleTickerProviderStateMixin {
  late final ShareService _shareService;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    final audioHandler = ref.read(audioHandlerProvider);
    _shareService = ShareService(audioHandler);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareService.init(context);
    });

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    _shareService.handleSharedText(context, uri.toString());
  }

  @override
  void dispose() {
    _shareService.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isPlayerExpanded = ref.watch(isPlayerExpandedProvider);
    final globalBottomSheet = ref.watch(globalBottomSheetProvider);

    ref.listen(storageServiceProvider, (previous, next) {
      if (previous?.errorNotifier.value != next.errorNotifier.value &&
          next.errorNotifier.value != null) {
        showGlassSnackBar(context, next.errorNotifier.value!);
        next.errorNotifier.value = null;
      }
    });

    ref.listen(navigationIndexProvider, (previous, next) {
      if (previous != next) {
        ref.read(globalBottomSheetProvider.notifier).state = null;
      }
    });

    return GlobalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Main content
            widget.child,

            // 2. Lightweight storage sync hint only. Audio no longer blocks the UI,
            // so taps, lyrics, and playback controls feel instant.
            ValueListenableBuilder<bool>(
              valueListenable: ref.watch(storageServiceProvider).isLoadingNotifier,
              builder: (context, isStorageLoading, _) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  top: isStorageLoading ? MediaQuery.of(context).padding.top + 8 : -56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Syncing...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. Bottom Navigation Bar
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: IgnorePointer(
                ignoring: isPlayerExpanded,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isPlayerExpanded ? 0.0 : 1.0,
                  child: Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    height: 58 + MediaQuery.of(context).padding.bottom,
                    child: _buildFloatingNavBar(context, ref, selectedIndex),
                  ),
                ),
              ),
            ),

            // 4. MiniPlayer
            Positioned(
              left: 0, right: 0,
              bottom: 58 + MediaQuery.of(context).padding.bottom,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.96,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final mediaItemAsync = ref.watch(currentMediaItemProvider);
                      final palette = ref.watch(currentPaletteProvider).asData?.value;
                      final isExpandedVal = ref.watch(isPlayerExpandedProvider);
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      Color miniPlayerColor = isDark ? const Color(0xff404040) : Colors.white;
                      if (palette != null) {
                        final extracted =
                            palette.darkVibrantColor?.color ??
                            palette.darkMutedColor?.color ??
                            palette.dominantColor?.color ??
                            const Color(0xff404040);
                        miniPlayerColor = isDark
                            ? Color.lerp(const Color(0xff303030), extracted, 0.6)!
                            : Color.lerp(Colors.white, extracted, 0.5)!;
                      }

                      return mediaItemAsync.maybeWhen(
                        data: (mediaItem) {
                          if (mediaItem == null) return const SizedBox.shrink();
                          return IgnorePointer(
                            ignoring: isExpandedVal,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isExpandedVal ? 0.0 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: miniPlayerColor,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const MiniPlayer(),
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 5. Floating sleep timer
            const FloatingSleepTimer(),

            // 6. Global bottom sheet
            if (globalBottomSheet != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(globalBottomSheetProvider.notifier).state = null,
                        child: Container(color: Colors.black.withValues(alpha: 0.4)),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: globalBottomSheet,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, WidgetRef ref, int selectedIndex) {
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, ref,
              FluentIcons.home_24_regular, FluentIcons.home_24_filled, "Home", 0, selectedIndex),
          _buildNavItem(context, ref,
              FluentIcons.compass_northwest_24_regular, FluentIcons.compass_northwest_24_filled, "Explore", 1, selectedIndex),
          _buildNavItem(context, ref,
              FluentIcons.library_24_regular, FluentIcons.library_24_filled, "Library", 2, selectedIndex),
          _buildNavItem(context, ref,
              FluentIcons.person_24_regular, FluentIcons.person_24_filled, "Channels", 3, selectedIndex),
          _buildNavItem(context, ref,
              FluentIcons.settings_24_regular, FluentIcons.settings_24_filled, "Settings", 4, selectedIndex),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    IconData iconRegular,
    IconData iconFilled,
    String label,
    int index,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        if (index >= 0 && index <= 4) {
          ref.read(navigationIndexProvider.notifier).state = index;
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: isSelected ? 68 : 60,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? iconFilled : iconRegular,
                key: ValueKey(isSelected),
                color: isSelected
                    ? accent
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? accent
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
