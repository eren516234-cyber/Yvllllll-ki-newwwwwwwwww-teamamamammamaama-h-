import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single syllable/word within a karaoke lyric line
class KaraokeSyllable {
  final Duration time;
  final Duration duration;
  final String text;
  const KaraokeSyllable({required this.time, required this.duration, required this.text});
}

/// A complete lyric line with optional word-level timing for karaoke
class KaraokeLine {
  final Duration lineStart;
  final String fullText;
  final List<KaraokeSyllable> syllables;
  const KaraokeLine({required this.lineStart, required this.fullText, required this.syllables});
}

class Lyrics {
  final int id;
  final String name;
  final String trackName;
  final String artistName;
  final String albumName;
  final int duration;
  final bool instrumental;
  final String plainLyrics;
  final String syncedLyrics;
  /// Non-null when Atomix returns type:Word — enables karaoke word highlighting
  final List<KaraokeLine>? karaokeLines;

  Lyrics({
    required this.id,
    required this.name,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.instrumental,
    required this.plainLyrics,
    required this.syncedLyrics,
    this.karaokeLines,
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      trackName: json['trackName'] ?? '',
      artistName: json['artistName'] ?? '',
      albumName: json['albumName'] ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      instrumental: json['instrumental'] ?? false,
      plainLyrics: json['plainLyrics'] ?? '',
      syncedLyrics: json['syncedLyrics'] ?? '',
    );
  }
}

final lyricsServiceProvider = Provider((ref) => LyricsService());

class LyricsService {
  static const String _lrcLibBaseUrl = 'https://lrclib.net/api';

  Future<Lyrics?> fetchLyrics(
    String trackName,
    String artistName,
    int duration,
  ) async {
    final cleanTrack = _cleanTitle(trackName);
    final cleanArtist = _cleanTitle(artistName);

    // 1. Try Atomix Lyrics API (primary — supports karaoke word-level timing)
    final atomixResult = await _tryAtomix(cleanTrack, cleanArtist, duration);
    if (atomixResult != null) return atomixResult;

    // 2. Fallback: LRCLIB exact match
    final lrcLibResult = await _tryLrcLib(cleanTrack, cleanArtist, duration);
    if (lrcLibResult != null) return lrcLibResult;

    // 3. Fallback: PaxSenix lyrics API
    final paxResult = await _tryPaxSenix(cleanTrack, cleanArtist, duration);
    if (paxResult != null) return paxResult;

    // 4. Fallback: lyrics.ovh (plain lyrics only, no sync)
    final ovhResult = await _tryLyricsOvh(cleanTrack, cleanArtist);
    if (ovhResult != null) return ovhResult;

    // 5. Last resort: LRCLIB search with fuzzy duration matching
    return _searchLyrics(cleanTrack, cleanArtist, duration);
  }

  // ---------------------------------------------------------------------------
  // Provider implementations
  // ---------------------------------------------------------------------------

