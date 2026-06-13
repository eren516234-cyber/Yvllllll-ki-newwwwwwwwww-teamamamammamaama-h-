import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/providers/explore_provider.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/widgets/result_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingContentProvider);
    final songsAsync = ref.watch(newestSongsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Explore',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(FluentIcons.arrow_sync_24_regular,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(trendingContentProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Spinning Album Dialer
            SliverToBoxAdapter(
              child: trendingAsync.when(
                data: (content) {
                  final items = [
                    ...?content['playlists'],
                    ...?content['songs'],
                  ].take(12).toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return _AlbumDialer(
                    items: items,
                    spinController: _spinController,
                    onTap: (item) => _playItem(item),
                  );
                },
                loading: () => const _DialerSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Section label: Trending Songs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Trending Now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // Songs horizontal scroll
            SliverToBoxAdapter(
              child: songsAsync.when(
                data: (songs) => songs.isEmpty
                    ? const _EmptySection()
                    : SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: songs.length,
                          itemBuilder: (context, i) => _AlbumCard(
                            item: songs[i],
                            onTap: () => _playItem(songs[i]),
                          ),
                        ),
                      ),
                loading: () => const _HorizontalSkeleton(),
                error: (_, __) => const _EmptySection(),
              ),
            ),

            // Playlists section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Featured Playlists',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: ref.watch(trendingPlaylistsProvider).when(
                data: (playlists) => playlists.isEmpty
                    ? const _EmptySection()
                    : SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: playlists.length,
                          itemBuilder: (context, i) => _AlbumCard(
                            item: playlists[i],
                            onTap: () => _playItem(playlists[i]),
                          ),
                        ),
                      ),
                loading: () => const _HorizontalSkeleton(),
                error: (_, __) => const _EmptySection(),
              ),
            ),

            // Recently played
            _buildRecentSection(context),

            const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final history = storage.historyListenable.value;
    if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Recently Played',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...history.take(8).map((item) => ResultTile(
          item: item,
          onTap: () => _playItem(item),
        )),
      ]),
    );
  }

  void _playItem(MuzoItem item) {
    HapticFeedback.lightImpact();
    final audioHandler = ref.read(audioHandlerProvider);
    audioHandler.playMuzoItem(item);
  }
}

// ─── Spinning Album Dialer ─────────────────────────────────────────────────
class _AlbumDialer extends StatefulWidget {
  final List<MuzoItem> items;
  final AnimationController spinController;
  final void Function(MuzoItem) onTap;

  const _AlbumDialer({
    required this.items,
    required this.spinController,
    required this.onTap,
  });

  @override
  State<_AlbumDialer> createState() => _AlbumDialerState();
}

class _AlbumDialerState extends State<_AlbumDialer> {
  double _rotationOffset = 0.0;
  double _lastHapticAngle = 0.0;
  int _selectedIndex = 0;
  bool _isDragging = false;
  double _dragVelocity = 0.0;
  double _momentum = 0.0;

  late int _count;
  late double _angleStep;

  @override
  void initState() {
    super.initState();
    _count = widget.items.length;
    _angleStep = (2 * pi) / _count;
  }

  void _onPanStart(DragStartDetails _) {
    setState(() => _isDragging = true);
    _momentum = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    _dragVelocity = dx;
    setState(() {
      _rotationOffset += dx * 0.012;
      _rotationOffset = _rotationOffset % (2 * pi);
    });
    _checkHaptic();
    _updateSelected();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _momentum = details.velocity.pixelsPerSecond.dx * 0.001;
    _runMomentum();
  }

  void _runMomentum() async {
    while (_momentum.abs() > 0.001 && mounted) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      setState(() {
        _rotationOffset += _momentum;
        _rotationOffset = _rotationOffset % (2 * pi);
        _momentum *= 0.94;
      });
      _checkHaptic();
      _updateSelected();
    }
  }

  void _checkHaptic() {
    final diff = (_rotationOffset - _lastHapticAngle).abs();
    if (diff >= _angleStep * 0.85) {
      HapticFeedback.selectionClick();
      _lastHapticAngle = _rotationOffset;
    }
  }

  void _updateSelected() {
    final normalized = (_rotationOffset % (2 * pi) + 2 * pi) % (2 * pi);
    final idx = ((normalized / _angleStep).round()) % _count;
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialerSize = size.width * 0.85;
    const radius = 0.38;

    return SizedBox(
      height: dialerSize * 0.68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glow ring
          Container(
            width: dialerSize * 0.62,
            height: dialerSize * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: dialerSize * 0.42,
            height: dialerSize * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),

          // Draggable album wheel
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: dialerSize,
              height: dialerSize * 0.68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Album covers arranged in arc
                  ...List.generate(_count, (i) {
                    final angle = (i / _count) * 2 * pi + _rotationOffset - pi / 2;
                    final x = cos(angle) * dialerSize * radius;
                    final y = sin(angle) * dialerSize * radius;
                    final isSelected = i == _selectedIndex;
                    final distFromTop = (angle + pi / 2) % (2 * pi);
                    final visibility = (cos(distFromTop - pi) + 1) / 2;

                    return Positioned(
                      left: dialerSize / 2 + x - (isSelected ? 38 : 28),
                      top: dialerSize * 0.34 + y - (isSelected ? 38 : 28),
                      child: GestureDetector(
                        onTap: () => widget.onTap(widget.items[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          width: isSelected ? 76 : 56,
                          height: isSelected ? 76 : 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white.withValues(alpha: 0.15),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipOval(
                            child: Opacity(
                              opacity: (0.3 + visibility * 0.7).clamp(0.3, 1.0),
                              child: CachedNetworkImage(
                                imageUrl: widget.items[i].thumbnails.isNotEmpty
                                    ? widget.items[i].thumbnails.first.url
                                    : '',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: const Icon(FluentIcons.music_note_2_24_regular, color: Colors.white38, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Center: selected track info
                  Positioned(
                    top: dialerSize * 0.34 - 45,
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            widget.items[_selectedIndex].title,
                            key: ValueKey(_selectedIndex),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDragging ? 'Release to select' : 'Tap to play',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Album Card ────────────────────────────────────────────────────────────
class _AlbumCard extends StatelessWidget {
  final MuzoItem item;
  final VoidCallback onTap;

  const _AlbumCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.first.url : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: thumb,
                width: 140, height: 140,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 140, height: 140,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(FluentIcons.music_note_2_24_regular, color: Colors.white38, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (item.artists.isNotEmpty)
              Text(
                item.artists.first.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton loaders ─────────────────────────────────────────────────────
class _DialerSkeleton extends StatelessWidget {
  const _DialerSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.55,
      child: Center(
        child: SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          width: 140,
          height: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(
        child: Text('No content available', style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}
