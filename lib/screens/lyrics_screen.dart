import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:yvl/services/lyrics_service.dart';
import 'package:yvl/widgets/lyrics_view.dart';
import 'package:yvl/widgets/bubble_lyrics_view.dart';
import 'package:yvl/widgets/karaoke_view.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/providers/theme_provider.dart';

enum LyricsMode { classic, bubble, karaoke, wave, personal, neon, float }

class LyricsScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final int durationSeconds;

  const LyricsScreen({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.durationSeconds,
  });

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen>
    with SingleTickerProviderStateMixin {
  Lyrics? _lyrics;
  bool _isLoading = true;
  LyricsMode _mode = LyricsMode.classic;
  File? _personalBgImage;
  Color _lyricsColor = Colors.white;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _fetchLyrics();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final lyrics = await ref
          .read(lyricsServiceProvider)
          .fetchLyrics(widget.title, widget.artist, widget.durationSeconds);
      if (mounted) setState(() { _lyrics = lyrics; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPersonalBg() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null && mounted) setState(() => _personalBgImage = File(img.path));
  }

  void _showColorPicker() {
    final colors = [
      Colors.white,
      Colors.yellowAccent,
      const Color(0xFF00E5FF),
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lyrics Color', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((c) => GestureDetector(
                onTap: () { setState(() => _lyricsColor = c); Navigator.pop(context); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _lyricsColor == c ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: _lyricsColor == c
                        ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 12)]
                        : [],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final accentColor = ref.watch(currentPaletteProvider).asData?.value?.darkVibrantColor?.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(FluentIcons.chevron_down_24_regular, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text('Lyrics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${widget.title} • ${widget.artist}',
                style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.normal),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_mode == LyricsMode.personal)
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: Colors.white),
              onPressed: _showColorPicker,
            ),
          IconButton(
            icon: const Icon(FluentIcons.arrow_sync_24_regular, color: Colors.white),
            tooltip: 'Re-sync',
            onPressed: () { HapticFeedback.lightImpact(); _fetchLyrics(); },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(accentColor)),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _lyrics == null
                          ? _buildNotFound()
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                  child: child,
                                ),
                              ),
                              child: _buildModeWidget(audioHandler, accentColor),
                            ),
                ),
                if (_lyrics != null) _buildModeSelector(accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color? accentColor) {
    if (_mode == LyricsMode.neon) {
      return Stack(
        children: [
          Container(color: Colors.black),
          Positioned(
            top: -100,
            left: -80,
            child: _NeonBlob(color: accentColor ?? const Color(0xFF00E5FF), size: 300),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _NeonBlob(color: Colors.purpleAccent, size: 250),
          ),
        ],
      );
    }
    if (_mode == LyricsMode.float) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0D1A),
              accentColor?.withValues(alpha: 0.3) ?? const Color(0xFF1A0D2E),
              const Color(0xFF0A0A14),
            ],
          ),
        ),
      );
    }
    if (_mode == LyricsMode.personal && _personalBgImage != null) {
      return Stack(
        children: [
          Image.file(_personalBgImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Container(color: Colors.black.withValues(alpha: 0.4)),
        ],
      );
    }
    return Stack(
      children: [
        if (widget.thumbnailUrl != null)
          RepaintBoundary(
            child: Image.network(widget.thumbnailUrl!, fit: BoxFit.cover,
                width: double.infinity, height: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0A0A0A))),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
      ],
    );
  }

  Widget _buildModeWidget(dynamic audioHandler, Color? accentColor) {
    switch (_mode) {
      case LyricsMode.classic:
        return LyricsView(
          key: const ValueKey('classic'),
          lyrics: _lyrics!,
          onClose: () {},
          positionStream: audioHandler.player.positionStream,
          totalDuration: audioHandler.player.duration ?? Duration.zero,
          isEmbedded: false,
          accentColor: accentColor,
        );

      case LyricsMode.bubble:
        return BubbleLyricsView(
          key: const ValueKey('bubble'),
          syncedLyrics: _lyrics!.syncedLyrics,
          plainLyrics: _lyrics!.plainLyrics,
          positionStream: audioHandler.player.positionStream,
          accentColor: accentColor,
        );

      case LyricsMode.karaoke:
        if (_lyrics!.karaokeLines != null && _lyrics!.karaokeLines!.isNotEmpty) {
          return KaraokeView(
            key: const ValueKey('karaoke'),
            lines: _lyrics!.karaokeLines!,
            positionStream: audioHandler.player.positionStream,
            isEmbedded: false,
          );
        }
        return LyricsView(
          key: const ValueKey('karaoke-fallback'),
          lyrics: _lyrics!,
          onClose: () {},
          positionStream: audioHandler.player.positionStream,
          totalDuration: audioHandler.player.duration ?? Duration.zero,
          isEmbedded: false,
          accentColor: accentColor,
        );

      case LyricsMode.wave:
        return _WaveLyricsView(
          key: const ValueKey('wave'),
          lyrics: _lyrics!,
          positionStream: audioHandler.player.positionStream,
          accentColor: accentColor ?? Colors.cyanAccent,
        );

      case LyricsMode.personal:
        return _PersonalLyricsView(
          key: const ValueKey('personal'),
          lyrics: _lyrics!,
          positionStream: audioHandler.player.positionStream,
          lyricsColor: _lyricsColor,
          onPickImage: _pickPersonalBg,
          hasBg: _personalBgImage != null,
        );

      case LyricsMode.neon:
        return _NeonLyricsView(
          key: const ValueKey('neon'),
          lyrics: _lyrics!,
          positionStream: audioHandler.player.positionStream,
          accentColor: accentColor ?? const Color(0xFF00E5FF),
        );

      case LyricsMode.float:
        return _FloatLyricsView(
          key: const ValueKey('float'),
          lyrics: _lyrics!,
          positionStream: audioHandler.player.positionStream,
          accentColor: accentColor ?? Colors.purpleAccent,
        );
    }
  }

  Widget _buildModeSelector(Color? accentColor) {
    final modes = [
      (LyricsMode.classic, 'Classic', FluentIcons.text_align_left_20_regular),
      (LyricsMode.bubble, 'Bubble', Icons.chat_bubble_outline_rounded),
      (LyricsMode.karaoke, 'Karaoke', Icons.mic_none_rounded),
      (LyricsMode.wave, 'Wave', Icons.waves_rounded),
      (LyricsMode.neon, 'Neon', Icons.blur_on_rounded),
      (LyricsMode.float, 'Float', Icons.animation_rounded),
      (LyricsMode.personal, 'Personal', Icons.image_outlined),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: modes.map((m) {
            final isSelected = _mode == m.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _mode = m.$1); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (accentColor ?? Colors.white).withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? (accentColor ?? Colors.white).withValues(alpha: 0.75)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.$3, size: 14,
                          color: isSelected ? (accentColor ?? Colors.white) : Colors.white54),
                      const SizedBox(width: 6),
                      Text(m.$2,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? (accentColor ?? Colors.white) : Colors.white54,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.text_quote_24_regular, size: 64, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 24),
          const Text('Lyrics not found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("We couldn't find lyrics for this song.", style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _fetchLyrics,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.arrow_sync_24_regular, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Neon Blob helper ──────────────────────────────────────────────────────
class _NeonBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _NeonBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.45), Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Neon Mode ─────────────────────────────────────────────────────────────
class _NeonLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Stream<Duration> positionStream;
  final Color accentColor;

  const _NeonLyricsView({super.key, required this.lyrics, required this.positionStream, required this.accentColor});

  @override
  State<_NeonLyricsView> createState() => _NeonLyricsViewState();
}

class _NeonLyricsViewState extends State<_NeonLyricsView> with SingleTickerProviderStateMixin {
  List<_LrcLine> _lines = [];
  int _currentIndex = -1;
  late AnimationController _pulseCtrl;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  StreamSubscription<Duration>? _sub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _lines = _parseLrc(widget.lyrics.syncedLyrics.isNotEmpty ? widget.lyrics.syncedLyrics : widget.lyrics.plainLyrics);
    _sub = widget.positionStream.listen(_onPosition);
  }

  void _onPosition(Duration pos) {
    if (!mounted) return;
    int idx = -1;
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (pos >= _lines[i].time) { idx = i; break; }
    }
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int idx) {
    if (!_scroll.hasClients || idx < 0) return;
    final key = _keys[idx];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(key!.currentContext!, alignment: 0.35,
        duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  static List<_LrcLine> _parseLrc(String lrc) {
    final lines = <_LrcLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    for (final raw in lrc.split('\n')) {
      final m = regex.firstMatch(raw.trim());
      if (m == null) {
        if (lines.isEmpty && raw.trim().isNotEmpty) lines.add(_LrcLine(time: Duration.zero, text: raw.trim()));
        continue;
      }
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final ms = int.parse(m.group(3)!.padRight(3, '0').substring(0, 3));
      final text = m.group(4)!.trim();
      if (text.isEmpty) continue;
      lines.add(_LrcLine(time: Duration(minutes: min, seconds: sec, milliseconds: ms), text: text));
    }
    return lines;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      itemCount: _lines.length,
      itemBuilder: (ctx, i) {
        final isActive = i == _currentIndex;
        _keys[i] ??= GlobalKey();
        final dist = (i - _currentIndex).abs();
        return Container(
          key: _keys[i],
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: isActive
              ? AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final glow = 0.5 + _pulseCtrl.value * 0.5;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: widget.accentColor.withValues(alpha: 0.08),
                        boxShadow: [
                          BoxShadow(color: widget.accentColor.withValues(alpha: 0.35 * glow), blurRadius: 24 * glow, spreadRadius: 2),
                          BoxShadow(color: widget.accentColor.withValues(alpha: 0.15 * glow), blurRadius: 48 * glow),
                        ],
                        border: Border.all(color: widget.accentColor.withValues(alpha: 0.4 * glow), width: 1),
                      ),
                      child: Text(
                        _lines[i].text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: widget.accentColor,
                          shadows: [
                            Shadow(color: widget.accentColor.withValues(alpha: 0.9 * glow), blurRadius: 20),
                            Shadow(color: widget.accentColor.withValues(alpha: 0.5 * glow), blurRadius: 40),
                          ],
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                )
              : Text(
                  _lines[i].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dist == 1 ? 16 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: dist == 1 ? 0.3 : 0.15),
                    height: 1.35,
                  ),
                ),
        );
      },
    );
  }
}

