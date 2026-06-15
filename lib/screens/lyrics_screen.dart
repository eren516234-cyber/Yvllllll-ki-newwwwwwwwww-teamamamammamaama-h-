import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:yvl/services/lyrics_service.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/providers/theme_provider.dart';

// ─── 6 lyrics modes ───────────────────────────────────────────────────────────
enum LyricsMode { classic, karaoke, neon, bubble, wave, cinema }

// ─── Parsed line ─────────────────────────────────────────────────────────────
class _Line {
  final Duration time;
  final String text;
  const _Line({required this.time, required this.text});
}

/// Parses LRC-formatted synced lyrics. Returns empty list if no timestamps found.
/// For plain lyrics (no timestamps), use [parsePlainLyrics] instead.
List<_Line> parseLrc(String raw) {
  final lines = <_Line>[];
  final re = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
  for (final row in raw.split('\n')) {
    final m = re.firstMatch(row.trim());
    if (m == null) continue; // skip — don't add plain lines here
    final txt = m.group(4)!.trim();
    if (txt.isEmpty) continue;
    final ms3 = m.group(3)!.padRight(3, '0').substring(0, 3);
    lines.add(_Line(
      time: Duration(
        minutes: int.parse(m.group(1)!),
        seconds: int.parse(m.group(2)!),
        milliseconds: int.parse(ms3),
      ),
      text: txt,
    ));
  }
  return lines;
}

/// Splits plain (non-timestamped) lyrics into displayable lines.
List<String> parsePlainLyrics(String raw) {
  return raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoading = true);
    try {
      final l = await ref
          .read(lyricsServiceProvider)
          .fetchLyrics(widget.title, widget.artist, widget.durationSeconds);
      if (mounted) setState(() { _lyrics = l; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final palette = ref.watch(currentPaletteProvider).asData?.value;
    final accent = palette?.darkVibrantColor?.color ??
        palette?.lightVibrantColor?.color ??
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred artwork background
          Positioned.fill(child: _ArtworkBg(url: widget.thumbnailUrl, mode: _mode, accent: accent)),

          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: widget.title,
                  artist: widget.artist,
                  onRefresh: _fetchLyrics,
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                      : _lyrics == null
                          ? _NotFound(onRetry: _fetchLyrics)
                          : _buildModeView(handler, accent),
                ),

                _ModeBar(
                    current: _mode,
                    accent: accent,
                    onChanged: (m) {
                      HapticFeedback.lightImpact();
                      setState(() => _mode = m);
                    },
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeView(dynamic handler, Color accent) {
    // Instrumental — no lyrics at all
    if (_lyrics!.instrumental) {
      return const _InstrumentalView();
    }

    // Prefer synced lyrics; fall back to plain if empty
    final hasSynced = _lyrics!.syncedLyrics.isNotEmpty;
    final pos = handler.player.positionStream as Stream<Duration>;

    if (!hasSynced) {
      // Plain lyrics (no timestamps) — parse and show as scrollable list
      final plainLines = parsePlainLyrics(
        _lyrics!.plainLyrics.isNotEmpty ? _lyrics!.plainLyrics : '',
      );
      if (plainLines.isEmpty) return _NotFound(onRetry: _fetchLyrics);
      return _PlainLyricsView(lines: plainLines, accent: accent);
    }

    // Synced lyrics
    final lines = parseLrc(_lyrics!.syncedLyrics);
    if (lines.isEmpty) {
      // Fallback: render syncedLyrics as plain if parseLrc found no timestamps
      final fallback = parsePlainLyrics(_lyrics!.syncedLyrics);
      if (fallback.isEmpty) return _NotFound(onRetry: _fetchLyrics);
      return _PlainLyricsView(lines: fallback, accent: accent);
    }

    switch (_mode) {
      case LyricsMode.classic:
        return _ClassicMode(key: const ValueKey('classic'), lines: lines, positionStream: pos, accent: accent);
      case LyricsMode.karaoke:
        return _KaraokeMode(key: const ValueKey('karaoke'), lines: lines, positionStream: pos, accent: accent);
      case LyricsMode.neon:
        return _NeonMode(key: const ValueKey('neon'), lines: lines, positionStream: pos, accent: accent);
      case LyricsMode.bubble:
        return _BubbleMode(key: const ValueKey('bubble'), lines: lines, positionStream: pos, accent: accent);
      case LyricsMode.wave:
        return _WaveMode(key: const ValueKey('wave'), lines: lines, positionStream: pos, accent: accent);
      case LyricsMode.cinema:
        return _CinemaMode(key: const ValueKey('cinema'), lines: lines, positionStream: pos, accent: accent);
    }
  }
}

// ─── Artwork Background ───────────────────────────────────────────────────────
class _ArtworkBg extends StatelessWidget {
  final String? url;
  final LyricsMode mode;
  final Color accent;
  const _ArtworkBg({required this.url, required this.mode, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (mode == LyricsMode.neon) {
      return _NeonBg(accent: accent);
    }
    if (mode == LyricsMode.cinema) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [accent.withValues(alpha: 0.25), Colors.black],
          ),
        ),
      );
    }
    return Stack(
      children: [
        if (url != null)
          RepaintBoundary(
            child: Image.network(url!, fit: BoxFit.cover,
                width: double.infinity, height: double.infinity,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
      ],
    );
  }
}

class _NeonBg extends StatefulWidget {
  final Color accent;
  const _NeonBg({required this.accent});
  @override
  State<_NeonBg> createState() => _NeonBgState();
}

class _NeonBgState extends State<_NeonBg> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _NeonBgPainter(_c.value, widget.accent)),
      ),
    );
  }
}

