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
    HomeSection(title: 'Trending in USA 🔥', items: [
      song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
      song('H5v3kku4y6Q', 'As It Was', 'Harry Styles'),
      song('JRfuAukYTKg', 'bad guy', 'Billie Eilish'),
      song('TUVcZfQe-Kw', 'Levitating', 'Dua Lipa'),
      song('nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
      song('ApXoWvfEYVU', 'Sunflower', 'Post Malone'),
      song('ZmDBbnmKpqQ', 'drivers license', 'Olivia Rodrigo'),
      song('kgx4WGK0oNU', 'Peaches', 'Justin Bieber'),
      song('KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
    ]),

    HomeSection(title: 'Pop Hits 🎵', items: [
      song('YQHsXMglC9A', 'Hello', 'Adele'),
      song('XqZsoesa55w', 'Someone Like You', 'Adele'),
      song('Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
      song('k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
      song('kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
      song('i_HZpuSqhXc', 'Sugar', 'Maroon 5'),
      song('OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
      song('E07s5ZYygMg', 'Watermelon Sugar', 'Harry Styles'),
      song('IcrBqCFLHIY', 'Attention', 'Charlie Puth'),
      song('nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
    ]),

    HomeSection(title: 'The Weeknd Radio 🌙', items: [
      song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      song('XXYlFuWEuKI', 'Save Your Tears', 'The Weeknd'),
      song('mGVa1rL5VlE', 'Die For You', 'The Weeknd'),
      song('9HDEHj2yzew', 'In The Night', 'The Weeknd'),
      song('4NRXx6U8ekM', 'Starboy', 'The Weeknd ft. Daft Punk'),
      song('ZuJkpwp1aXs', 'Can\'t Feel My Face', 'The Weeknd'),
      song('KEI4qSrkPAs', 'The Hills', 'The Weeknd'),
    ]),

    HomeSection(title: 'Taylor\'s World ✨', items: [
      song('nfWlot6h_JM', 'Shake It Off', 'Taylor Swift'),
      song('ic8j13piAhQ', 'Cruel Summer', 'Taylor Swift'),
      song('jNQXAC9IVRw', 'Anti-Hero', 'Taylor Swift'),
      song('WA4iX5HeTHg', 'Love Story (Taylor\'s Version)', 'Taylor Swift'),
      song('e-ORhEE9VVg', 'Blank Space', 'Taylor Swift'),
      song('q3zqJs7JUCQ', 'You Belong With Me', 'Taylor Swift'),
      song('5anLPw0Efmo', 'Bad Blood', 'Taylor Swift'),
    ]),

    HomeSection(title: 'Hip-Hop Hits 🎤', items: [
      song('ApXoWvfEYVU', 'Sunflower', 'Post Malone & Swae Lee'),
      song('wXhTHyIgQ_U', 'Circles', 'Post Malone'),
      song('iNkqgbwEpzo', 'Rockstar', 'Post Malone ft. 21 Savage'),
      song('xpVfcIGjX9Q', 'God\'s Plan', 'Drake'),
      song('2XN_uD_i1To', 'Stay', 'The Kid LAROI & Justin Bieber'),
      song('gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
      song('gl1aHhXnN1k', 'thank u, next', 'Ariana Grande'),
      song('QYh6mYIJG2Y', '7 rings', 'Ariana Grande'),
    ]),

    HomeSection(title: 'Billie Eilish Essentials 🖤', items: [
      song('JRfuAukYTKg', 'bad guy', 'Billie Eilish'),
      song('5GJWxDKyk3A', 'Happier Than Ever', 'Billie Eilish'),
      song('DyDfgMOUjCI', 'lovely (with Khalid)', 'Billie Eilish'),
      song('pB-5XG-DbAA', 'Ocean Eyes', 'Billie Eilish'),
      song('XDXAEV4bRd0', 'Everything I Wanted', 'Billie Eilish'),
      song('q5PJoq-tEg8', 'when the party\'s over', 'Billie Eilish'),
    ]),

    HomeSection(title: 'Rock Classics 🎸', items: [
      song('7wtfhZwyrcc', 'Demons', 'Imagine Dragons'),
      song('mWRsgZuwf_8', 'Believer', 'Imagine Dragons'),
      song('ktvTqknDobU', 'Radioactive', 'Imagine Dragons'),
      song('dvgZkm1xWPE', 'Yellow', 'Coldplay'),
      song('1G4isv_Fylg', 'The Scientist', 'Coldplay'),
      song('0ytoUuO-qvg', 'Viva la Vida', 'Coldplay'),
      song('09R8_2nJtjg', 'Payphone', 'Maroon 5'),
      song('8UVNT4wvIGY', 'This Love', 'Maroon 5'),
    ]),

    HomeSection(title: 'R&B & Soul 💜', items: [
      song('adLGHcj_GMI', 'Leave The Door Open', 'Silk Sonic'),
      song('92cwKCU8Z5c', 'Unholy', 'Sam Smith & Kim Petras'),
      song('vIyRqZ1pXJU', 'We Don\'t Talk Anymore', 'Charlie Puth'),
      song('KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
      song('oygrmJFKYZY', 'Don\'t Start Now', 'Dua Lipa'),
      song('nfWlot6h_JM', 'Watermelon Sugar (Acoustic)', 'Harry Styles'),
    ]),

    HomeSection(title: 'Workout Bangers ⚡', items: [
      song('kffacxfA7G4', 'Uptown Funk', 'Mark Ronson ft. Bruno Mars'),
      song('fHI8X4OXluQ', 'Blinding Lights', 'The Weeknd'),
      song('7wtfhZwyrcc', 'Demons', 'Imagine Dragons'),
      song('mWRsgZuwf_8', 'Believer', 'Imagine Dragons'),
      song('ktvTqknDobU', 'Radioactive', 'Imagine Dragons'),
      song('OPf0YbXqDm0', '24K Magic', 'Bruno Mars'),
      song('iNkqgbwEpzo', 'Rockstar', 'Post Malone'),
      song('gNi_6U5Pm_o', 'good 4 u', 'Olivia Rodrigo'),
    ]),

    HomeSection(title: 'Late Night Vibes 🌃', items: [
      song('dvgZkm1xWPE', 'Yellow', 'Coldplay'),
      song('1G4isv_Fylg', 'The Scientist', 'Coldplay'),
      song('k0DTIfrJBME', 'Thinking Out Loud', 'Ed Sheeran'),
      song('Zi_XLOBDo_Y', 'Perfect', 'Ed Sheeran'),
      song('XqZsoesa55w', 'Someone Like You', 'Adele'),
      song('nCkpzqqog4k', 'Stay With Me', 'Sam Smith'),
      song('KtlgAro6ba0', 'Someone You Loved', 'Lewis Capaldi'),
      song('DyDfgMOUjCI', 'lovely (with Khalid)', 'Billie Eilish'),
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
      // Filter to English-only and valid items
      final filtered = fresh.map((section) {
        final filteredItems = section.items.where((item) {
          if (item.videoId == null) return false;
          final devanagari = RegExp(r'[\u0900-\u097F]');
          return !devanagari.hasMatch(item.title) &&
              !devanagari.hasMatch(item.subtitle ?? '');
        }).toList();
        return HomeSection(title: section.title, items: filteredItems);
      }).where((s) => s.items.isNotEmpty).toList();

      final filled = filtered.isEmpty ? buildInstantHomeSections() : filtered;

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
      final filtered = fresh.map((section) {
        final filteredItems = section.items.where((item) {
          if (item.videoId == null) return false;
          final devanagari = RegExp(r'[\u0900-\u097F]');
          return !devanagari.hasMatch(item.title) &&
              !devanagari.hasMatch(item.subtitle ?? '');
        }).toList();
        return HomeSection(title: section.title, items: filteredItems);
      }).where((s) => s.items.isNotEmpty).toList();

      final filled = filtered.isEmpty ? buildInstantHomeSections() : filtered;

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
