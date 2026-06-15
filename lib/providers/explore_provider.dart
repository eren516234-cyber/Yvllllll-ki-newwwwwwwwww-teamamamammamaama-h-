import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/services/muzo_api_service.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/providers/home_provider.dart';

/// Returns true if the item title/artist contains Devanagari (Hindi) script.
bool _isHindiContent(MuzoItem item) {
  final devanagari = RegExp(r'[\u0900-\u097F]');
  final artistText = (item.artists ?? []).map((a) => a.name).join(' ');
  return devanagari.hasMatch(item.title) || devanagari.hasMatch(artistText);
}

/// Filters a list to remove Hindi content and items with null videoId.
List<MuzoItem> _filterContent(List<MuzoItem> items) =>
    items.where((i) => i.videoId != null && !_isHindiContent(i)).toList();

final trendingContentProvider = FutureProvider<Map<String, List<MuzoItem>>>((
  ref,
) async {
  final storage = ref.read(storageServiceProvider);
  final apiService = MuzoApiService(storage);
  try {
    final content = await apiService.getTrendingContent();
    final filtered = content.map((k, v) => MapEntry(k, _filterContent(v)));
    if ((filtered['songs'] ?? const <MuzoItem>[]).isNotEmpty ||
        (filtered['playlists'] ?? const <MuzoItem>[]).isNotEmpty) {
      return filtered;
    }
  } catch (_) {}

  final fallbackItems = buildInstantHomeSections()
      .expand((section) => section.items)
      .where((item) => item.videoId != null)
      .map((item) => MuzoItem(
            title: item.title,
            videoId: item.videoId,
            resultType: 'song',
            isExplicit: false,
            artists: item.subtitle == null ? null : [MuzoArtist(name: item.subtitle!, id: null)],
            thumbnails: [
              if (item.thumbnailUrl != null)
                MuzoThumbnail(url: item.thumbnailUrl!, width: 480, height: 360),
            ],
          ))
      .toList();
  return {'songs': fallbackItems, 'videos': fallbackItems, 'playlists': fallbackItems.reversed.toList()};
});

final newestSongsProvider = FutureProvider<List<MuzoItem>>((ref) async {
  final content = await ref.watch(trendingContentProvider.future);
  return content['songs'] ?? [];
});

final newestVideosProvider = FutureProvider<List<MuzoItem>>((ref) async {
  final content = await ref.watch(trendingContentProvider.future);
  return content['videos'] ?? [];
});

final trendingPlaylistsProvider = FutureProvider<List<MuzoItem>>((
  ref,
) async {
  final content = await ref.watch(trendingContentProvider.future);
  return content['playlists'] ?? [];
});

// Keep this for backward compatibility if needed, or remove if unused.
// For now, I'll redefine it to combine everything or just deprecate it.
// Since HomeScreen will be rewritten, we might not need this anymore.
// But to avoid breaking other things immediately, let's leave a dummy or combined one.
final exploreContentProvider = FutureProvider<List<MuzoItem>>((ref) async {
  final songs = await ref.watch(newestSongsProvider.future);
  final videos = await ref.watch(newestVideosProvider.future);
  return [...songs, ...videos]..shuffle();
});