// ─── Float Mode ─────────────────────────────────────────────────────────────
class _FloatLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Stream<Duration> positionStream;
  final Color accentColor;

  const _FloatLyricsView({super.key, required this.lyrics, required this.positionStream, required this.accentColor});

  @override
  State<_FloatLyricsView> createState() => _FloatLyricsViewState();
}

class _FloatLyricsViewState extends State<_FloatLyricsView> with SingleTickerProviderStateMixin {
  List<_LrcLine> _lines = [];
  int _currentIndex = -1;
  late AnimationController _floatCtrl;
  StreamSubscription<Duration>? _sub;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _lines = _NeonLyricsViewState._parseLrc(
      widget.lyrics.syncedLyrics.isNotEmpty ? widget.lyrics.syncedLyrics : widget.lyrics.plainLyrics);
    _sub = widget.positionStream.listen(_onPos);
  }

  void _onPos(Duration pos) {
    if (!mounted) return;
    int idx = -1;
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (pos >= _lines[i].time) { idx = i; break; }
    }
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      if (idx >= 0) {
        final key = _keys[idx];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(key!.currentContext!, alignment: 0.35,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
        }
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _floatCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      itemCount: _lines.length,
      itemBuilder: (ctx, i) {
        final isActive = i == _currentIndex;
        final dist = (i - _currentIndex).abs();
        _keys[i] ??= GlobalKey();
        return Container(
          key: _keys[i],
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: isActive
              ? AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, __) {
                    final floatOffset = _floatCtrl.value * 4.0;
                    return Transform.translate(
                      offset: Offset(0, -floatOffset),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            widget.accentColor,
                            Colors.white,
                            widget.accentColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          _lines[i].text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: dist == 1 ? 17 : (dist == 2 ? 14 : 12),
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: dist == 1 ? 0.35 : 0.15),
                    height: 1.35,
                  ),
                  child: Text(_lines[i].text, textAlign: TextAlign.center),
                ),
        );
      },
    );
  }
}

