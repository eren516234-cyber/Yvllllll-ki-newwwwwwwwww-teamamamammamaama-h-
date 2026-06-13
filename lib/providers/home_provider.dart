import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/services/ytm_home.dart';
import 'package:yvl/services/storage_service.dart';

const _fallbackThumbBase = 'https://i.ytimg.com/vi';

List<HomeSection> buildInstantHomeSections() {
  HomeItem song(String id, String title, String artist) => HomeItem(
        title: title,
        subtitle: artist,
        thumbnails: [
          {'url': '$_fallbackThumbBase/$id/hqdefault.jpg'}
        ],
        videoId: id,
        type: 'song',
      );

  return [
    HomeSection(title: 'Fresh Hindi Hits', items: [
      song('gvyUuxdRdR4', 'Kesariya', 'Arijit Singh'),
      song('VAdGW7QDJiU', 'Apna Bana Le', 'Arijit Singh'),
      song('ElZfdU54Cp8', 'Heeriye', 'Jasleen Royal'),
      song('KUpwupYj_tY', 'Chaleya', 'Arijit Singh'),
      song('sAzlWScHTc4', 'Raataan Lambiyan', 'Jubin Nautiyal'),
      song('huxhqphtDrM', 'Tum Hi Ho', 'Arijit Singh'),
    ]),
    HomeSection(title: 'Summer Vibes', items: [
      song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
      song('kJQP7kiw5Fk', 'Despacito', 'Luis Fonsi'),
      song('OPf0YbXqDm0', 'Uptown Funk', 'Mark Ronson'),
      song('CevxZvSJLk8', 'Roar', 'Katy Perry'),
      song('09R8_2nJtjg', 'Sugar', 'Maroon 5'),
      song('YQHsXMglC9A', 'Hello', 'Adele'),
    ]),
    HomeSection(title: 'Romantic Mix', items: [
      song('284Ov7ysmfA', 'Shayad', 'Arijit Singh'),
      song('ByIZIKFmHOA', 'Ranjha', 'B Praak'),
      song('atVof3pjT-I', 'Mast Magan', 'Arijit Singh'),
      song('Umqb9KENgmk', 'Pehle Bhi Main', 'Vishal Mishra'),
      song('Y2zc2IeVX_g', 'Tujhe Kitna Chahne Lage', 'Arijit Singh'),
      song('MJyKN-8UncM', 'O Maahi', 'Arijit Singh'),
    ]),
    HomeSection(title: 'Party & Workout', items: [
      song('YxWlaYCA8MU', 'Kala Chashma', 'Amar Arshi'),
      song('gC3RzyY4tLo', 'Ghungroo', 'Arijit Singh'),
      song('pAEtOOV7MBI', 'Kar Gayi Chull', 'Badshah'),
      song('iP87dM6uN3s', 'Illegal Weapon 2.0', 'Jasmine Sandlas'),
      song('nCD2hj6zJEc', 'Bom Diggy Diggy', 'Zack Knight'),
      song('zpsVpnvFfZQ', 'The Breakup Song', 'Pritam'),
    ]),
    HomeSection(title: 'Podcasts & Long Plays', items: [
      song('4xDzrJKXOOY', 'Deep Focus Mix', 'YVL Radio'),
      song('jfKfPfyJRdk', 'lofi hip hop radio', 'Lofi Girl'),
      song('5qap5aO4i9A', 'Chill Beats', 'YVL Sessions'),
      song('DWcJFNfaw9c', 'Ambient Study', 'Music Lab'),
      song('lTRiuFIWV54', 'Calm Talk Radio', 'Podcast Studio'),
      song('mPZkdNFkNps', 'Motivation Daily', 'YVL Podcasts'),
    ]),
    HomeSection(title: 'Global Hits', items: [
      song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      song('TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
      song('H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
      song('kPa7bsKwL-c', 'Flowers', 'Miley Cyrus'),
      song('qN4ooNx77u0', 'Lovely', 'Billie Eilish'),
      song('oygrmJFKYZY', 'Don\'t Start Now', 'Dua Lipa'),
    ]),
  ];
}


final ytmHomeServiceProvider = Provider<YouTubeMusicHomeService>((ref) {
  final service = YouTubeMusicHomeService();
  ref.onDispose(() => service.dispose());
  return service;
});

final homeSectionsProvider =
    AsyncNotifierProvider<HomeSectionsNotifier, List<HomeSection>>(() {
      return HomeSectionsNotifier();
    });

class HomeSectionsNotifier extends AsyncNotifier<List<HomeSection>> {
  @override
  Future<List<HomeSection>> build() async {
    final storage = ref.watch(storageServiceProvider);

    // Attempt to load from cache
    final cached = storage.getHomeCache();
    if (cached.isNotEmpty) {
      // Trigger background refresh
      // Delay slightly to allow the UI to render the cached content first
      Future.delayed(Duration.zero, _refreshBackground);
      return cached;
    }

    // Show a filled, instant home instead of an empty/loading first launch.
    Future.delayed(Duration.zero, _refreshBackground);
    return buildInstantHomeSections();
  }

  Future<void> _refreshBackground() async {
    try {
      final service = ref.read(ytmHomeServiceProvider);
      await service.initialize();
      final fresh = await service.getHome(limit: 12);
      final filled = fresh.isEmpty ? buildInstantHomeSections() : fresh;

      // Update cache
      ref.read(storageServiceProvider).setHomeCache(filled);

      // Update state if mounted
      state = AsyncValue.data(filled);
    } catch (e) {
      // Silent error for background update
    }
  }

  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final service = ref.read(ytmHomeServiceProvider);
      await service.initialize();
      final fresh = await service.getHome(limit: 12);
      final filled = fresh.isEmpty ? buildInstantHomeSections() : fresh;

      ref.read(storageServiceProvider).setHomeCache(filled);
      state = AsyncValue.data(filled);
    } catch (_) {
      state = AsyncValue.data(buildInstantHomeSections());
    }
  }
}

final homeFilterProvider = StateProvider<String>((ref) => 'All');

final filteredHomeSectionsProvider = Provider<AsyncValue<List<HomeSection>>>((
  ref,
) {
  final homeSectionsAsync = ref.watch(homeSectionsProvider);
  final filter = ref.watch(homeFilterProvider);

  return homeSectionsAsync.whenData((sections) {
    if (filter == 'All') return sections;

    return sections
        .map((section) {
          final filteredItems = section.items.where((item) {
            if (filter == 'Songs') {
              return item.type == 'song' || item.videoId != null;
            }
            if (filter == 'Albums') return item.type == 'album';
            if (filter == 'Playlists') return item.type == 'playlist';
            return false;
          }).toList();

          if (filteredItems.isEmpty) return null;
          return HomeSection(title: section.title, items: filteredItems);
        })
        .whereType<HomeSection>()
        .toList();
  });
});
