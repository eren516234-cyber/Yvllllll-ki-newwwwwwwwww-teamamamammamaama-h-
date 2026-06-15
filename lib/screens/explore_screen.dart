import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/providers/explore_provider.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/screens/search_screen.dart';

const _thumbBase = 'https://i.ytimg.com/vi';

class _GenreTile {
  final String label;
  final IconData icon;
  final Color color;
  final String query;
  const _GenreTile(this.label, this.icon, this.color, this.query);
}

const _genres = [
  _GenreTile('Pop', FluentIcons.star_24_filled, Color(0xFFE91E63), 'top pop songs 2024'),
  _GenreTile('Hip-Hop', FluentIcons.mic_24_filled, Color(0xFF9C27B0), 'best hip hop 2024'),
  _GenreTile('R&B', FluentIcons.heart_24_filled, Color(0xFFFF5722), 'best rnb songs 2024'),
  _GenreTile('Rock', FluentIcons.music_note_2_24_filled, Color(0xFF607D8B), 'classic rock hits'),
  _GenreTile('Electronic', FluentIcons.headphones_24_filled, Color(0xFF00BCD4), 'electronic dance music'),
  _GenreTile('Country', FluentIcons.flag_24_filled, Color(0xFF795548), 'country music hits'),
  _GenreTile('Jazz', FluentIcons.music_note_1_24_filled, Color(0xFF3F51B5), 'smooth jazz music'),
  _GenreTile('Classical', FluentIcons.app_store_24_filled, Color(0xFF009688), 'classical music'),
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  void _playItem(MuzoItem item) {
    if (item.videoId == null) return;
    HapticFeedback.lightImpact();
    ref.read(audioHandlerProvider).playVideo(item);
  }

  void _searchGenre(BuildContext context, String query) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingContentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
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
                      icon: Icon(FluentIcons.arrow_clockwise_24_regular, color: theme.colorScheme.onSurface),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(trendingContentProvider);
                      },
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
            ),

            // ── Browse Genres ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'Browse Genres',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final g = _genres[i];
                    return GestureDetector(
                      onTap: () => _searchGenre(context, g.query),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: g.color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(g.icon, color: g.color, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                g.label,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 40));
                  },
                  childCount: _genres.length,
                ),
              ),
            ),

            // ── Trending Now ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Text(
                      'Trending Now 🔥',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    trendingAsync.whenOrNull(
                      data: (_) => GestureDetector(
                        onTap: () => ref.invalidate(trendingContentProvider),
                        child: Text(
                          'Refresh',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ) ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            trendingAsync.when(
              data: (content) {
                final items = [
                  ...?content['songs'],
                  ...?content['playlists'],
                ].where((item) => item.videoId != null).take(20).toList();

                if (items.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmpty(context));
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item = items[i];
                        return _TrendingListItem(
                          item: item,
                          rank: i + 1,
                          onPlay: () => _playItem(item),
                        ).animate().fadeIn(duration: 280.ms, delay: Duration(milliseconds: i * 30));
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(child: _buildLoading(context, theme)),
              error: (_, __) => SliverToBoxAdapter(child: _buildEmpty(context)),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(FluentIcons.compass_northwest_24_regular, size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Nothing to explore yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(trendingContentProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingListItem extends StatelessWidget {
  final MuzoItem item;
  final int rank;
  final VoidCallback onPlay;

  const _TrendingListItem({required this.item, required this.rank, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.first.url : '';
    final artist = item.artists?.isNotEmpty == true ? item.artists!.first.name : '';

    return GestureDetector(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rank <= 3
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  fontSize: rank <= 3 ? 14 : 12,
                  fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: thumb.isNotEmpty
                    ? thumb
                    : '$_thumbBase/${item.videoId}/hqdefault.jpg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 52, height: 52,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(FluentIcons.music_note_2_24_regular,
                      size: 22, color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
            Icon(
              Icons.play_circle_outline_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