// ─── Wave Mode ─────────────────────────────────────────────────────────────
class _WaveLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Stream<Duration> positionStream;
  final Color accentColor;

  const _WaveLyricsView({
    super.key,
    required this.lyrics,
    required this.positionStream,
    required this.accentColor,
  });

  @override
  State<_WaveLyricsView> createState() => _WaveLyricsViewState();
}

class _WaveLyricsViewState extends State<_WaveLyricsView>
    with SingleTickerProviderStateMixin {
  List<_LrcLine> _lines = [];
  int _currentIndex = -1;
  late AnimationController _waveCtrl;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  StreamSubscription<Duration>? _sub;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _lines = _parseLrc(
      widget.lyrics.syncedLyrics.isNotEmpty ? widget.lyrics.syncedLyrics : widget.lyrics.plainLyrics);
    _sub = widget.positionStream.listen(_onPosition);
  }

  void _onPosition(Duration pos) {
    if (!mounted) return;
    int idx = -1;
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (pos >= _lines[i].time) { idx = i; break; }
    }
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int idx) {
    if (!_scroll.hasClients || idx < 0) return;
    final key = _keys[idx];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(key!.currentContext!,
        alignment: 0.35, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  static List<_LrcLine> _parseLrc(String lrc) {
    final lines = <_LrcLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    for (final raw in lrc.split('\n')) {
      final m = regex.firstMatch(raw.trim());
      if (m == null) {
        if (lines.isEmpty && raw.trim().isNotEmpty) lines.add(_LrcLine(time: Duration.zero, text: raw.trim()));
        continue;
      }
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final ms = int.parse(m.group(3)!.padRight(3, '0').substring(0, 3));
      final text = m.group(4)!.trim();
      if (text.isEmpty) continue;
      lines.add(_LrcLine(time: Duration(minutes: min, seconds: sec, milliseconds: ms), text: text));
    }
    return lines;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _waveCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      itemCount: _lines.length,
      itemBuilder: (context, i) {
        final isActive = i == _currentIndex;
        _keys[i] ??= GlobalKey();
        return Container(
          key: _keys[i],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: isActive
              ? AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) {
                    final t = _waveCtrl.value;
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          widget.accentColor,
                          Colors.white,
                          widget.accentColor.withValues(alpha: 0.8),
                          Colors.white,
                          widget.accentColor,
                        ],
                        stops: const [0, 0.25, 0.5, 0.75, 1.0],
                        begin: Alignment(-2.0 + t * 4, 0),
                        end: Alignment(2.0 + t * 4, 0),
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        _lines[i].text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1.35, color: Colors.white),
                      ),
                    );
                  },
                )
              : Text(
                  _lines[i].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (i - _currentIndex).abs() == 1 ? 18 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: (i - _currentIndex).abs() == 1 ? 0.4 : 0.2),
                    height: 1.35,
                  ),
                ),
        );
      },
    );
  }
}