class _NeonBgPainter extends CustomPainter {
  final double t;
  final Color accent;
  const _NeonBgPainter(this.t, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF050008));
    final blobs = [
      (Offset(size.width * (0.2 + 0.15 * math.sin(t * math.pi * 2)), size.height * 0.2), accent, 0.22),
      (Offset(size.width * (0.8 - 0.1 * math.cos(t * math.pi * 2)), size.height * 0.7), Colors.purpleAccent, 0.18),
      (Offset(size.width * 0.5, size.height * (0.4 + 0.15 * math.sin((t + 0.5) * math.pi * 2))), Colors.deepPurple, 0.14),
    ];
    for (final (center, color, alpha) in blobs) {
      final r = size.width * 0.6;
      canvas.drawCircle(center, r, Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), Colors.transparent])
            .createShader(Rect.fromCircle(center: center, radius: r)));
    }
  }
  @override
  bool shouldRepaint(_NeonBgPainter old) => old.t != t;
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final String artist;
  final VoidCallback onRefresh;
  const _TopBar({required this.title, required this.artist, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FluentIcons.chevron_down_24_regular, color: Colors.white70),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Lyrics', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                Text('$title • $artist',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.arrow_sync_24_regular, color: Colors.white70),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─── Mode Bar ────────────────────────────────────────────────────────────────
class _ModeBar extends StatelessWidget {
  final LyricsMode current;
  final Color accent;
  final void Function(LyricsMode) onChanged;
  const _ModeBar({required this.current, required this.accent, required this.onChanged});

  static const _modes = [
    (LyricsMode.classic,  '✦ Classic',  Icons.format_align_center_rounded),
    (LyricsMode.karaoke,  '🎤 Karaoke',  Icons.mic_rounded),
    (LyricsMode.neon,     '⚡ Neon',     Icons.bolt_rounded),
    (LyricsMode.bubble,   '💬 Bubble',   Icons.chat_bubble_rounded),
    (LyricsMode.wave,     '〜 Wave',     Icons.waves_rounded),
    (LyricsMode.cinema,   '🎬 Cinema',   Icons.movie_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _modes.map((m) {
          final sel = current == m.$1;
          return GestureDetector(
            onTap: () => onChanged(m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: sel ? accent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.12),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Text(m.$2,
                style: TextStyle(
                  color: sel ? accent : Colors.white54,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Not Found ───────────────────────────────────────────────────────────────
class _NotFound extends StatelessWidget {
  final VoidCallback onRetry;
  const _NotFound({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(FluentIcons.text_quote_24_regular, color: Colors.white24, size: 56),
        const SizedBox(height: 20),
        const Text('Lyrics not found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Could not find synced lyrics for this song.',
            style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(FluentIcons.arrow_sync_24_regular, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 1 — CLASSIC
// ─── Plain Lyrics View (no timestamps) ───────────────────────────────────────
/// Shown when only plain (non-LRC) lyrics are available.
class _PlainLyricsView extends StatelessWidget {
  final List<String> lines;
  final Color accent;
  const _PlainLyricsView({required this.lines, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      itemCount: lines.length,
      itemBuilder: (ctx, i) {
        final line = lines[i];
        // Section headers like [Chorus], [Verse 1]
        final isSection = line.startsWith('[') && line.endsWith(']');
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isSection ? 14 : 7),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSection ? 13 : 17,
              fontWeight: isSection ? FontWeight.w600 : FontWeight.w500,
              color: isSection
                  ? accent.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.82),
              letterSpacing: isSection ? 1.5 : 0,
              height: 1.65,
            ),
          ),
        );
      },
    );
  }
}

// ─── Instrumental View ────────────────────────────────────────────────────────
class _InstrumentalView extends StatelessWidget {
  const _InstrumentalView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.piano_rounded, color: Colors.white24, size: 72),
        const SizedBox(height: 20),
        const Text('🎼 Instrumental', style: TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('This track has no lyrics',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14)),
      ]),
    );
  }
}

// Clean vertical list. Active line: large white. Inactive: dimmer + smaller.
// Smooth auto-scroll. Zero lag: no per-frame setState on full tree.
// ═══════════════════════════════════════════════════════════════════════════════
class _ClassicMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _ClassicMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_ClassicMode> createState() => _ClassicModeState();
}

class _ClassicModeState extends State<_ClassicMode> {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _cur = -1;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _sub = widget.positionStream.listen(_onPos);
  }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      if (idx != _cur) {
        setState(() => _cur = idx);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
      }
    });
  }

  void _scrollTo(int idx) {
    final key = _keys[idx];
    if (key?.currentContext != null && _scroll.hasClients) {
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.38, duration: const Duration(milliseconds: 480), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      itemCount: widget.lines.length,
      itemBuilder: (ctx, i) {
        _keys[i] ??= GlobalKey();
        final isActive = i == _cur;
        final dist = (i - _cur).abs();
        final opacity = isActive ? 1.0 : (dist == 1 ? 0.45 : (dist == 2 ? 0.25 : 0.12));
        return Container(
          key: _keys[i],
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 320),
            style: TextStyle(
              fontSize: isActive ? 26 : (dist <= 1 ? 18 : 15),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: opacity),
              height: 1.35,
              letterSpacing: isActive ? -0.4 : 0,
            ),
            child: Text(widget.lines[i].text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 2 — KARAOKE
// Gradient sweep fills text left-to-right based on position within line.
// ═══════════════════════════════════════════════════════════════════════════════
class _KaraokeMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _KaraokeMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_KaraokeMode> createState() => _KaraokeModeState();
}

class _KaraokeModeState extends State<_KaraokeMode> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _cur = -1;
  double _fill = 0;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;
  late final AnimationController _sweepCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void initState() {
    super.initState();
    _sub = widget.positionStream.listen(_onPos);
  }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      double fill = 0;
      if (idx >= 0 && idx < widget.lines.length - 1) {
        final lineStart = widget.lines[idx].time;
        final lineEnd = widget.lines[idx + 1].time;
        final lineLen = (lineEnd - lineStart).inMilliseconds;
        if (lineLen > 0) {
          fill = ((pos - lineStart).inMilliseconds / lineLen).clamp(0.0, 1.0);
        }
      } else if (idx == widget.lines.length - 1) {
        fill = 1.0;
      }
      if (idx != _cur || (fill - _fill).abs() > 0.01) {
        if (idx != _cur) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
        }
        setState(() { _cur = idx; _fill = fill; });
      }
    });
  }

  void _scrollTo(int idx) {
    final key = _keys[idx];
    if (key?.currentContext != null && _scroll.hasClients) {
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.38, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); _sweepCtrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      itemCount: widget.lines.length,
      itemBuilder: (ctx, i) {
        _keys[i] ??= GlobalKey();
        final isActive = i == _cur;
        final dist = (i - _cur).abs();
        return Container(
          key: _keys[i],
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: isActive
              ? RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _sweepCtrl,
                    builder: (_, __) => _KaraokeLineText(
                      text: widget.lines[i].text,
                      fill: _fill,
                      accent: widget.accent,
                      sweep: _sweepCtrl.value,
                    ),
                  ),
                )
              : Text(
                  widget.lines[i].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dist == 1 ? 17 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: dist == 1 ? 0.35 : 0.15),
                    height: 1.4,
                  ),
                ),
        );
      },
    );
  }
}

