import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/player_provider.dart';
import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:yvl/services/lyrics_service.dart';
import 'package:yvl/widgets/lyrics_view.dart';
import 'package:yvl/providers/theme_provider.dart';
import 'package:audio_service/audio_service.dart';

class AlbumArtNLyrics extends ConsumerStatefulWidget {
  final double playerArtImageSize;
  const AlbumArtNLyrics({super.key, required this.playerArtImageSize});

  @override
  ConsumerState<AlbumArtNLyrics> createState() => _AlbumArtNLyricsState();
}

class _AlbumArtNLyricsState extends ConsumerState<AlbumArtNLyrics>
    with SingleTickerProviderStateMixin {
  bool _showLyrics = false;
  bool _isLoadingLyrics = false;
  Lyrics? _lyrics;
  String? _lastFetchedTitle;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics(MediaItem mediaItem) async {
    if (_lyrics != null && _lastFetchedTitle == mediaItem.title) return;
    if (_isLoadingLyrics) return;

    setState(() => _isLoadingLyrics = true);

    try {
      final lyrics = await ref
          .read(lyricsServiceProvider)
          .fetchLyrics(
            mediaItem.title,
            mediaItem.artist ?? '',
            mediaItem.duration?.inSeconds ??
                ref.read(audioHandlerProvider).player.duration?.inSeconds ??
                0,
          );
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _lastFetchedTitle = mediaItem.title;
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLyrics = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    ref.listen(currentMediaItemProvider, (previous, next) {
      next.whenData((mediaItem) {
        if (mediaItem != null &&
            mediaItem.title != _lastFetchedTitle &&
            _showLyrics) {
          _fetchLyrics(mediaItem);
        }
      });
    });

    final safeSize = widget.playerArtImageSize.clamp(10.0, double.infinity);

    return SizedBox(
      width: safeSize,
      height: safeSize,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -280) {
            audioHandler.skipToNext();
          } else if (velocity > 280) {
            audioHandler.skipToPrevious();
          }
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Album Art
              mediaItemAsync.when(
                data: (mediaItem) {
                  if (mediaItem?.artUri == null) {
                    return Container(color: Colors.grey[900]);
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: CachedNetworkImage(
                      key: ValueKey(mediaItem!.artUri.toString()),
                      imageUrl: mediaItem.artUri.toString().replaceAll(
                        RegExp(r'w\d+-h\d+'),
                        'w800-h800',
                      ),
                      fit: BoxFit.cover,
                      width: widget.playerArtImageSize,
                      height: widget.playerArtImageSize,
                      errorWidget: (context, url, error) => Icon(
                        Icons.music_note,
                        size: 50,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                },
                loading: () => Container(color: Colors.grey[900]),
                error: (_, __) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.error),
                ),
              ),

              // Lyrics Overlay with smooth fade
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _showLyrics
                    ? Positioned.fill(
                        key: const ValueKey('lyrics'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                            child: Container(
                              color:
                                  (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.black
                                          : Colors.white)
                                      .withValues(alpha: 0.48),
                              child: _isLoadingLyrics
                                  ? Center(
                                      child: Text(
                                        'Lyrics loading...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : _lyrics == null
                                  ? Center(
                                      child: Text(
                                        "No lyrics found",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    )
                                  : LyricsView(
                                      lyrics: _lyrics!,
                                      onClose: () =>
                                          setState(() => _showLyrics = false),
                                      positionStream:
                                          audioHandler.player.positionStream,
                                      totalDuration:
                                          audioHandler.player.duration ??
                                          Duration.zero,
                                      isEmbedded: true,
                                      accentColor:
                                          ref
                                              .watch(currentPaletteProvider)
                                              .asData
                                              ?.value
                                              ?.darkVibrantColor
                                              ?.color ??
                                          Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-lyrics')),
              ),

              // Lyrics Button (hide when lyrics are shown)
              if (!_showLyrics)
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              final mediaItem = mediaItemAsync.value;
                              if (mediaItem != null) {
                                setState(() => _showLyrics = true);
                                _fetchLyrics(mediaItem);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FluentIcons.text_quote_20_filled,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Lyrics",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showLyrics)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _GlassLyricButton(
                    icon: FluentIcons.arrow_sync_20_filled,
                    label: 'Re-sync',
                    onTap: () {
                      // Re-fetch lyrics without touching playback position
                      setState(() {
                        _lyrics = null;
                        _lastFetchedTitle = null;
                        _isLoadingLyrics = false;
                      });
                      final mediaItem = mediaItemAsync.value;
                      if (mediaItem != null) {
                        _fetchLyrics(mediaItem);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _GlassLyricButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassLyricButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