// ─── Personal Mode ─────────────────────────────────────────────────────────
class _PersonalLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Stream<Duration> positionStream;
  final Color lyricsColor;
  final VoidCallback onPickImage;
  final bool hasBg;

  const _PersonalLyricsView({
    super.key,
    required this.lyrics,
    required this.positionStream,
    required this.lyricsColor,
    required this.onPickImage,
    required this.hasBg,
  });

  @override
  State<_PersonalLyricsView> createState() => _PersonalLyricsViewState();
}

class _PersonalLyricsViewState extends State<_PersonalLyricsView> {
  List<_LrcLine> _lines = [];
  int _currentIndex = -1;
  StreamSubscription<Duration>? _sub;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _lines = _NeonLyricsViewState._parseLrc(
      widget.lyrics.syncedLyrics.isNotEmpty ? widget.lyrics.syncedLyrics : widget.lyrics.plainLyrics);
    _sub = widget.positionStream.listen(_onPos);
  }

  void _onPos(Duration pos) {
    if (!mounted) return;
    int idx = -1;
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (pos >= _lines[i].time) { idx = i; break; }
    }
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int idx) {
    if (!_scroll.hasClients || idx < 0) return;
    final key = _keys[idx];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(key!.currentContext!,
        alignment: 0.35, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasBg) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.image_outlined, color: Colors.white70, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('Your Background', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Pick a photo from your gallery\nto use as lyrics background',
                style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: widget.onPickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.08)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Pick Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      itemCount: _lines.length,
      itemBuilder: (ctx, i) {
        final isActive = i == _currentIndex;
        _keys[i] ??= GlobalKey();
        final dist = (i - _currentIndex).abs();
        return Container(
          key: _keys[i],
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _lines[i].text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isActive ? 22 : (dist == 1 ? 16 : 13),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
              color: isActive
                  ? widget.lyricsColor
                  : widget.lyricsColor.withValues(alpha: dist == 1 ? 0.45 : 0.2),
              height: 1.4,
              shadows: isActive
                  ? [Shadow(color: widget.lyricsColor.withValues(alpha: 0.6), blurRadius: 16)]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared ─────────────────────────────────────────────────────────────────
class _LrcLine {
  final Duration time;
  final String text;
  const _LrcLine({required this.time, required this.text});
}