class _KaraokeLineText extends StatelessWidget {
  final String text;
  final double fill;
  final Color accent;
  final double sweep;
  const _KaraokeLineText({required this.text, required this.fill, required this.accent, required this.sweep});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(text, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white24, height: 1.3)),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [accent, Colors.white, accent],
                stops: [(sweep - 0.5).clamp(0, 1.0), sweep.clamp(0, 1.0), (sweep + 0.5).clamp(0, 1.0)],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(text, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3)),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 3 — NEON
// Active line glows with animated neon shimmer. Others are ghost text.
// ═══════════════════════════════════════════════════════════════════════════════
class _NeonMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _NeonMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_NeonMode> createState() => _NeonModeState();
}

class _NeonModeState extends State<_NeonMode> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _cur = -1;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void initState() { super.initState(); _sub = widget.positionStream.listen(_onPos); }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      if (idx != _cur) {
        setState(() => _cur = idx);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
      }
    });
  }

  void _scrollTo(int idx) {
    final key = _keys[idx];
    if (key?.currentContext != null && _scroll.hasClients) {
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.38, duration: const Duration(milliseconds: 480), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); _pulse.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      itemCount: widget.lines.length,
      itemBuilder: (ctx, i) {
        _keys[i] ??= GlobalKey();
        final isActive = i == _cur;
        final dist = (i - _cur).abs();
        return Container(
          key: _keys[i],
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: isActive
              ? RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      final g = 0.55 + _pulse.value * 0.45;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: widget.accent.withValues(alpha: 0.07),
                          border: Border.all(color: widget.accent.withValues(alpha: 0.35 * g), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: widget.accent.withValues(alpha: 0.45 * g), blurRadius: 28 * g, spreadRadius: 2),
                            BoxShadow(color: widget.accent.withValues(alpha: 0.2 * g), blurRadius: 60 * g),
                          ],
                        ),
                        child: Text(
                          widget.lines[i].text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: widget.accent,
                            height: 1.35,
                            shadows: [
                              Shadow(color: widget.accent.withValues(alpha: 0.9 * g), blurRadius: 18),
                              Shadow(color: widget.accent.withValues(alpha: 0.5 * g), blurRadius: 36),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  widget.lines[i].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dist == 1 ? 16 : 13,
                    color: Colors.white.withValues(alpha: dist == 1 ? 0.22 : 0.09),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 4 — BUBBLE
// Each active line slides in as a glass bubble. Previous lines fade to small.
// ═══════════════════════════════════════════════════════════════════════════════
class _BubbleMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _BubbleMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_BubbleMode> createState() => _BubbleModeState();
}

class _BubbleModeState extends State<_BubbleMode> {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _cur = -1;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _sub = widget.positionStream.listen(_onPos); }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      if (idx != _cur) {
        setState(() => _cur = idx);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
      }
    });
  }

  void _scrollTo(int idx) {
    final key = _keys[idx];
    if (key?.currentContext != null && _scroll.hasClients) {
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.4, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bool isRightAlign = true;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      itemCount: widget.lines.length,
      itemBuilder: (ctx, i) {
        _keys[i] ??= GlobalKey();
        final isActive = i == _cur;
        final isPrev = i < _cur;
        final dist = (_cur - i).abs();

        final align = (i % 2 == 0) ? Alignment.centerLeft : Alignment.centerRight;

        return Container(
          key: _keys[i],
          alignment: align,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 18 : 13,
              vertical: isActive ? 13 : 8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? widget.accent.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: isPrev ? 0.06 : 0.04),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(i % 2 == 0 ? 4 : 22),
                bottomRight: Radius.circular(i % 2 == 0 ? 22 : 4),
              ),
              border: Border.all(
                color: isActive ? widget.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
                width: isActive ? 1.5 : 0.8,
              ),
              boxShadow: isActive ? [
                BoxShadow(color: widget.accent.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 0),
              ] : [],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isActive ? 18 : (dist == 1 ? 14 : 12),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: dist == 1 ? 0.4 : 0.18),
                height: 1.4,
              ),
              child: Text(widget.lines[i].text),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 5 — WAVE
