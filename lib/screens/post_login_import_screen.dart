import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/screens/home_shell.dart';
import 'package:yvl/services/spotify_liked_service.dart';
import 'package:yvl/services/storage_service.dart';

class PostLoginImportScreen extends ConsumerStatefulWidget {
  final String providerName;
  const PostLoginImportScreen({super.key, required this.providerName});

  @override
  ConsumerState<PostLoginImportScreen> createState() => _State();
}

class _State extends ConsumerState<PostLoginImportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;
  ImportProgress _progress = const ImportProgress();
  StreamSubscription<ImportProgress>? _sub;
  bool _importing = false;
  bool _done = false;

  bool get _isSpotify => widget.providerName == 'spotify';
  Color get _accent => _isSpotify ? const Color(0xFF1DB954) : const Color(0xFF4285F4);

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startImport() async {
    HapticFeedback.mediumImpact();
    setState(() => _importing = true);
    final svc = SpotifyLikedService(ref.read(storageServiceProvider));
    _sub = svc.importLikedSongs().listen(
      (p) {
        if (mounted) setState(() => _progress = p);
        if (p.isComplete && mounted) {
          setState(() { _done = true; _importing = false; });
          HapticFeedback.heavyImpact();
        }
      },
      onError: (e) {
        if (mounted) setState(() {
          _importing = false;
          _progress = _progress.copyWith(hasError: true, isComplete: true, errorMessage: '$e');
        });
      },
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeIn), child: const HomeShell()),
        transitionDuration: const Duration(milliseconds: 500),
        opaque: true,
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient bg
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(sin(_bg.value * pi) * 0.4, cos(_bg.value * pi) * 0.3 - 0.3),
                  radius: 1.6,
                  colors: [_accent.withValues(alpha: 0.18), const Color(0xFF0D0D1A), Colors.black],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.15),
                      border: Border.all(color: _accent.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Icon(
                      _isSpotify ? Icons.music_note_rounded : Icons.thumb_up_rounded,
                      color: _accent, size: 40,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _done ? 'Import Complete! 🎉'
                        : _importing ? 'Importing your music...'
                        : _isSpotify ? 'Import your Spotify library'
                        : 'You\'re all set!',
                    style: const TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w900, letterSpacing: -0.8),
                    textAlign: TextAlign.center,
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 10),

                  Text(
                    _done
                        ? 'Added ${_progress.imported} songs to "Liked Songs ❤️"'
                        : _importing ? _progress.status
                        : _isSpotify ? 'Import your liked songs from Spotify into YVL. They\'ll be available offline too.'
                        : 'Your music is ready. Start listening now.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center,
                  ).animate(delay: 180.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // Progress card
                  if (_importing || _done || _progress.hasError) ...[
                    _ProgressCard(p: _progress, accent: _accent)
                        .animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 28),
                  ],

                  // Feature chips (before import)
                  if (!_importing && !_done && !_progress.hasError && _isSpotify) ...[
                    Wrap(
                      spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                      children: [
                        ('❤️', 'Liked songs'), ('🎵', 'Up to 200 tracks'),
                        ('📱', 'Plays instantly'), ('🔄', 'Matched on YouTube'),
                      ].map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accent.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(f.$1, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(f.$2, style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      )).toList(),
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 32),
                  ],

                  const Spacer(),

                  // CTA buttons
                  if (_done || _progress.isComplete)
                    _PrimaryBtn(label: 'Start listening 🎵', color: _accent, onTap: _goHome)
                  else if (!_importing) ...[
                    if (_isSpotify)
                      _PrimaryBtn(label: 'Import Liked Songs', color: _accent, onTap: _startImport),
                    const SizedBox(height: 12),
                    _TextBtn(label: 'Skip for now', onTap: _goHome),
                  ] else
                    _TextBtn(label: 'Skip — go to app', onTap: _goHome),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ImportProgress p;
  final Color accent;
  const _ProgressCard({required this.p, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                p.isComplete && !p.hasError ? '✓ Done'
                    : p.hasError ? '⚠ Error'
                    : '${p.current} / ${p.total}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text('${(p.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p.progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accent),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              p.errorMessage ?? p.status,
              style: TextStyle(
                color: p.hasError ? Colors.redAccent : Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            if (p.imported > 0) ...[
              const SizedBox(height: 8),
              Text('${p.imported} songs added',
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
    ),
  );
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.2),
          )),
    ),
  );
}
