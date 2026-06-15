import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/screens/player_screen.dart';
import 'package:yvl/services/navigator_key.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/models/muzo_item.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return mediaItemAsync.when(
      data: (mediaItem) {
        if (mediaItem == null) return const SizedBox.shrink();

        return _MiniPlayerContent(mediaItem: mediaItem, audioHandler: audioHandler);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MiniPlayerContent extends ConsumerStatefulWidget {
  final dynamic mediaItem;
  final dynamic audioHandler;

  const _MiniPlayerContent({required this.mediaItem, required this.audioHandler});

  @override
  ConsumerState<_MiniPlayerContent> createState() => _MiniPlayerContentState();
}

class _MiniPlayerContentState extends ConsumerState<_MiniPlayerContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOut,
    );
    _expandCtrl.forward();
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPlayer() async {
    HapticFeedback.lightImpact();
    if (navigatorKey.currentContext != null) {
      ref.read(isPlayerExpandedProvider.notifier).state = true;
      await Navigator.of(navigatorKey.currentContext!).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const ExpandedPlayer(),
          ),
          transitionDuration: const Duration(milliseconds: 350),
          fullscreenDialog: true,
        ),
      );
      ref.read(isPlayerExpandedProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final artUri = widget.mediaItem.artUri;
    final title = widget.mediaItem.title as String? ?? '';
    final artist = widget.mediaItem.artist as String? ?? '';

    return SizeTransition(
      sizeFactor: _expandAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openPlayer,
        onVerticalDragStart: (d) => _dragStartY = d.localPosition.dy,
        onVerticalDragUpdate: (d) {
          final dy = d.localPosition.dy - _dragStartY;
          if (dy < -40) _openPlayer();
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            HapticFeedback.lightImpact();
            widget.audioHandler.skipToNext();
          } else if (details.primaryVelocity! > 300) {
            HapticFeedback.lightImpact();
            widget.audioHandler.skipToPrevious();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    // ── Album art ─────────────────────────────────────
                    Hero(
                      tag: 'player_art',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: artUri != null
                            ? CachedNetworkImage(
                                imageUrl: artUri.toString(),
                                height: 46,
                                width: 46,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _PlaceholderArt(theme: theme),
                              )
                            : _PlaceholderArt(theme: theme),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Waveform ──────────────────────────────────────
                    const _MiniWaveform(),
                    const SizedBox(width: 8),

                    // ── Title & artist ─────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (artist.isNotEmpty)
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Controls ──────────────────────────────────────
                    _MiniControls(
                      audioHandler: widget.audioHandler,
                      mediaItem: widget.mediaItem,
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // ── Slim progress bar at bottom ──────────────────────────
              _MiniProgressBar(
                audioHandler: widget.audioHandler,
                theme: theme,
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOut),
    );
  }
}

// ─── Mini Controls ────────────────────────────────────────────────────────────
class _MiniControls extends ConsumerWidget {
  final dynamic audioHandler;
  final dynamic mediaItem;
  final ThemeData theme;

  const _MiniControls({
    required this.audioHandler,
    required this.mediaItem,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous
        _IconBtn(
          icon: FluentIcons.previous_24_filled,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          onTap: () {
            HapticFeedback.lightImpact();
            audioHandler.skipToPrevious();
          },
        ),

        // Play / Pause
        StreamBuilder<PlayerState>(
          stream: audioHandler.player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final isLoading = state?.processingState == ProcessingState.loading ||
                state?.processingState == ProcessingState.buffering;
            final isPlaying = state?.playing ?? false;

            if (isLoading) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }

            return _IconBtn(
              icon: isPlaying
                  ? FluentIcons.pause_24_filled
                  : FluentIcons.play_24_filled,
              size: 28,
              color: theme.colorScheme.onSurface,
              onTap: () {
                HapticFeedback.lightImpact();
                if (isPlaying) {
                  audioHandler.pause();
                } else {
                  audioHandler.resume();
                }
              },
            );
          },
        ),

        // Next
        _IconBtn(
          icon: FluentIcons.next_24_filled,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          onTap: () {
            HapticFeedback.lightImpact();
            audioHandler.skipToNext();
          },
        ),

        // Favorite
        ValueListenableBuilder<List<MuzoItem>>(
          valueListenable: storage.favoritesListenable,
          builder: (context, _, __) {
            final isFav = storage.isFavorite(mediaItem.id as String? ?? '');
            return _IconBtn(
              icon: isFav ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular,
              size: 19,
              color: isFav ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              onTap: () {
                HapticFeedback.lightImpact();
                final item = MuzoItem(
                  videoId: mediaItem.id as String? ?? '',
                  title: mediaItem.title as String? ?? '',
                  thumbnails: [
                    MuzoThumbnail(
                      url: mediaItem.artUri?.toString() ?? '',
                      width: 0,
                      height: 0,
                    )
                  ],
                  artists: [
                    MuzoArtist(
                      name: mediaItem.artist as String? ?? '',
                      id: mediaItem.extras?['artistId'] as String?,
                    )
                  ],
                  resultType: mediaItem.extras?['resultType'] as String? ?? 'song',
                  isExplicit: false,
                );
                storage.toggleFavorite(item);
              },
            );
          },
        ),
      ],
    );
  }
}

// ─── Mini Progress Bar ────────────────────────────────────────────────────────
class _MiniProgressBar extends StatelessWidget {
  final dynamic audioHandler;
  final ThemeData theme;

  const _MiniProgressBar({required this.audioHandler, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audioHandler.player.positionStream,
      builder: (ctx, posSnap) {
        return StreamBuilder<Duration?>(
          stream: audioHandler.player.durationStream,
          builder: (ctx, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final progress =
                dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 3,
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Placeholder Art ──────────────────────────────────────────────────────────
class _PlaceholderArt extends StatelessWidget {
  final ThemeData theme;
  const _PlaceholderArt({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      color: theme.colorScheme.surface,
      child: Icon(
        FluentIcons.music_note_2_24_regular,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        size: 22,
      ),
    );
  }
}

// ─── Icon Button ─────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

// ─── Mini Waveform ────────────────────────────────────────────────────────────
class _MiniWaveform extends StatefulWidget {
  const _MiniWaveform();

  @override
  State<_MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<_MiniWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 18,
      height: 22,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final phase = (i * 0.35 + _ctrl.value) % 1.0;
              final h = 4.0 + 14 * (0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2));
              return AnimatedContainer(
                duration: Duration(milliseconds: 120 + i * 40),
                width: 3.5,
                height: h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
