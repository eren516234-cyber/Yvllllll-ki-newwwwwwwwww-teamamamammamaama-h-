import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:yvl/screens/webview_auth_screen.dart';
import 'package:yvl/services/storage_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _loadingFor;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    HapticFeedback.lightImpact();
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingComplete();
    if (mounted) _goToHome();
  }

  Future<void> _handleGoogleLogin() async {
    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _loadingFor = 'google'; });

    try {
      final result = await Navigator.of(context).push<Map<String, String>>(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const WebViewAuthScreen(
            provider: AuthProvider.google,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      if (result != null && mounted) {
        final storage = ref.read(storageServiceProvider);
        if (result['token'] != null) {
          await storage.setAuthToken(result['token']!);
        }
        await storage.setUserInfo(
          result['name'] ?? 'Music Lover',
          result['email'] ?? '',
          avatarUrl: result['avatar'],
        );
        await storage.setOnboardingComplete();
        if (mounted) _goToHome();
      } else {
        setState(() { _isLoading = false; _loadingFor = null; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _loadingFor = null; });
        _showError('Google login failed. Please try again.');
      }
    }
  }

  Future<void> _handleSpotifyLogin() async {
    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _loadingFor = 'spotify'; });

    try {
      final result = await Navigator.of(context).push<Map<String, String>>(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const WebViewAuthScreen(
            provider: AuthProvider.spotify,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      if (result != null && mounted) {
        final storage = ref.read(storageServiceProvider);
        if (result['token'] != null) {
          await storage.setSpotifyToken(result['token']!);
        }
        await storage.setUserInfo(
          result['name'] ?? 'Music Lover',
          result['email'] ?? '',
          avatarUrl: result['avatar'],
        );
        await storage.setOnboardingComplete();
        if (mounted) _goToHome();
      } else {
        setState(() { _isLoading = false; _loadingFor = null; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _loadingFor = null; });
        _showError('Spotify login failed. Please try again.');
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final t = _bgController.value;
              return Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.3 + t * 0.6,
                      -0.5 + t * 0.3,
                    ),
                    radius: 1.4,
                    colors: const [
                      Color(0xFF1A0533),
                      Color(0xFF0D1B4B),
                      Color(0xFF000000),
                    ],
                  ),
                ),
              );
            },
          ),

          // Glow orbs
          Positioned(
            top: size.height * 0.15,
            left: -80,
            child: _GlowOrb(color: const Color(0xFF6C00FF), size: 260),
          ),
          Positioned(
            bottom: size.height * 0.2,
            right: -60,
            child: _GlowOrb(color: const Color(0xFF1DB954), size: 200),
          ),
          Positioned(
            top: size.height * 0.45,
            right: size.width * 0.1,
            child: _GlowOrb(color: const Color(0xFF4285F4), size: 150),
          ),

          // Frosted glass overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo + App name
                Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C00FF).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    Text(
                      'YVL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 10),
                    Text(
                      'Premium music, no limits',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                  ],
                ),

                const Spacer(flex: 3),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // Google button
                      _AuthButton(
                        label: 'Continue with Google',
                        icon: _GoogleIcon(),
                        color: Colors.white,
                        textColor: const Color(0xFF1A1A1A),
                        isLoading: _loadingFor == 'google',
                        onTap: _isLoading ? null : _handleGoogleLogin,
                      )
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3),

                      const SizedBox(height: 14),

                      // Spotify button
                      _AuthButton(
                        label: 'Continue with Spotify',
                        icon: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        color: const Color(0xFF1DB954),
                        textColor: Colors.white,
                        isLoading: _loadingFor == 'spotify',
                        onTap: _isLoading ? null : _handleSpotifyLogin,
                      )
                          .animate(delay: 620.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Skip button
                GestureDetector(
                  onTap: _isLoading ? null : _handleSkip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                )
                    .animate(delay: 750.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 8),

                // Terms note
                Text(
                  'By continuing, you agree to our Terms of Service',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.22),
                    fontSize: 11,
                  ),
                )
                    .animate(delay: 850.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glow Orb ────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ─── Auth Button ─────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.isLoading,
    this.onTap,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.onTap != null) _pressCtrl.reverse(); },
      onTapUp: (_) { _pressCtrl.forward(); widget.onTap?.call(); },
      onTapCancel: () { _pressCtrl.forward(); },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: widget.textColor,
                  ),
                )
              else ...[
                widget.icon,
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google Icon ─────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final r = size.width / 2;

    // Draw a simplified Google G
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.57, 3.14, false, paint..style = PaintingStyle.stroke..strokeWidth = 3.5);

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.57, 1.57, false, paint);

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14, 0.79, false, paint);

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.93, 0.79, false, paint);

    // White horizontal bar for G
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - 2, r, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
