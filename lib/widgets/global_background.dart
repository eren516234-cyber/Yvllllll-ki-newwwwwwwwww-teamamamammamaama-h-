import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/settings_provider.dart';

class GlobalBackground extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalBackground({super.key, required this.child});

  @override
  ConsumerState<GlobalBackground> createState() => _GlobalBackgroundState();
}

class _GlobalBackgroundState extends ConsumerState<GlobalBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _doodleController;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _doodleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _doodleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeType = ref.watch(settingsProvider).themeType;
    final isSky = themeType == ThemeType.sky;
    final isDoodle = themeType == ThemeType.doodle;

    if (isDoodle) {
      return Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _doodleController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _DoodleBackgroundPainter(t: _doodleController.value),
                );
              },
            ),
          ),
          widget.child,
        ],
      );
    }

    if (!isSky) {
      return Stack(
        children: [
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          widget.child,
        ],
      );
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller1, _controller2]),
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SkyBackgroundPainter(
                  t1: _controller1.value,
                  t2: _controller2.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ─── Doodle Background ──────────────────────────────────────────────────────
class _DoodleBackgroundPainter extends CustomPainter {
  final double t;
  const _DoodleBackgroundPainter({required this.t});

  static const _coral = Color(0xFFFF6B6B);
  static const _mint = Color(0xFF4ECDC4);
  static const _lavender = Color(0xFFC3B1E1);
  static const _yellow = Color(0xFFFFE66D);

  @override
  void paint(Canvas canvas, Size size) {
    // Warm cream base
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFCF0), Color(0xFFFFF8E0), Color(0xFFFFFCF0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final rng = math.Random(77);

    // Soft colored blobs
    _drawBlob(canvas, size, _coral.withValues(alpha: 0.06),
        Offset(size.width * (0.15 + 0.08 * math.sin(t * math.pi * 2)), size.height * 0.12),
        size.width * 0.38);
    _drawBlob(canvas, size, _mint.withValues(alpha: 0.07),
        Offset(size.width * (0.82 + 0.06 * math.cos(t * math.pi * 2)), size.height * 0.38),
        size.width * 0.32);
    _drawBlob(canvas, size, _lavender.withValues(alpha: 0.08),
        Offset(size.width * (0.45 + 0.07 * math.sin((t + 0.3) * math.pi * 2)), size.height * (0.72 + 0.05 * math.cos(t * math.pi * 2))),
        size.width * 0.4);
    _drawBlob(canvas, size, _yellow.withValues(alpha: 0.06),
        Offset(size.width * (0.88), size.height * 0.8),
        size.width * 0.28);

    // Animated doodle circles (hand-drawn style)
    for (int i = 0; i < 7; i++) {
      final ox = rng.nextDouble() * size.width;
      final oy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 28 + 12;
      final phase = rng.nextDouble();
      final floatY = math.sin((t + phase) * math.pi * 2) * 8;
      final colors = [_coral, _mint, _lavender, _yellow];
      final c = colors[i % colors.length];
      final paint = Paint()
        ..color = c.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(ox, oy + floatY), r, paint);
    }

    // Wavy lines
    for (int w = 0; w < 3; w++) {
      final wy = size.height * (0.2 + w * 0.3);
      final wPhase = w * 0.4 + t;
      final wavePaint = Paint()
        ..color = _mint.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(0, wy);
      for (double x = 0; x <= size.width; x += 4) {
        final y = wy + math.sin((x / size.width * 4 * math.pi) + wPhase * math.pi * 2) * 10;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Music notes
    final notePositions = [
      (0.1, 0.18, 0.0), (0.75, 0.08, 0.2), (0.9, 0.55, 0.5),
      (0.05, 0.65, 0.7), (0.55, 0.92, 0.1), (0.3, 0.04, 0.9),
    ];
    for (final (nx, ny, ph) in notePositions) {
      final floatY = math.sin((t + ph) * math.pi * 2) * 6;
      final noteX = size.width * nx;
      final noteY = size.height * ny + floatY;
      final c = [_coral, _mint, _lavender][notePositions.indexOf((nx, ny, ph)) % 3];
      _drawMusicNote(canvas, Offset(noteX, noteY), c.withValues(alpha: 0.22), 11.0);
    }

    // Small star dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final rng2 = math.Random(33);
    for (int i = 0; i < 20; i++) {
      final sx = rng2.nextDouble() * size.width;
      final sy = rng2.nextDouble() * size.height;
      final dotColors = [_coral, _mint, _lavender, _yellow];
      dotPaint.color = dotColors[i % dotColors.length].withValues(alpha: 0.18);
      canvas.drawCircle(Offset(sx, sy), rng2.nextDouble() * 2.5 + 1, dotPaint);
    }
  }

  void _drawBlob(Canvas canvas, Size size, Color color, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawMusicNote(Canvas canvas, Offset pos, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Oval note head
    canvas.drawOval(Rect.fromCenter(center: pos, width: size * 0.8, height: size * 0.6), paint);
    // Stem
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = size * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pos.dx + size * 0.35, pos.dy),
      Offset(pos.dx + size * 0.35, pos.dy - size * 1.1),
      stemPaint,
    );
    // Flag
    final flagPath = Path()
      ..moveTo(pos.dx + size * 0.35, pos.dy - size * 1.1)
      ..quadraticBezierTo(
        pos.dx + size * 0.85, pos.dy - size * 0.7,
        pos.dx + size * 0.6, pos.dy - size * 0.4,
      );
    canvas.drawPath(flagPath, stemPaint);
  }

  @override
  bool shouldRepaint(_DoodleBackgroundPainter old) => old.t != t;
}

// ─── Sky Background ──────────────────────────────────────────────────────────
class _SkyBackgroundPainter extends CustomPainter {
  final double t1;
  final double t2;

  const _SkyBackgroundPainter({required this.t1, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF010A18), Color(0xFF050A14), Color(0xFF020810)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final cx1 = size.width * (0.2 + 0.3 * math.sin(t1 * math.pi * 2));
    final cy1 = size.height * (0.1 + 0.25 * math.cos(t1 * math.pi * 2));
    final orb1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00BCD4).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: size.width * 0.55));
    canvas.drawCircle(Offset(cx1, cy1), size.width * 0.55, orb1);

    final cx2 = size.width * (0.7 + 0.2 * math.cos(t2 * math.pi * 2));
    final cy2 = size.height * (0.4 + 0.3 * math.sin(t2 * math.pi * 2));
    final orb2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0D47A1).withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: size.width * 0.6));
    canvas.drawCircle(Offset(cx2, cy2), size.width * 0.6, orb2);

    final cx3 = size.width * (0.5 + 0.25 * math.sin((t1 + 0.5) * math.pi * 2));
    final cy3 = size.height * (0.7 + 0.2 * math.cos((t2 + 0.3) * math.pi * 2));
    final orb3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF006064).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx3, cy3), radius: size.width * 0.45));
    canvas.drawCircle(Offset(cx3, cy3), size.width * 0.45, orb3);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      final sr = rng.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }
  }

  @override
  bool shouldRepaint(_SkyBackgroundPainter old) => old.t1 != t1 || old.t2 != t2;
}
