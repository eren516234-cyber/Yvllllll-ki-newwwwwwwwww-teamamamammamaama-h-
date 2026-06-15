import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/settings_provider.dart';

/// Floating cozy companion — only visible in Cozy Night Studio theme.
/// A small animated character that floats in the bottom-right corner.
class CozyCompanion extends ConsumerStatefulWidget {
  const CozyCompanion({super.key});

  @override
  ConsumerState<CozyCompanion> createState() => _CozyCompanionState();
}

class _CozyCompanionState extends ConsumerState<CozyCompanion>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _noteController;

  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scheduleBlink();

    _noteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  void _scheduleBlink() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2400 + (math.Random().nextInt(2000))));
      if (!mounted) break;
      await _blinkController.forward();
      await _blinkController.reverse();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeType = ref.watch(settingsProvider).themeType;
    if (themeType != ThemeType.cozyNight) return const SizedBox.shrink();
    if (!_visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _blinkController, _noteController]),
      builder: (context, _) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 6;
        return GestureDetector(
          onTap: () => setState(() => _visible = false),
          child: Transform.translate(
            offset: Offset(0, floatOffset),
            child: SizedBox(
              width: 64,
              height: 80,
              child: CustomPaint(
                painter: _CompanionPainter(
                  blinkProgress: _blinkController.value,
                  noteProgress: _noteController.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompanionPainter extends CustomPainter {
  final double blinkProgress;
  final double noteProgress;

  const _CompanionPainter({
    required this.blinkProgress,
    required this.noteProgress,
  });

  static const _amber = Color(0xFFFFB347);
  static const _warmWhite = Color(0xFFFFF3E0);
  static const _deepBrown = Color(0xFF3D1A08);
  static const _softPink = Color(0xFFFFB6C1);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // === BODY (little round cat/creature) ===
    // Body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF4A2808), const Color(0xFF2A1404)],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: Offset(cx, size.height * 0.68), radius: 22));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height * 0.68), width: 38, height: 34),
      bodyPaint,
    );

    // Belly patch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height * 0.7), width: 20, height: 18),
      Paint()..color = const Color(0xFF6B3418).withValues(alpha: 0.6),
    );

    // === HEAD ===
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF5A3010), const Color(0xFF2A1404)],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: Offset(cx, size.height * 0.35), radius: 20));
    canvas.drawCircle(Offset(cx, size.height * 0.35), 19, headPaint);

    // === EARS ===
    final earPaint = Paint()..color = const Color(0xFF3A1A08);
    // Left ear
    final leftEar = Path()
      ..moveTo(cx - 14, size.height * 0.22)
      ..lineTo(cx - 20, size.height * 0.06)
      ..lineTo(cx - 6, size.height * 0.18)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    // Inner left ear
    canvas.drawPath(
      Path()
        ..moveTo(cx - 13, size.height * 0.2)
        ..lineTo(cx - 17, size.height * 0.1)
        ..lineTo(cx - 8, size.height * 0.18)
        ..close(),
      Paint()..color = _softPink.withValues(alpha: 0.5),
    );
    // Right ear
    final rightEar = Path()
      ..moveTo(cx + 14, size.height * 0.22)
      ..lineTo(cx + 20, size.height * 0.06)
      ..lineTo(cx + 6, size.height * 0.18)
      ..close();
    canvas.drawPath(rightEar, earPaint);
    canvas.drawPath(
      Path()
        ..moveTo(cx + 13, size.height * 0.2)
        ..lineTo(cx + 17, size.height * 0.1)
        ..lineTo(cx + 8, size.height * 0.18)
        ..close(),
      Paint()..color = _softPink.withValues(alpha: 0.5),
    );

    // === FACE ===
    // Eyes
    final eyeY = size.height * 0.33;
    final eyeHalfH = blinkProgress < 0.5 ? 5.0 * (1 - blinkProgress * 2) : 5.0 * ((blinkProgress - 0.5) * 2);
    final eyeOpen = eyeHalfH.clamp(0.5, 5.0);

    // Gleaming eyes (amber)
    for (final ex in [cx - 7.0, cx + 7.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, eyeY), width: 8, height: eyeOpen * 2),
        Paint()..color = _amber,
      );
      // Pupil
      if (eyeOpen > 1.5) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ex + 1, eyeY), width: 4, height: eyeOpen * 1.2),
          Paint()..color = _deepBrown,
        );
        // Glint
        canvas.drawCircle(Offset(ex - 1.5, eyeY - 1.5), 1.2,
            Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }

    // Tiny nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height * 0.4), width: 5, height: 3),
      Paint()..color = _softPink,
    );

    // Whiskers
    final whiskerPaint = Paint()
      ..color = _warmWhite.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final wy = size.height * 0.41 + (i - 1) * 3.5;
      canvas.drawLine(Offset(cx - 8, wy), Offset(cx - 19, wy - 1 + i * 0.5), whiskerPaint);
      canvas.drawLine(Offset(cx + 8, wy), Offset(cx + 19, wy - 1 + i * 0.5), whiskerPaint);
    }

    // Tiny smile
    final smilePath = Path()
      ..moveTo(cx - 4, size.height * 0.43)
      ..quadraticBezierTo(cx, size.height * 0.46, cx + 4, size.height * 0.43);
    canvas.drawPath(smilePath, Paint()
      ..color = _warmWhite.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round);

    // === TINY MUSIC NOTE floating above ===
    final noteAlpha = math.sin(noteProgress * math.pi).clamp(0.0, 1.0);
    final noteY = size.height * 0.04 - noteProgress * 12;
    final noteX = cx + 14 + math.sin(noteProgress * math.pi * 2) * 4;
    if (noteAlpha > 0.05) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(noteX, noteY), width: 6, height: 4.5),
        Paint()..color = _amber.withValues(alpha: noteAlpha * 0.8),
      );
      canvas.drawLine(
        Offset(noteX + 2.7, noteY),
        Offset(noteX + 2.7, noteY - 7),
        Paint()
          ..color = _amber.withValues(alpha: noteAlpha * 0.8)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // === PAWS ===
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 16, size.height * 0.84), width: 12, height: 8),
      Paint()..color = const Color(0xFF3A1A08),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 16, size.height * 0.84), width: 12, height: 8),
      Paint()..color = const Color(0xFF3A1A08),
    );

    // Toe beans
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
          Offset(cx - 18 + i * 4.0, size.height * 0.86), 1.4,
          Paint()..color = _softPink.withValues(alpha: 0.6));
      canvas.drawCircle(
          Offset(cx + 14 + i * 4.0, size.height * 0.86), 1.4,
          Paint()..color = _softPink.withValues(alpha: 0.6));
    }

    // === TAIL ===
    final tailPath = Path()
      ..moveTo(cx + 17, size.height * 0.78)
      ..quadraticBezierTo(cx + 32, size.height * 0.6, cx + 26, size.height * 0.5);
    canvas.drawPath(tailPath, Paint()
      ..color = const Color(0xFF3A1A08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    // Tail tip
    canvas.drawCircle(Offset(cx + 26, size.height * 0.5), 4,
        Paint()..color = const Color(0xFF4A2808));
  }

  @override
  bool shouldRepaint(_CompanionPainter old) =>
      old.blinkProgress != blinkProgress || old.noteProgress != noteProgress;
}