  Future<Lyrics?> _tryAtomix(String track, String artist, int duration) async {
    try {
      final atomixUri = Uri.parse('https://lyricsplus.atomix.one/v2/lyrics/get').replace(
        queryParameters: {'title': track, 'artist': artist, 'duration': duration.toString()},
      );

      debugPrint('LyricsService [Atomix]: GET $atomixUri');
      final res = await http.get(atomixUri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final String responseType = data['type'] ?? '';
        final bool isSupported = (responseType == 'Line' || responseType == 'Word') &&
            data['lyrics'] != null;

        if (isSupported) {
          final List<dynamic> lines = data['lyrics'];
          final StringBuffer syncedBuffer = StringBuffer();
          final StringBuffer plainBuffer = StringBuffer();
          final List<KaraokeLine>? karaokeLines = responseType == 'Word' ? [] : null;

          for (var line in lines) {
            final int rawMs = line['time'] ?? 0;
            final String text = (line['text'] as String? ?? '').trim();
            if (text.isEmpty) continue;

            final lineDuration = Duration(milliseconds: rawMs);
            final minutes = lineDuration.inMinutes.toString().padLeft(2, '0');
            final seconds = (lineDuration.inSeconds % 60).toString().padLeft(2, '0');
            final hundredths = ((lineDuration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

            syncedBuffer.writeln('[$minutes:$seconds.$hundredths] $text');
            plainBuffer.writeln(text);

            if (responseType == 'Word') {
              final List<dynamic> syllabi = (line['syllabus'] as List<dynamic>?) ?? [];
              final List<KaraokeSyllable> syllables = syllabi.map((s) {
                return KaraokeSyllable(
                  time: Duration(milliseconds: (s['time'] as num?)?.toInt() ?? rawMs),
                  duration: Duration(milliseconds: (s['duration'] as num?)?.toInt() ?? 300),
                  text: s['text'] as String? ?? '',
                );
              }).toList();
              karaokeLines!.add(KaraokeLine(
                lineStart: Duration(milliseconds: rawMs),
                fullText: text,
                syllables: syllables.isEmpty
                    ? [KaraokeSyllable(time: Duration(milliseconds: rawMs), duration: const Duration(milliseconds: 2000), text: text)]
                    : syllables,
              ));
            }
          }

          if (plainBuffer.isNotEmpty) {
            debugPrint('LyricsService [Atomix]: Found (type: $responseType)');
            return Lyrics(
              id: 0,
              name: track,
              trackName: track,
              artistName: artist,
              albumName: '',
              duration: duration,
              instrumental: false,
              plainLyrics: plainBuffer.toString(),
              syncedLyrics: syncedBuffer.toString(),
              karaokeLines: karaokeLines,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('LyricsService [Atomix]: Error — $e');
    }
    return null;
  }

  Future<Lyrics?> _tryLrcLib(String track, String artist, int duration) async {
    try {
      final uri = Uri.parse('$_lrcLibBaseUrl/get').replace(
        queryParameters: {'track_name': track, 'artist_name': artist},
      );

      debugPrint('LyricsService [LRCLIB]: GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('LyricsService [LRCLIB]: status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['plainLyrics'] != null || data['syncedLyrics'] != null) {
          debugPrint('LyricsService [LRCLIB]: Found exact match');
          return Lyrics.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('LyricsService [LRCLIB]: Error — $e');
    }
    return null;
  }

  Future<Lyrics?> _tryPaxSenix(String track, String artist, int duration) async {
    try {
      final uri = Uri.parse('https://api.paxsenix.biz.id/lyrics').replace(
        queryParameters: {'title': track, 'artist': artist},
      );

      debugPrint('LyricsService [PaxSenix]: GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // PaxSenix returns {status: bool, lrc: "...", lyrics: "..."}
        final String? lrc = data['lrc'] as String?;
        final String? plain = data['lyrics'] as String?;

        if ((lrc != null && lrc.isNotEmpty) || (plain != null && plain.isNotEmpty)) {
          debugPrint('LyricsService [PaxSenix]: Found lyrics');
          return Lyrics(
            id: 0,
            name: track,
            trackName: track,
            artistName: artist,
            albumName: '',
            duration: duration,
            instrumental: false,
            plainLyrics: plain ?? _stripLrcTimestamps(lrc ?? ''),
            syncedLyrics: lrc ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('LyricsService [PaxSenix]: Error — $e');
    }
    return null;
  }

  Future<Lyrics?> _tryLyricsOvh(String track, String artist) async {
    try {
      final encodedArtist = Uri.encodeComponent(artist);
      final encodedTrack = Uri.encodeComponent(track);
      final uri = Uri.parse('https://api.lyrics.ovh/v1/$encodedArtist/$encodedTrack');

      debugPrint('LyricsService [lyrics.ovh]: GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? lyrics = data['lyrics'] as String?;
        if (lyrics != null && lyrics.trim().isNotEmpty) {
          debugPrint('LyricsService [lyrics.ovh]: Found plain lyrics');
          return Lyrics(
            id: 0,
            name: track,
            trackName: track,
            artistName: artist,
            albumName: '',
            duration: 0,
            instrumental: false,
            plainLyrics: lyrics,
            syncedLyrics: '',
          );
        }
      }
    } catch (e) {
      debugPrint('LyricsService [lyrics.ovh]: Error — $e');
    }
    return null;
  }

  Future<Lyrics?> _searchLyrics(
    String track,
    String artist,
    int duration,
  ) async {
    try {
      final uri = Uri.parse(
        '$_lrcLibBaseUrl/search',
      ).replace(queryParameters: {'track_name': track, 'artist_name': artist});
      debugPrint('LyricsService [LRCLIB Search]: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        debugPrint('LyricsService [LRCLIB Search]: ${list.length} results');

        if (list.isEmpty) return null;

        Lyrics? bestMatch;
        int minDiff = 1000000;

        for (var item in list) {
          final l = Lyrics.fromJson(item);
          final diff = (l.duration - duration).abs();

          if (l.plainLyrics.isEmpty && l.syncedLyrics.isEmpty) continue;

          if (diff < minDiff) {
            minDiff = diff;
            bestMatch = l;
          }
        }

        if ((duration == 0 || minDiff <= 30) && bestMatch != null) {
          debugPrint(
            'LyricsService [LRCLIB Search]: Best match "${bestMatch.trackName}" diff ${minDiff}s',
          );
          return bestMatch;
        } else {
          debugPrint(
            'LyricsService [LRCLIB Search]: No match within tolerance (best diff: ${minDiff}s)',
          );
        }
      } else {
        debugPrint('LyricsService [LRCLIB Search]: status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LyricsService [LRCLIB Search]: Error — $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Strip LRC timestamp tags to produce plain text from an LRC string.
  String _stripLrcTimestamps(String lrc) {
    return lrc
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^\[\d+:\d+\.\d+\]\s*'), ''))
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  String _cleanTitle(String text) {
    debugPrint('LyricsService: Cleaning title: "$text"');
    if (text.isEmpty) return text;

    try {
      var clean = text;

      final videoPattern = RegExp(
        r'\s*[\(\[](official|video|audio|lyrics|lyric|hd|hq|4k|mv|music video|full audio)[\)\]]',
        caseSensitive: false,
      );
      clean = clean.replaceAll(videoPattern, '');

      final featPattern = RegExp(
        r'\s+(ft\.|feat\.|featuring)\s+',
        caseSensitive: false,
      );
      if (featPattern.hasMatch(clean)) {
        clean = clean.split(featPattern).first;
      }

      clean = clean.replaceAll(' - Topic', '');

      final result = clean.trim();
      debugPrint('LyricsService: Cleaned: "$result"');
      return result;
    } catch (e) {
      debugPrint('LyricsService: Error cleaning "$text": $e');
      return text;
    }
  }
}
