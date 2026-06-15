import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/services/storage_service.dart';

class SpotifyLikedTrack {
  final String title;
  final String artist;
  final String? albumArt;
  const SpotifyLikedTrack({required this.title, required this.artist, this.albumArt});
}

class ImportProgress {
  final int total;
  final int current;
  final String status;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;
  final int imported;

  const ImportProgress({
    this.total = 0,
    this.current = 0,
    this.status = '',
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.imported = 0,
  });

  ImportProgress copyWith({int? total, int? current, String? status,
      bool? isComplete, bool? hasError, String? errorMessage, int? imported}) =>
    ImportProgress(
      total: total ?? this.total,
      current: current ?? this.current,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      imported: imported ?? this.imported,
    );

  double get progress => total > 0 ? (current / total).clamp(0.0, 1.0) : 0;
}

class SpotifyLikedService {
  final StorageService _storage;
  static const _spotifyBase = 'https://api.spotify.com/v1';
  static const _workerBase = 'https://dawn-violet-2368.shashwat-coding.workers.dev/api';

  SpotifyLikedService(this._storage);

  String? get _token => _storage.spotifyToken;

  Future<List<SpotifyLikedTrack>> fetchLikedTracks({int limit = 200}) async {
    final token = _token;
    if (token == null || token.isEmpty) return [];

    final tracks = <SpotifyLikedTrack>[];
    String? nextUrl = '$_spotifyBase/me/tracks?limit=50';

    while (nextUrl != null && tracks.length < limit) {
      try {
        final res = await http.get(Uri.parse(nextUrl),
          headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 12));
        if (res.statusCode == 401 || res.statusCode != 200) break;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        for (final item in (data['items'] as List? ?? [])) {
          final track = item['track'] as Map?;
          if (track == null) continue;
          final artists = (track['artists'] as List?)
              ?.map((a) => a['name'] as String? ?? '').join(', ') ?? '';
          final images = track['album']?['images'] as List?;
          tracks.add(SpotifyLikedTrack(
            title: track['name'] as String? ?? '',
            artist: artists,
            albumArt: images?.isNotEmpty == true ? images!.first['url'] as String? : null,
          ));
          if (tracks.length >= limit) break;
        }
        nextUrl = data['next'] as String?;
      } catch (e) {
        debugPrint('SpotifyLiked: fetch error — $e');
        break;
      }
    }
    return tracks;
  }

  Future<MuzoItem?> resolveToYouTube(String title, String artist) async {
    try {
      final uri = Uri.parse('$_workerBase/find/track')
          .replace(queryParameters: {'name': title, 'artist': artist});
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        if (data?['videoId'] != null) {
          data!['resultType'] = 'song';
          return MuzoItem.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('SpotifyLiked: resolve error "$title" — $e');
    }
    return null;
  }

  Stream<ImportProgress> importLikedSongs() async* {
    var p = const ImportProgress(status: 'Connecting to Spotify...');
    yield p;

    if (_token == null || _token!.isEmpty) {
      yield p.copyWith(
        hasError: true, isComplete: true,
        errorMessage: 'No Spotify token. Please log in with Spotify first.',
      );
      return;
    }

    final tracks = await fetchLikedTracks(limit: 200);
    if (tracks.isEmpty) {
      yield p.copyWith(
        hasError: true, isComplete: true,
        errorMessage: 'No liked songs found on Spotify.',
      );
      return;
    }

    p = p.copyWith(total: tracks.length, status: 'Creating "Liked Songs ❤️"...');
    yield p;

    const name = 'Liked Songs ❤️';
    try {
      if (!_storage.getPlaylistNames().contains(name)) {
        await _storage.createPlaylist(name);
      }
    } catch (_) {}

    int imported = 0;
    for (int i = 0; i < tracks.length; i++) {
      yield p.copyWith(current: i, status: 'Matching: ${tracks[i].title}', imported: imported);
      final item = await resolveToYouTube(tracks[i].title, tracks[i].artist);
      if (item != null) {
        try { await _storage.addToPlaylist(name, item); imported++; } catch (_) {}
      }
      yield p.copyWith(current: i + 1, imported: imported);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    yield p.copyWith(
      current: tracks.length, imported: imported, isComplete: true,
      status: imported > 0 ? '✓ Imported $imported/${tracks.length} songs!' : 'No songs matched.',
    );
  }
}
