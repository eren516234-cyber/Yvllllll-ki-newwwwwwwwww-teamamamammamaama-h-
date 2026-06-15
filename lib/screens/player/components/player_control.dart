import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:widget_marquee/widget_marquee.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'up_next_queue.dart';

import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/widgets/glass_snackbar.dart';

class PlayerControlWidget extends ConsumerWidget {
  const PlayerControlWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Title, Artist, Controls ───────────────────────────────────
          mediaItemAsync.when(
            data: (mediaItem) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                        child: Marquee(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(seconds: 10),
                          child: Text(
                            mediaItem?.title ?? '—',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Marquee(
                        delay: const Duration(milliseconds: 300),
                        duration: const Duration(seconds: 10),
                        child: Text(
                          mediaItem?.artist ?? '—',
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Queue Button
                _ActionButton(
                  icon: FluentIcons.list_24_regular,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.3,
                        maxChildSize: 0.9,
                        builder: (ctx, ctrl) => ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white)
                                    .withValues(alpha: 0.85),
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: UpNextQueue(
                                scrollController: ctrl,
                                onReorderStart: (_, __) {},
                                onReorderEnd: (_) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Favorite
                Consumer(
                  builder: (context, ref, _) {
                    final storage = ref.watch(storageServiceProvider);
                    if (mediaItem == null) return const SizedBox.shrink();
                    return ValueListenableBuilder(
                      valueListenable: storage.favoritesListenable,
                      builder: (_, __, ___) {
                        final isFav = storage.isFavorite(mediaItem.id);
                        return _ActionButton(
                          icon: isFav
                              ? FluentIcons.heart_24_filled
                              : FluentIcons.heart_24_regular,
                          color: isFav ? Colors.red : null,
                          onTap: () {
                            final item = MuzoItem(
                              videoId: mediaItem.id,
                              title: mediaItem.title,
                              thumbnails: [
                                MuzoThumbnail(
                                    url: mediaItem.artUri.toString(),
                                    width: 0,
                                    height: 0)
                              ],
                              artists: [
                                MuzoArtist(
                                    name: mediaItem.artist ?? '',
                                    id: mediaItem.extras?['artistId'] as String?)
                              ],
                              resultType:
                                  mediaItem.extras?['resultType'] ?? 'song',
                              isExplicit: false,
                            );
                            storage.toggleFavorite(item);
                            if (context.mounted) {
                              showGlassSnackBar(
                                context,
                                isFav
                                    ? 'Removed from favorites'
                                    : 'Added to favorites',
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          // ── Custom Curved Progress Bar ────────────────────────────────
          RepaintBoundary(
            child: StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.duration ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    // Curved / wave progress bar
                    GestureDetector(
                      onHorizontalDragUpdate: (d) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final localX = d.localPosition.dx;
                        final seekFrac = (localX / box.size.width).clamp(0.0, 1.0);
                        final seekPos = Duration(
                          milliseconds:
                              (seekFrac * duration.inMilliseconds).round(),
                        );
                        player.seek(seekPos);
                      },
                      onTapDown: (d) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final seekFrac =
                            (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                        final seekPos = Duration(
                          milliseconds:
                              (seekFrac * duration.inMilliseconds).round(),
                        );
                        player.seek(seekPos);
                      },
                      child: SizedBox(
                        height: 44,
                        child: CustomPaint(
                          painter: _CurvedProgressPainter(
                            progress: progress,
                            activeColor: Theme.of(context).colorScheme.onSurface,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.18),
                            thumbColor: Theme.of(context).colorScheme.onSurface,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    // Time labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Playback Controls ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shuffle
              StreamBuilder<bool>(
                stream: player.shuffleModeEnabledStream,
                builder: (context, snapshot) {
                  final shuffleOn = snapshot.data ?? false;
                  return _ControlIconBtn(
                    icon: FluentIcons.arrow_shuffle_24_regular,
                    active: shuffleOn,
                    onTap: () => player.setShuffleModeEnabled(!shuffleOn),
                  );
                },
              ),

              // Previous
              _ControlIconBtn(
                icon: FluentIcons.previous_24_filled,
                size: 30,
                onTap: () => audioHandler.skipToPrevious(),
              ),

              // Play / Pause
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isLoading =
                      state?.processingState == ProcessingState.loading ||
                          state?.processingState == ProcessingState.buffering;
                  final playing = state?.playing ?? false;

                  return GestureDetector(
                    onTap: () {
                      if (!isLoading) {
                        playing ? audioHandler.pause() : audioHandler.resume();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onSurface,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            )
                          : Icon(
                              playing
                                  ? FluentIcons.pause_24_filled
                                  : FluentIcons.play_24_filled,
                              color: Theme.of(context).colorScheme.surface,
                              size: 34,
                            ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        ),
                  );
                },
              ),

              // Next
              _ControlIconBtn(
                icon: FluentIcons.next_24_filled,
                size: 30,
                onTap: () => audioHandler.skipToNext(),
              ),

              // Repeat
              StreamBuilder<LoopMode>(
                stream: player.loopModeStream,
                builder: (context, snapshot) {
                  final mode = snapshot.data ?? LoopMode.off;
                  final isOn = mode != LoopMode.off;
                  return _ControlIconBtn(
                    icon: mode == LoopMode.one
                        ? FluentIcons.arrow_repeat_1_24_regular
                        : FluentIcons.arrow_repeat_all_24_regular,
                    active: isOn,
                    onTap: () {
                      final next = mode == LoopMode.off
                          ? LoopMode.all
                          : mode == LoopMode.all
                              ? LoopMode.one
                              : LoopMode.off;
                      player.setLoopMode(next);
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Curved Progress Bar Painter ─────────────────────────────────────────────
class _CurvedProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  _CurvedProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final midY = size.height / 2;
    const amplitude = 6.0;
    const barH = 4.0;
    final thumbX = w * progress;

    final bgPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = barH
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = activeColor
      ..strokeWidth = barH
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Build wave path
    final bgPath = Path();
    final fgPath = Path();

    const steps = 200;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = w * t;
      final wave = amplitude * (1 - (t - progress).abs().clamp(0, 1)) *
          (i == 0 ? 0 : 1);
      final y = midY -
          amplitude * 0.5 * (1 - (2 * (t - 0.5)).abs()) *
              (progress > 0 ? 1 : 0);

      if (i == 0) {
        bgPath.moveTo(x, y);
        fgPath.moveTo(x, y);
      } else {
        bgPath.lineTo(x, y);
        if (t <= progress) fgPath.lineTo(x, y);
      }
    }

    canvas.drawPath(bgPath, bgPaint);
    if (progress > 0) canvas.drawPath(fgPath, fgPaint);

    // Thumb glow
    if (progress > 0) {
      canvas.drawCircle(
        Offset(thumbX, midY),
        10,
        Paint()..color = thumbColor.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        Offset(thumbX, midY),
        6,
        Paint()..color = thumbColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedProgressPainter old) =>
      old.progress != progress;
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onTap,
    );
  }
}

class _ControlIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;

  const _ControlIconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 26,
  });

  @override
  State<_ControlIconBtn> createState() => _ControlIconBtnState();
}

class _ControlIconBtnState extends State<_ControlIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            widget.icon,
            color: widget.active
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
