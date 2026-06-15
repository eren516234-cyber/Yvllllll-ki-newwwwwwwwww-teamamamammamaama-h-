import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yvl/services/storage_service.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _cookieController = TextEditingController();
  bool _ytmConnected = false;
  bool _spotifyConnected = false;
  bool _showCookieField = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _ytmConnected = storage.ytmCookie != null && storage.ytmCookie!.isNotEmpty;
    _spotifyConnected = storage.isSpotifyConnected;
  }

  @override
  void dispose() {
    _cookieController.dispose();
    super.dispose();
  }

  Future<void> _saveYtmCookie() async {
    final cookie = _cookieController.text.trim();
    if (cookie.isEmpty) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final storage = ref.read(storageServiceProvider);
    await storage.setYtmCookie(cookie);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _ytmConnected = true;
        _showCookieField = false;
        _cookieController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube Music connected successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _disconnectYtm() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setYtmCookie(null);
    setState(() {
      _ytmConnected = false;
      _showCookieField = false;
    });
  }

  Future<void> _connectSpotify() async {
    final uri = Uri.parse('https://open.spotify.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FluentIcons.arrow_left_24_regular, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connect Services',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import your playlists and connect your music accounts for a personalized experience.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // YouTube Music Card
            _buildServiceCard(
              context,
              icon: const _YtmIcon(),
              serviceName: 'YouTube Music',
              description: _ytmConnected
                  ? 'Connected — your YTM playlists & library are synced'
                  : 'Import your playlists, history, and liked songs',
              connected: _ytmConnected,
              onConnect: () => setState(() => _showCookieField = !_showCookieField),
              onDisconnect: _disconnectYtm,
              connectLabel: _showCookieField ? 'Cancel' : 'Connect',
              extra: _showCookieField ? _buildCookieForm(context, theme) : null,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Spotify Card
            _buildServiceCard(
              context,
              icon: const _SpotifyIcon(),
              serviceName: 'Spotify',
              description: _spotifyConnected
                  ? 'Connected — import playlists anytime from Library'
                  : 'Import your Spotify playlists by sharing them',
              connected: _spotifyConnected,
              onConnect: _connectSpotify,
              onDisconnect: () {
                ref.read(storageServiceProvider).setSpotifyConnected(false);
                setState(() => _spotifyConnected = false);
              },
              connectLabel: 'Open Spotify',
            ).animate().fadeIn(duration: 400.ms, delay: 180.ms).slideY(begin: 0.05),

            const SizedBox(height: 28),

            // How to get YTM cookie guide
            _buildGuide(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required Widget icon,
    required String serviceName,
    required String description,
    required bool connected,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
    required String connectLabel,
    Widget? extra,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? Colors.green.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            serviceName,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (connected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Connected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onConnect();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: connected
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                          : theme.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      connectLabel,
                      style: TextStyle(
                        color: connected
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.colorScheme.surface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (connected) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDisconnect();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: 16),
              extra,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCookieForm(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Text(
          'Enter your YouTube Music cookie to unlock your personal playlists and recommendations.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cookieController,
          maxLines: 3,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Paste your cookie here (starts with "SAPISID=...")',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              fontSize: 12,
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSaving ? null : _saveYtmCookie,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Cookie',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuide(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.info_24_regular, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'How to get YouTube Music cookie',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            '1. Open music.youtube.com in Chrome on PC',
            '2. Press F12 → Application → Cookies',
            '3. Select https://music.youtube.com',
            '4. Copy the value of the "SAPISID" cookie',
            '5. Paste it above and hit Save',
          ].asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              e.value,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          )),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

class _YtmIcon extends StatelessWidget {
  const _YtmIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SpotifyIcon extends StatelessWidget {
  const _SpotifyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
