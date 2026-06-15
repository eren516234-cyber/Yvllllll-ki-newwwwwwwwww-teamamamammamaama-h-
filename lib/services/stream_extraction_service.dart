import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamExtractionService {
  /// Ordered list of clients to attempt — androidVr first for best success
  /// rate, then fall back through ios, tvHtml5Embedded, and android.
  static const List<YoutubeApiClient> _clientFallbackOrder = [
    YoutubeApiClient.androidVr,
    YoutubeApiClient.ios,
    YoutubeApiClient.tvHtml5Embedded,
    YoutubeApiClient.android,
  ];

  /// Extracts the best audio stream URL, trying multiple YouTube API clients
  /// in order until one succeeds.
  static Future<String?> getStreamUrl(String videoId) async {
    for (final client in _clientFallbackOrder) {
      final yt = YoutubeExplode();
      try {
        debugPrint(
          'StreamExtraction: Trying client ${client.runtimeType} for $videoId',
        );
        final manifest = await yt.videos.streamsClient
            .getManifest(videoId, ytClients: [client])
            .timeout(const Duration(seconds: 20));

        final audioStreams = manifest.audioOnly;
        if (audioStreams.isNotEmpty) {
          final bestAudio = audioStreams.withHighestBitrate();
          debugPrint(
            'StreamExtraction: Success via ${client.runtimeType} — ${bestAudio.url}',
          );
          return bestAudio.url.toString();
        } else {
          debugPrint(
            'StreamExtraction: No audio streams from ${client.runtimeType}, trying next.',
          );
        }
      } catch (e) {
        debugPrint('StreamExtraction: ${client.runtimeType} failed — $e');
      } finally {
        yt.close();
      }
    }

    debugPrint('StreamExtraction: All clients exhausted — returning null.');
    return null;
  }
}
