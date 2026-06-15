import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class _CachedUrl {
  final String url;
  final DateTime expiry;
  _CachedUrl(this.url, this.expiry);
  bool get isValid => DateTime.now().isBefore(expiry);
}

class StreamExtractionService {
  /// In-memory stream URL cache — avoids re-extracting recently played songs
  static final Map<String, _CachedUrl> _cache = {};

  static final List<YoutubeApiClient> _clients = [
    YoutubeApiClient.androidVr,
    YoutubeApiClient.android,
    YoutubeApiClient.ios,
  ];

  /// Returns a playable audio URL. Tries cache → backend → youtube_explode.
  static Future<String?> getStreamUrl(String videoId) async {
    // 1. Cache hit
    final cached = _cache[videoId];
    if (cached != null && cached.isValid) {
      debugPrint('StreamExtraction[$videoId]: cache hit');
      return cached.url;
    }

    // 2. Backend API (faster, avoids YouTube bot-detection)
    final backendUrl = await _tryBackend(videoId);
    if (backendUrl != null) {
      _cache[videoId] = _CachedUrl(backendUrl, DateTime.now().add(const Duration(minutes: 40)));
      return backendUrl;
    }

    // 3. youtube_explode with multiple client fallback
    final url = await _extractViaExplode(videoId);
    if (url != null) {
      _cache[videoId] = _CachedUrl(url, DateTime.now().add(const Duration(minutes: 40)));
    }
    return url;
  }

  /// Call this when playback fails (403 / stream expired) to force re-extraction
  static void invalidate(String videoId) {
    _cache.remove(videoId);
    debugPrint('StreamExtraction[$videoId]: cache invalidated');
  }

  static void clearCache() => _cache.clear();

  // ── Private helpers ──────────────────────────────────────────────────────

  static Future<String?> _tryBackend(String videoId) async {
    try {
      // Try the MuzoAPI stream endpoint first
      final uri = Uri.parse('https://veltrixcode-ytify.hf.space/api/stream/$videoId');
      final res = await http.get(uri, headers: {'User-Agent': 'YVL/2.2.0'})
          .timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        final url = data?['url'] as String? ?? data?['streamUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          debugPrint('StreamExtraction[$videoId]: backend hit');
          return url;
        }
      }
    } catch (e) {
      debugPrint('StreamExtraction[$videoId]: backend miss — $e');
    }
    return null;
  }

  static Future<String?> _extractViaExplode(String videoId) async {
    for (final client in _clients) {
      final yt = YoutubeExplode();
      try {
        debugPrint('StreamExtraction[$videoId]: trying ${client.runtimeType}');
        final manifest = await yt.videos.streamsClient
            .getManifest(videoId, ytClients: [client])
            .timeout(const Duration(seconds: 18));
        final streams = manifest.audioOnly;
        if (streams.isNotEmpty) {
          final url = streams.withHighestBitrate().url.toString();
          debugPrint('StreamExtraction[$videoId]: success via ${client.runtimeType}');
          return url;
        }
      } catch (e) {
        debugPrint('StreamExtraction[$videoId]: ${client.runtimeType} failed — $e');
      } finally {
        yt.close();
      }
    }
    debugPrint('StreamExtraction[$videoId]: all clients exhausted');
    return null;
  }
}
