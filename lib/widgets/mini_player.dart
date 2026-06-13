import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

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

        final resultType = mediaItem.extras?['resultType'] ?? 'video';
        final isSong = resultType == 'song';

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
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
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -300) {
              HapticFeedback.lightImpact();
              audioHandler.skipToNext();
            } else if (details.primaryVelocity! > 300) {
              HapticFeedback.lightImpact();
              audioHandler.skipToPrevious();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: mediaItem.artUri.toString(),
                        height: 44,
                        width: 44,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: Icon(
                            FluentIcons.music_note_2_24_regular,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _MiniWaveform(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mediaItem.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            mediaItem.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Previous button
                    IconButton(
                      icon: Icon(
                        FluentIcons.previous_24_filled,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audioHandler.skipToPrevious();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    // Play/Pause
                    StreamBuilder<PlayerState>(
                      stream: audioHandler.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final isPlaying = playerState?.playing ?? false;
                        final isLoading = processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering;

                        if (isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          );
                        }

                        return IconButton(
                          icon: Icon(
                            isPlaying
                                ? FluentIcons.pause_24_filled
                                : FluentIcons.play_24_filled,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (isPlaying) {
                              audioHandler.pause();
                            } else {
                              audioHandler.resume();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        );
                      },
                    ),
                    // Next button
                    IconButton(
                      icon: Icon(
                        FluentIcons.next_24_filled,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audioHandler.skipToNext();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    // Favorite Button
                    Consumer(
                      builder: (context, ref, child) {
                        final storage = ref.watch(storageServiceProvider);
                        return ValueListenableBuilder<List<MuzoItem>>(
                          valueListenable: storage.favoritesListenable,
                          builder: (context, favorites, _) {
                            final isFav = storage.isFavorite(mediaItem.id);
                            return IconButton(
                              icon: Icon(
                                isFav
                                    ? FluentIcons.heart_24_filled
                                    : FluentIcons.heart_24_regular,
                                color: isFav ? Colors.red : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                final result = MuzoItem(
                                  videoId: mediaItem.id,
                                  title: mediaItem.title,
                                  thumbnails: [
                                    MuzoThumbnail(
                                      url: mediaItem.artUri.toString(),
                                      width: 0,
                                      height: 0,
                                    ),
                                  ],
                                  artists: [MuzoArtist(name: mediaItem.artist ?? '', id: '')],
                                  resultType: isSong ? 'song' : 'video',
                                  isExplicit: false,
                                );
                                storage.toggleFavorite(result);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              // Progress bar
              StreamBuilder<Duration>(
                stream: audioHandler.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration =
                      mediaItem.duration ?? audioHandler.player.duration ?? Duration.zero;
                  double value = 0.0;
                  if (duration.inMilliseconds > 0) {
                    value = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                  }
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1.0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}


class _MiniWaveform extends StatefulWidget {
  const _MiniWaveform();

  @override
  State<_MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<_MiniWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final wave = math.sin((_controller.value * math.pi * 2) + i * .72);
            final height = 10 + (wave + 1) * 7;
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }
}
