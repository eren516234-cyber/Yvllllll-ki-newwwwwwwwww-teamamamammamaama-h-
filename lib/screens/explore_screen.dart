import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/providers/explore_provider.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/services/storage_service.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with TickerProviderStateMixin {
  final FixedExtentScrollController _wheelController =
      FixedExtentScrollController(initialItem: 0);
  int _selectedIndex = 0;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _playItem(MuzoItem item) {
    if (item.videoId == null) {
      _showNoIdError();
      return;
    }
    HapticFeedback.mediumImpact();
    final audioHandler = ref.read(audioHandlerProvider);
    audioHandler.playVideo(item);
  }

  void _showNoIdError() {
    final ctx = context;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('Song not available'),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingContentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.1),
                      Text(
                        'Spin the wheel to discover',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 400.ms),
                    ],
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(trendingContentProvider);
                        setState(() => _selectedIndex = 0);
                        _wheelController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          FluentIcons.arrow_sync_24_regular,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Wheel ───────────────────────────────────────────────────
            Expanded(
              child: trendingAsync.when(
                data: (content) {
                  final rawItems = [
                    ...?content['songs'],
                    ...?content['playlists'],
                  ].take(20).toList();

                  final items = rawItems
                      .where((i) => i.videoId != null)
                      .toList();

                  if (items.isEmpty) {
                    return _buildEmpty(context, theme);
                  }

                  final selected = _selectedIndex < items.length
                      ? items[_selectedIndex]
                      : null;

                  return Column(
                    children: [
                      // ── Featured card ───────────────────────────────
                      if (selected != null)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: _FeaturedCard(
                            item: selected,
                            pulseAnim: _pulseAnim,
                            onPlay: () => _playItem(selected),
                          ).animate().fadeIn(duration: 300.ms),
                        ),

                      const SizedBox(height: 20),

                      // ── Scroll wheel ────────────────────────────────
                      Expanded(
                        child: _MusicWheel(
                          items: items,
                          selectedIndex: _selectedIndex,
                          controller: _wheelController,
                          onIndexChanged: (idx) {
                            setState(() => _selectedIndex = idx);
                            HapticFeedback.selectionClick();
                          },
                          onPlay: _playItem,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => _buildLoading(context, theme),
                error: (_, __) => _buildEmpty(context, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading music...',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.compass_northwest_24_regular,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing to explore',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Featured Card ────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final MuzoItem item;
  final Animation<double> pulseAnim;
  final VoidCallback onPlay;

  const _FeaturedCard({
    required this.item,
    required this.pulseAnim,
    required this.onPlay,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb =
        widget.item.thumbnails.isNotEmpty ? widget.item.thumbnails.last.url : '';
    final artist = widget.item.displayArtist;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onPlay();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: ScaleTransition(
          scale: widget.pulseAnim,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Artwork
                  CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surface,
                      child: Icon(
                        FluentIcons.music_note_2_24_regular,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ),

                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),

                  // Text + play button
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (artist.isNotEmpty)
                                    Text(
                                      artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Play button
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Music Wheel ─────────────────────────────────────────────────────────────
class _MusicWheel extends StatelessWidget {
  final List<MuzoItem> items;
  final int selectedIndex;
  final FixedExtentScrollController controller;
  final void Function(int) onIndexChanged;
  final void Function(MuzoItem) onPlay;
  final bool isDark;
  final ThemeData theme;

  const _MusicWheel({
    required this.items,
    required this.selectedIndex,
    required this.controller,
    required this.onIndexChanged,
    required this.onPlay,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Selection highlight band
        Center(
          child: Container(
            height: 82,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Wheel
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 82,
          diameterRatio: 2.8,
          perspective: 0.004,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onIndexChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= items.length) return null;
              final item = items[index];
              final isSelected = index == selectedIndex;
              return _WheelItem(
                item: item,
                isSelected: isSelected,
                theme: theme,
                isDark: isDark,
                onPlay: () => onPlay(item),
              );
            },
            childCount: items.length,
          ),
        ),

        // Top/bottom fade
        Positioned.fill(
          child: IgnorePointer(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wheel Item ───────────────────────────────────────────────────────────────
class _WheelItem extends StatelessWidget {
  final MuzoItem item;
  final bool isSelected;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onPlay;

  const _WheelItem({
    required this.item,
    required this.isSelected,
    required this.theme,
    required this.isDark,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final thumb =
        item.thumbnails.isNotEmpty ? item.thumbnails.last.url : '';
    final artist = item.displayArtist;

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.88,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: isSelected ? onPlay : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: thumb,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 58,
                      height: 58,
                      color: theme.colorScheme.surface,
                      child: Icon(
                        FluentIcons.music_note_2_24_regular,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + artist
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: isSelected ? 15 : 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (artist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Play icon (only when selected)
                if (isSelected)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 22,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 200.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 150.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