// Active line has an animated rainbow-wave colour shader sweeping across.
// ═══════════════════════════════════════════════════════════════════════════════
class _WaveMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _WaveMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_WaveMode> createState() => _WaveModeState();
}

class _WaveModeState extends State<_WaveMode> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _cur = -1;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void initState() { super.initState(); _sub = widget.positionStream.listen(_onPos); }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      if (idx != _cur) {
        setState(() => _cur = idx);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
      }
    });
  }

  void _scrollTo(int idx) {
    final key = _keys[idx];
    if (key?.currentContext != null && _scroll.hasClients) {
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.38, duration: const Duration(milliseconds: 480), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); _wave.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      itemCount: widget.lines.length,
      itemBuilder: (ctx, i) {
        _keys[i] ??= GlobalKey();
        final isActive = i == _cur;
        final dist = (i - _cur).abs();
        return Container(
          key: _keys[i],
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: isActive
              ? RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) => ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [
                          widget.accent,
                          Colors.white,
                          Colors.pinkAccent,
                          Colors.cyanAccent,
                          widget.accent,
                        ],
                        stops: const [0, 0.25, 0.5, 0.75, 1.0],
                        begin: Alignment(-2 + _wave.value * 4, 0),
                        end: Alignment(2 + _wave.value * 4, 0),
                      ).createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        widget.lines[i].text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.35),
                      ),
                    ),
                  ),
                )
              : Text(
                  widget.lines[i].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dist == 1 ? 17 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: dist == 1 ? 0.3 : 0.12),
                    height: 1.35,
                  ),
                ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODE 6 — CINEMA
