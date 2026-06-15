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
    if (_isLoadingLyrics) return;
    // Reset if different song
    if (_lastFetchedTitle != mediaItem.title) {
      setState(() {
        _lyrics = null;
        _lastFetchedTitle = null;
      });
    }
    if (_lyrics != null && _lastFetchedTitle == mediaItem.title) return;

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

  void _closeLyrics() {
    setState(() => _showLyrics = false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    // Auto-prefetch lyrics when song changes (even when lyrics pane is closed)
    ref.listen(currentMediaItemProvider, (previous, next) {
      next.whenData((mediaItem) {
        if (mediaItem == null) return;
        if (mediaItem.title != _lastFetchedTitle && !_isLoadingLyrics) {
          // Pre-fetch in background so lyrics appear instantly when opened
          _fetchLyrics(mediaItem);
          // Also auto-show if already in lyrics mode
          if (_showLyrics) {
            setState(() {
              _lyrics = null;
              _lastFetchedTitle = null;
            });
          }
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
                                        .withValues(alpha: 0.55),
                                child: _isLoadingLyrics
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Finding lyrics...',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _lyrics == null
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FluentIcons.text_quote_20_regular,
                                              size: 36,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              "No lyrics found",
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton(
                                              onPressed: () {
                                                final mi = mediaItemAsync.value;
                                                if (mi != null) {
                                                  setState(() {
                                                    _lyrics = null;
                                                    _lastFetchedTitle = null;
                                                  });
                                                  _fetchLyrics(mi);
                                                }
                                              },
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : LyricsView(
                                        lyrics: _lyrics!,
                                        onClose: _closeLyrics,
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

                // Lyrics Button (shown when lyrics hidden)
                if (!_showLyrics)
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: _GlassLyricButton(
                      icon: FluentIcons.text_quote_20_filled,
                      label: _isLoadingLyrics ? 'Loading...' : 'Lyrics',
                      onTap: () {
                        final mediaItem = mediaItemAsync.value;
                        if (mediaItem != null) {
                          setState(() => _showLyrics = true);
                          if (_lyrics == null && !_isLoadingLyrics) {
                            _fetchLyrics(mediaItem);
                          }
                        }
                      },
                    ),
                  ),

                // Close button (shown when lyrics visible)
                if (_showLyrics)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _GlassLyricButton(
                      icon: FluentIcons.dismiss_20_filled,
                      label: 'Close',
                      onTap: _closeLyrics,
                    ),
                  ),

                // Re-sync button (shown when lyrics visible, bottom-right)
                if (_showLyrics && _lyrics != null)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _GlassLyricButton(
                      icon: FluentIcons.arrow_sync_20_filled,
                      label: 'Re-sync',
                      onTap: () {
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
                  Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 15),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
