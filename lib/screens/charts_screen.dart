import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/models/muzo_item.dart';

const _thumb = 'https://i.ytimg.com/vi';

class _ChartSong {
  final String id;
  final String title;
  final String artist;
  final int rank;
  const _ChartSong(this.rank, this.id, this.title, this.artist);
}

const _usaTop = [
  _ChartSong(1, 'fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
  _ChartSong(2, 'JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
  _ChartSong(3, 'nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
  _ChartSong(4, 'H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
  _ChartSong(5, 'JRfuAukYTKg', 'bad guy', 'Billie Eilish'),
  _ChartSong(6, 'TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
  _ChartSong(7, 'ApXoWvfEYVU', 'Sunflower', 'Post Malone'),
  _ChartSong(8, 'ZmDBbnmKpqQ', 'drivers license', 'Olivia Rodrigo'),
  _ChartSong(9, 'YQHsXMglC9A', 'Hello', 'Adele'),
  _ChartSong(10, 'ic8j13piAhQ', 'Cruel Summer', 'Taylor Swift'),
  _ChartSong(11, 'kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
  _ChartSong(12, 'wXhTHyIgQ_U', 'Circles', 'Post Malone'),
  _ChartSong(13, 'xpVfcIGjX9Q', "God's Plan", 'Drake'),
  _ChartSong(14, 'KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
  _ChartSong(15, 'gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
  _ChartSong(16, 'kgx4WGK0oNU', 'Peaches', 'Justin Bieber'),
  _ChartSong(17, 'E07s5ZYygMg', 'Watermelon Sugar', 'Harry Styles'),
  _ChartSong(18, 'gl1aHhXnN1k', 'thank u, next', 'Ariana Grande'),
  _ChartSong(19, 'OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
  _ChartSong(20, 'XXYlFuWEuKI', 'Save Your Tears', 'The Weeknd'),
];

const _globalTop = [
  _ChartSong(1, 'JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
  _ChartSong(2, 'fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
  _ChartSong(3, 'Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
  _ChartSong(4, 'dvgZkm1xWPE', 'Yellow', 'Coldplay'),
  _ChartSong(5, 'XqZsoesa55w', 'Someone Like You', 'Adele'),
  _ChartSong(6, 'TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
  _ChartSong(7, 'ApXoWvfEYVU', 'Sunflower', 'Post Malone & Swae Lee'),
  _ChartSong(8, '7wtfhZwyrcc', 'Demons', 'Imagine Dragons'),
  _ChartSong(9, 'k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
  _ChartSong(10, 'nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
  _ChartSong(11, 'mWRsgZuwf_8', 'Believer', 'Imagine Dragons'),
  _ChartSong(12, 'oygrmJFKYZY', "Don't Start Now", 'Dua Lipa'),
  _ChartSong(13, 'i_HZpuSqhXc', 'Sugar', 'Maroon 5'),
  _ChartSong(14, 'KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
  _ChartSong(15, '5GJWxDKyk3A', 'Happier Than Ever', 'Billie Eilish'),
  _ChartSong(16, '1G4isv_Fylg', 'The Scientist', 'Coldplay'),
  _ChartSong(17, 'adLGHcj_GMI', 'Leave The Door Open', 'Silk Sonic'),
  _ChartSong(18, 'IcrBqCFLHIY', 'Attention', 'Charlie Puth'),
  _ChartSong(19, '2XN_uD_i1To', 'Stay', 'The Kid LAROI & Justin Bieber'),
  _ChartSong(20, 'QYh6mYIJG2Y', '7 rings', 'Ariana Grande'),
];

const _popTop = [
  _ChartSong(1, 'nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
  _ChartSong(2, 'H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
  _ChartSong(3, 'JRfuAukYTKg', 'bad guy', 'Billie Eilish'),
  _ChartSong(4, 'TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
  _ChartSong(5, 'ic8j13piAhQ', 'Cruel Summer', 'Taylor Swift'),
  _ChartSong(6, 'Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
  _ChartSong(7, 'ZmDBbnmKpqQ', 'drivers license', 'Olivia Rodrigo'),
  _ChartSong(8, 'gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
  _ChartSong(9, 'YQHsXMglC9A', 'Hello', 'Adele'),
  _ChartSong(10, 'kgx4WGK0oNU', 'Peaches', 'Justin Bieber'),
  _ChartSong(11, 'oygrmJFKYZY', "Don't Start Now", 'Dua Lipa'),
  _ChartSong(12, 'E07s5ZYygMg', 'Watermelon Sugar', 'Harry Styles'),
  _ChartSong(13, 'gl1aHhXnN1k', 'thank u, next', 'Ariana Grande'),
  _ChartSong(14, 'QYh6mYIJG2Y', '7 rings', 'Ariana Grande'),
  _ChartSong(15, 'pB-5XG-DbAA', 'Ocean Eyes', 'Billie Eilish'),
  _ChartSong(16, 'XqZsoesa55w', 'Someone Like You', 'Adele'),
  _ChartSong(17, 'IcrBqCFLHIY', 'Attention', 'Charlie Puth'),
  _ChartSong(18, 'KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
  _ChartSong(19, '5GJWxDKyk3A', 'Happier Than Ever', 'Billie Eilish'),
  _ChartSong(20, 'k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
];

const _hipHopTop = [
  _ChartSong(1, 'ApXoWvfEYVU', 'Sunflower', 'Post Malone & Swae Lee'),
  _ChartSong(2, 'wXhTHyIgQ_U', 'Circles', 'Post Malone'),
  _ChartSong(3, 'xpVfcIGjX9Q', "God's Plan", 'Drake'),
  _ChartSong(4, 'iNkqgbwEpzo', 'Rockstar', 'Post Malone ft. 21 Savage'),
  _ChartSong(5, 'gl1aHhXnN1k', 'thank u, next', 'Ariana Grande'),
  _ChartSong(6, 'QYh6mYIJG2Y', '7 rings', 'Ariana Grande'),
  _ChartSong(7, '2XN_uD_i1To', 'Stay', 'The Kid LAROI & Justin Bieber'),
  _ChartSong(8, 'kgx4WGK0oNU', 'Peaches', 'Justin Bieber'),
  _ChartSong(9, 'gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
  _ChartSong(10, 'adLGHcj_GMI', 'Leave The Door Open', 'Silk Sonic'),
  _ChartSong(11, '92cwKCU8Z5c', 'Unholy', 'Sam Smith & Kim Petras'),
  _ChartSong(12, 'kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
  _ChartSong(13, 'OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
  _ChartSong(14, 'ZmDBbnmKpqQ', 'drivers license', 'Olivia Rodrigo'),
  _ChartSong(15, 'XXYlFuWEuKI', 'Save Your Tears', 'The Weeknd'),
];

const _rockTop = [
  _ChartSong(1, '7wtfhZwyrcc', 'Demons', 'Imagine Dragons'),
  _ChartSong(2, 'mWRsgZuwf_8', 'Believer', 'Imagine Dragons'),
  _ChartSong(3, 'ktvTqknDobU', 'Radioactive', 'Imagine Dragons'),
  _ChartSong(4, 'dvgZkm1xWPE', 'Yellow', 'Coldplay'),
  _ChartSong(5, '1G4isv_Fylg', 'The Scientist', 'Coldplay'),
  _ChartSong(6, '0ytoUuO-qvg', 'Viva la Vida', 'Coldplay'),
  _ChartSong(7, 'i_HZpuSqhXc', 'Sugar', 'Maroon 5'),
  _ChartSong(8, '09R8_2nJtjg', 'Payphone', 'Maroon 5'),
  _ChartSong(9, '8UVNT4wvIGY', 'This Love', 'Maroon 5'),
  _ChartSong(10, 'JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
];

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _play(_ChartSong song) {
    HapticFeedback.lightImpact();
    final muzo = MuzoItem(
      title: song.title,
      resultType: 'song',
      isExplicit: false,
      artists: [MuzoArtist(name: song.artist)],
      thumbnails: [MuzoThumbnail(url: '$_thumb/${song.id}/hqdefault.jpg', width: 480, height: 360)],
      videoId: song.id,
    );
    ref.read(audioHandlerProvider).playVideo(muzo);
  }

  void _playAll(List<_ChartSong> songs) {
    HapticFeedback.mediumImpact();
    final items = songs.map((s) => MuzoItem(
      title: s.title,
      resultType: 'song',
      isExplicit: false,
      artists: [MuzoArtist(name: s.artist)],
      thumbnails: [MuzoThumbnail(url: '$_thumb/${s.id}/hqdefault.jpg', width: 480, height: 360)],
      videoId: s.id,
    )).toList();
    if (items.isEmpty) return;
    final handler = ref.read(audioHandlerProvider);
    handler.playVideo(items.first);
    if (items.length > 1) {
      for (final item in items.skip(1)) {
        handler.addToQueue(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Charts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFFFF2D55),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: theme.colorScheme.surface,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: '🇺🇸 USA'),
                    Tab(text: '🌍 Global'),
                    Tab(text: '🎵 Pop'),
                    Tab(text: '🎤 Hip-Hop'),
                    Tab(text: '🎸 Rock'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Chart Lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChartList(songs: _usaTop, onPlay: _play, onPlayAll: _playAll, label: 'USA Top 20'),
                  _ChartList(songs: _globalTop, onPlay: _play, onPlayAll: _playAll, label: 'Global Top 20'),
                  _ChartList(songs: _popTop, onPlay: _play, onPlayAll: _playAll, label: 'Pop Top 20'),
                  _ChartList(songs: _hipHopTop, onPlay: _play, onPlayAll: _playAll, label: 'Hip-Hop Top 15'),
                  _ChartList(songs: _rockTop, onPlay: _play, onPlayAll: _playAll, label: 'Rock Top 10'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartList extends StatelessWidget {
  final List<_ChartSong> songs;
  final void Function(_ChartSong) onPlay;
  final void Function(List<_ChartSong>) onPlayAll;
  final String label;

  const _ChartList({
    required this.songs,
    required this.onPlay,
    required this.onPlayAll,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 200),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onPlayAll(songs),
                  child: Container(
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
                        Text('Play All',
                          style: TextStyle(
                            color: theme.colorScheme.surface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final song = songs[i - 1];
        final isTop3 = song.rank <= 3;
        return GestureDetector(
          onTap: () => onPlay(song),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isTop3
                  ? theme.colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${song.rank}',
                    style: TextStyle(
                      color: isTop3
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: isTop3 ? 15 : 13,
                      fontWeight: isTop3 ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: '$_thumb/${song.id}/hqdefault.jpg',
                    width: 52, height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52, height: 52,
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(FluentIcons.music_note_2_24_regular,
                          size: 24, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
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
          ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: (i - 1) * 25)),
        );
      },
    );
  }
}