// Only the active line. Full-screen centered. Cinematic cross-fade + scale.
// ═══════════════════════════════════════════════════════════════════════════════
class _CinemaMode extends StatefulWidget {
  final List<_Line> lines;
  final Stream<Duration> positionStream;
  final Color accent;
  const _CinemaMode({super.key, required this.lines, required this.positionStream, required this.accent});
  @override
  State<_CinemaMode> createState() => _CinemaModeState();
}

class _CinemaModeState extends State<_CinemaMode> {
  int _cur = -1;
  StreamSubscription<Duration>? _sub;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _sub = widget.positionStream.listen(_onPos); }

  void _onPos(Duration pos) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      int idx = -1;
      for (int i = widget.lines.length - 1; i >= 0; i--) {
        if (pos >= widget.lines[i].time) { idx = i; break; }
      }
      if (idx != _cur) setState(() => _cur = idx);
    });
  }

  @override
  void dispose() { _sub?.cancel(); _debounce?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final text = (_cur >= 0 && _cur < widget.lines.length) ? widget.lines[_cur].text : '';
    final next = (_cur + 1 < widget.lines.length) ? widget.lines[_cur + 1].text : '';
    final prev = (_cur - 1 >= 0) ? widget.lines[_cur - 1].text : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous (ghost)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: prev.isEmpty ? const SizedBox(height: 28) : Text(
              key: ValueKey('prev-$_cur'),
              prev,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.2), fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),

          // Active (main)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) {
              final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved), child: child),
              );
            },
            child: text.isEmpty
                ? const SizedBox(key: ValueKey('empty'), height: 80)
                : Container(
                    key: ValueKey(_cur),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [widget.accent.withValues(alpha: 0.18), widget.accent.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: widget.accent.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [Colors.white, widget.accent.withValues(alpha: 0.9), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.35, letterSpacing: -0.5),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Next (ghost)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: next.isEmpty ? const SizedBox(height: 28) : Text(
              key: ValueKey('next-$_cur'),
              next,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.2), fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
