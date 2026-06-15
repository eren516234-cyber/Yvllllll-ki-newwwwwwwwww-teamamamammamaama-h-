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

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final FixedExtentScrollController _wheelController = FixedExtentScrollController(initialItem: 0);
  int _selectedIndex = 0;

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _playItem(MuzoItem item) {
    HapticFeedback.lightImpact();
    final audioHandler = ref.read(audioHandlerProvider);
    audioHandler.playVideo(item);
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
                  Text(
                    'Explore',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const Spacer(),
                  IconButton(
                    icon: Icon(FluentIcons.more_horizontal_24_regular, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.invalidate(trendingContentProvider);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Wheel List ───────────────────────────────────────────────
            Expanded(
              child: trendingAsync.when(
                data: (content) {
                  final items = [
                    ...?content['songs'],
                    ...?content['playlists'],
                  ].take(15).toList();

                  if (items.isEmpty) {
                    return _buildEmpty(context);
                  }

                  return _WheelList(
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
                  );
                },
                loading: () => _buildLoading(context, theme),
                error: (_, __) => _buildEmpty(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, ThemeData theme) {
    return Center(
      child: SizedBox(
        width: 36, height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.compass_northwest_24_regular, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Nothing to explore', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Wheel List ─────────────────────────────────────────────────────────────
class _WheelList extends StatelessWidget {
  final List<MuzoItem> items;
  final int selectedIndex;
  final FixedExtentScrollController controller;
  final void Function(int) onIndexChanged;
  final void Function(MuzoItem) onPlay;
  final bool isDark;
  final ThemeData theme;

  const _WheelList({
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notif) {
        if (notif is ScrollEndNotification) {
          final idx = controller.selectedItem % items.length;
          onIndexChanged(idx);
        }
        return false;
      },
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        physics: const FixedExtentScrollPhysics(),
        itemExtent: 104,
        perspective: 0.005,
        diameterRatio: 2.0,
        squeeze: 1.05,
        onSelectedItemChanged: onIndexChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            final item = items[index];
            final distFromCenter = (index - selectedIndex).abs();
            final isSelected = index == selectedIndex;
            final opacity = isSelected ? 1.0 : (distFromCenter == 1 ? 0.6 : (distFromCenter == 2 ? 0.35 : 0.15));
            final scale = isSelected ? 1.0 : (distFromCenter == 1 ? 0.88 : 0.75);

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: opacity.clamp(0.0, 1.0),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: scale,
                child: _WheelItem(
                  item: item,
                  isSelected: isSelected,
                  distFromCenter: distFromCenter,
                  onPlay: () => onPlay(item),
                  isDark: isDark,
                  theme: theme,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Wheel Item ─────────────────────────────────────────────────────────────
class _WheelItem extends StatelessWidget {
  final MuzoItem item;
  final bool isSelected;
  final int distFromCenter;
  final VoidCallback onPlay;
  final bool isDark;
  final ThemeData theme;

  const _WheelItem({
    required this.item,
    required this.isSelected,
    required this.distFromCenter,
    required this.onPlay,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.first.url : '';
    final title = item.title;
    final artist = item.artists?.isNotEmpty == true ? item.artists!.first.name : '';
    final avatarSize = isSelected ? 72.0 : (distFromCenter == 1 ? 54.0 : 42.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Album art circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: theme.colorScheme.surface,
                  child: Icon(FluentIcons.music_note_2_24_regular,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: avatarSize * 0.4),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title & artist
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: isSelected ? 16 : 14,
                  ),
                ),
                if (artist.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Play pill (only for selected)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isSelected
                ? GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      key: const ValueKey('play'),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: theme.colorScheme.surface, size: 16),
                          const SizedBox(width: 4),
                          Text('Play', style: TextStyle(color: theme.colorScheme.surface, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 0, height: 0),
          ),
        ],
      ),
    );
  }
}
