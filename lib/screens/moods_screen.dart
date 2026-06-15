import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/models/muzo_item.dart';

const _thumb = 'https://i.ytimg.com/vi';

class _MoodPlaylist {
  final String name;
  final String emoji;
  final Color color;
  final String description;
  final List<_Song> songs;

  const _MoodPlaylist({
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
    required this.songs,
  });
}

class _Song {
  final String id;
  final String title;
  final String artist;
  const _Song(this.id, this.title, this.artist);
}

final _moodPlaylists = [
  _MoodPlaylist(
    name: 'Focus & Study',
    emoji: '📚',
    color: const Color(0xFF3F51B5),
    description: 'Deep focus music for productivity',
    songs: [
      _Song('dvgZkm1xWPE', 'Yellow', 'Coldplay'),
      _Song('1G4isv_Fylg', 'The Scientist', 'Coldplay'),
      _Song('k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
      _Song('Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
      _Song('KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
      _Song('nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
      _Song('DyDfgMOUjCI', 'lovely (with Khalid)', 'Billie Eilish'),
    ],
  ),
  _MoodPlaylist(
    name: 'Workout',
    emoji: '⚡',
    color: const Color(0xFFFF5722),
    description: 'High energy bangers to push your limits',
    songs: [
      _Song('kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
      _Song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      _Song('7wtfhZwyrcc', 'Demons', 'Imagine Dragons'),
      _Song('mWRsgZuwf_8', 'Believer', 'Imagine Dragons'),
      _Song('ktvTqknDobU', 'Radioactive', 'Imagine Dragons'),
      _Song('OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
      _Song('iNkqgbwEpzo', 'Rockstar', 'Post Malone'),
      _Song('gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
    ],
  ),
  _MoodPlaylist(
    name: 'Chill Vibes',
    emoji: '🌊',
    color: const Color(0xFF00BCD4),
    description: 'Laid-back tracks to unwind',
    songs: [
      _Song('TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
      _Song('H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
      _Song('E07s5ZYygMg', 'Watermelon Sugar', 'Harry Styles'),
      _Song('5GJWxDKyk3A', 'Happier Than Ever', 'Billie Eilish'),
      _Song('pB-5XG-DbAA', 'Ocean Eyes', 'Billie Eilish'),
      _Song('IcrBqCFLHIY', 'Attention', 'Charlie Puth'),
    ],
  ),
  _MoodPlaylist(
    name: 'Party Mode',
    emoji: '🎉',
    color: const Color(0xFFE91E63),
    description: 'Certified party anthems only',
    songs: [
      _Song('nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
      _Song('kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
      _Song('OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
      _Song('QYh6mYIJG2Y', '7 rings', 'Ariana Grande'),
      _Song('JRfuAukYTKg', 'bad guy', 'Billie Eilish'),
      _Song('gl1aHhXnN1k', 'thank u, next', 'Ariana Grande'),
      _Song('adLGHcj_GMI', 'Leave The Door Open', 'Silk Sonic'),
    ],
  ),
  _MoodPlaylist(
    name: 'Heartbreak',
    emoji: '💔',
    color: const Color(0xFF9C27B0),
    description: 'Songs that understand how you feel',
    songs: [
      _Song('YQHsXMglC9A', 'Hello', 'Adele'),
      _Song('XqZsoesa55w', 'Someone Like You', 'Adele'),
      _Song('KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
      _Song('ZmDBbnmKpqQ', 'drivers license', 'Olivia Rodrigo'),
      _Song('nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
      _Song('DyDfgMOUjCI', 'lovely (with Khalid)', 'Billie Eilish'),
      _Song('XDXAEV4bRd0', 'Everything I Wanted', 'Billie Eilish'),
    ],
  ),
  _MoodPlaylist(
    name: 'Romance',
    emoji: '💕',
    color: const Color(0xFFFF4081),
    description: 'Perfect tracks for romantic moments',
    songs: [
      _Song('Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
      _Song('k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
      _Song('adLGHcj_GMI', 'Leave The Door Open', 'Silk Sonic'),
      _Song('dvgZkm1xWPE', 'Yellow', 'Coldplay'),
      _Song('1G4isv_Fylg', 'The Scientist', 'Coldplay'),
      _Song('nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
    ],
  ),
  _MoodPlaylist(
    name: 'Road Trip',
    emoji: '🚗',
    color: const Color(0xFFFF9800),
    description: 'Windows down, volume up anthems',
    songs: [
      _Song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
      _Song('kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
      _Song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      _Song('ic8j13piAhQ', 'Cruel Summer', 'Taylor Swift'),
      _Song('nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
      _Song('OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
      _Song('ApXoWvfEYVU', 'Sunflower', 'Post Malone'),
    ],
  ),
  _MoodPlaylist(
    name: 'Morning Energy',
    emoji: '☀️',
    color: const Color(0xFFFFC107),
    description: 'Start your day on the right note',
    songs: [
      _Song('H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
      _Song('TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
      _Song('E07s5ZYygMg', 'Watermelon Sugar', 'Harry Styles'),
      _Song('kgx4WGK0oNU', 'Peaches', 'Justin Bieber'),
      _Song('gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
      _Song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
    ],
  ),
];

class MoodsScreen extends ConsumerStatefulWidget {
  const MoodsScreen({super.key});

  @override
  ConsumerState<MoodsScreen> createState() => _MoodsScreenState();
}

class _MoodsScreenState extends ConsumerState<MoodsScreen> {
  _MoodPlaylist? _selectedMood;

  void _playAll(_MoodPlaylist mood) {
    HapticFeedback.mediumImpact();
    final handler = ref.read(audioHandlerProvider);
    for (int i = 0; i < mood.songs.length; i++) {
      final s = mood.songs[i];
      final item = MuzoItem(
        title: s.title,
        resultType: 'song',
        isExplicit: false,
        artists: [MuzoArtist(name: s.artist)],
        thumbnails: [MuzoThumbnail(url: '$_thumb/${s.id}/hqdefault.jpg', width: 480, height: 360)],
        videoId: s.id,
      );
      if (i == 0) {
        handler.playVideo(item);
      } else {
        handler.addToQueue(item);
      }
    }
  }

  void _playSong(_Song s) {
    HapticFeedback.lightImpact();
    final item = MuzoItem(
      title: s.title,
      resultType: 'song',
      isExplicit: false,
      artists: [MuzoArtist(name: s.artist)],
      thumbnails: [MuzoThumbnail(url: '$_thumb/${s.id}/hqdefault.jpg', width: 480, height: 360)],
      videoId: s.id,
    );
    ref.read(audioHandlerProvider).playVideo(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FluentIcons.arrow_left_24_regular, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Moods & Vibes',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: _selectedMood == null
          ? _buildMoodGrid(context, theme)
          : _buildMoodDetail(context, theme, _selectedMood!),
    );
  }

  Widget _buildMoodGrid(BuildContext context, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 200),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _moodPlaylists.length,
      itemBuilder: (ctx, i) {
        final mood = _moodPlaylists[i];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedMood = mood);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  mood.color.withValues(alpha: 0.85),
                  mood.color.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  Text(
                    mood.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mood.songs.length} songs',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 50)).scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildMoodDetail(BuildContext context, ThemeData theme, _MoodPlaylist mood) {
    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mood.color.withValues(alpha: 0.85), mood.color.withValues(alpha: 0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedMood = null),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mood.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _playAll(mood),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: mood.color, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Play All',
                        style: TextStyle(
                          color: mood.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Song list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
            physics: const BouncingScrollPhysics(),
            itemCount: mood.songs.length,
            itemBuilder: (ctx, i) {
              final s = mood.songs[i];
              return GestureDetector(
                onTap: () => _playSong(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.artist,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
