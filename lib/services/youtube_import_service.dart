import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/services/storage_service.dart';

final youtubeImportServiceProvider = Provider<YoutubeImportService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return YoutubeImportService(storageService);
});

class YoutubeImportProgress {
  final int total;
  final int current;
  final String status;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  YoutubeImportProgress({
    this.total = 0,
    this.current = 0,
    this.status = '',
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
  });

  YoutubeImportProgress copyWith({
    int? total,
    int? current,
    String? status,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
  }) {
    return YoutubeImportProgress(
      total: total ?? this.total,
      current: current ?? this.current,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class YoutubeImportService {
  final StorageService _storageService;

  YoutubeImportService(this._storageService);

  /// Extracts the playlist ID from a YouTube URL or returns the raw input
  /// if it looks like a bare ID already.
  String _extractPlaylistId(String input) {
    input = input.trim();
    // https://www.youtube.com/playlist?list=PLxxxxxx
    // https://youtube.com/playlist?list=PLxxxxxx
    final uri = Uri.tryParse(input);
    if (uri != null) {
      final listParam = uri.queryParameters['list'];
      if (listParam != null && listParam.isNotEmpty) return listParam;
    }
    // Bare playlist ID (starts with PL, RDMM, etc.)
    return input;
  }

  Stream<YoutubeImportProgress> importPlaylist(String urlOrId) async* {
    var progress = YoutubeImportProgress(status: 'Fetching YouTube playlist...');
    yield progress;

    final yt = YoutubeExplode();
    try {
      final playlistId = _extractPlaylistId(urlOrId);
      if (playlistId.isEmpty) {
        yield progress.copyWith(
          hasError: true,
          isComplete: true,
          errorMessage: 'Invalid YouTube playlist URL or ID.',
        );
        return;
      }

      // Fetch playlist metadata
      final Playlist playlist;
      try {
        playlist = await yt.playlists.get(playlistId);
      } catch (e) {
        yield progress.copyWith(
          hasError: true,
          isComplete: true,
          errorMessage: 'Could not fetch playlist. Make sure it is public.',
        );
        return;
      }

      String playlistName = playlist.title.isNotEmpty
          ? playlist.title
          : 'YouTube Import';

      // Collect all video IDs first so we know the total count
      final List<Video> videos = [];
      yield progress.copyWith(status: 'Loading videos...');
      try {
        await for (final video in yt.playlists.getVideos(playlistId)) {
          videos.add(video);
          if (videos.length > 500) break; // Safety cap
        }
      } catch (e) {
        debugPrint('YoutubeImportService: Error fetching video list — $e');
      }

      if (videos.isEmpty) {
        yield progress.copyWith(
          hasError: true,
          isComplete: true,
          errorMessage: 'The YouTube playlist is empty or could not be loaded.',
        );
        return;
      }

      // Deduplicate playlist name
      final existingNames = _storageService.getPlaylistNames();
      String finalName = playlistName;
      int counter = 1;
      while (existingNames.contains(finalName)) {
        finalName = '$playlistName ($counter)';
        counter++;
      }

      yield progress.copyWith(
        total: videos.length,
        status: 'Creating playlist "$finalName"...',
      );

      await _storageService.createPlaylist(finalName);

      int imported = 0;
      for (final video in videos) {
        yield progress.copyWith(
          total: videos.length,
          current: imported,
          status: 'Importing "${video.title}"...',
        );

        try {
          final muzoItem = _videoToMuzoItem(video);
          await _storageService.addToPlaylist(finalName, muzoItem);
        } catch (e) {
          debugPrint('YoutubeImportService: Skipping "${video.title}" — $e');
        }

        imported++;
        yield progress.copyWith(
          total: videos.length,
          current: imported,
          status: 'Imported $imported/${videos.length}',
        );
      }

      yield progress.copyWith(
        total: videos.length,
        current: imported,
        isComplete: true,
        status: 'Import complete! ($imported songs)',
      );
    } catch (e) {
      yield progress.copyWith(
        hasError: true,
        isComplete: true,
        errorMessage: 'Unexpected error: $e',
      );
    } finally {
      yt.close();
    }
  }

  MuzoItem _videoToMuzoItem(Video video) {
    final thumbnailUrl = video.thumbnails.maxResUrl.isNotEmpty
        ? video.thumbnails.maxResUrl
        : video.thumbnails.standardResUrl.isNotEmpty
            ? video.thumbnails.standardResUrl
            : video.thumbnails.highResUrl;

    return MuzoItem(
      videoId: video.id.value,
      title: video.title,
      thumbnails: [
        MuzoThumbnail(url: thumbnailUrl, width: 480, height: 360),
      ],
      artists: [
        MuzoArtist(name: video.author, id: video.channelId.value),
      ],
      resultType: 'video',
      isExplicit: false,
    );
  }
}
