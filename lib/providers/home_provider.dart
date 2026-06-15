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

  HomeItem podcast(String id, String title, String artist) => HomeItem(
        title: title,
        subtitle: artist,
        thumbnails: [
          {'url': '$_fallbackThumbBase/$id/hqdefault.jpg'}
        ],
        videoId: id,
        type: 'podcast',
      );

  HomeItem album(String id, String title, String artist) => HomeItem(
        title: title,
        subtitle: artist,
        thumbnails: [
          {'url': '$_fallbackThumbBase/$id/hqdefault.jpg'}
        ],
        videoId: id,
        type: 'album',
      );

  return [
    HomeSection(title: 'Songs', items: [
      song('gvyUuxdRdR4', 'Kesariya', 'Arijit Singh'),
      song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
      song('KUpwupYj_tY', 'Chaleya', 'Arijit Singh'),
      song('kJQP7kiw5Fk', 'Despacito', 'Luis Fonsi'),
      song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      song('TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
      song('H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
      song('VAdGW7QDJiU', 'Apna Bana Le', 'Arijit Singh'),
    ]),
    HomeSection(title: 'Podcasts', items: [
      podcast('4xDzrJKXOOY', 'Deep Focus Mix', 'YVL Radio'),
      podcast('jfKfPfyJRdk', 'Lofi Hip Hop Radio', 'Lofi Girl'),
      podcast('5qap5aO4i9A', 'Chill Beats', 'YVL Sessions'),
      podcast('DWcJFNfaw9c', 'Ambient Study', 'Music Lab'),
      podcast('lTRiuFIWV54', 'Calm Talk Radio', 'Podcast Studio'),
      podcast('mPZkdNFkNps', 'Motivation Daily', 'YVL Podcasts'),
    ]),
    HomeSection(title: 'Albums', items: [
      album('kPa7bsKwL-c', 'Flowers (Album)', 'Miley Cyrus'),
      album('oygrmJFKYZY', 'Future Nostalgia', 'Dua Lipa'),
      album('qN4ooNx77u0', 'When We All Fall Asleep', 'Billie Eilish'),
      album('Y2zc2IeVX_g', 'Arijit Singh Hits', 'Arijit Singh'),
      album('OPf0YbXqDm0', 'Uptown Special', 'Mark Ronson'),
      album('09R8_2nJtjg', 'V', 'Maroon 5'),
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

    final cached = storage.getHomeCache();
    if (cached.isNotEmpty) {
      Future.delayed(Duration.zero, _refreshBackground);
      return cached;
    }

    Future.delayed(Duration.zero, _refreshBackground);
    return buildInstantHomeSections();
  }

  Future<void> _refreshBackground() async {
    try {
      final service = ref.read(ytmHomeServiceProvider);
      await service.initialize();
      final fresh = await service.getHome(limit: 12);
      final filled = fresh.isEmpty ? buildInstantHomeSections() : fresh;

      ref.read(storageServiceProvider).setHomeCache(filled);
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
              return item.type == 'song' || (item.videoId != null && item.type != 'podcast' && item.type != 'album');
            }
            if (filter == 'Podcasts') return item.type == 'podcast';
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
