import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/services/spotify_import_service.dart';
import 'package:yvl/services/youtube_import_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

enum _ImportSource { spotify, youtube }

class SpotifyImportDialog extends ConsumerStatefulWidget {
  const SpotifyImportDialog({super.key});

  @override
  ConsumerState<SpotifyImportDialog> createState() => _SpotifyImportDialogState();
}

class _SpotifyImportDialogState extends ConsumerState<SpotifyImportDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription? _subscription;
  SpotifyImportProgress? _spotifyProgress;
  YoutubeImportProgress? _youtubeProgress;
  bool _isImporting = false;
  _ImportSource _source = _ImportSource.spotify;

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  bool get _isComplete {
    if (_source == _ImportSource.spotify) {
      return _spotifyProgress?.isComplete ?? false;
    }
    return _youtubeProgress?.isComplete ?? false;
  }

  bool get _hasError {
    if (_source == _ImportSource.spotify) {
      return _spotifyProgress?.hasError ?? false;
    }
    return _youtubeProgress?.hasError ?? false;
  }

  String get _status {
    if (_source == _ImportSource.spotify) {
      return _spotifyProgress?.status ?? '';
    }
    return _youtubeProgress?.status ?? '';
  }

  int get _total {
    if (_source == _ImportSource.spotify) return _spotifyProgress?.total ?? 0;
    return _youtubeProgress?.total ?? 0;
  }

  int get _current {
    if (_source == _ImportSource.spotify) return _spotifyProgress?.current ?? 0;
    return _youtubeProgress?.current ?? 0;
  }

  String? get _errorMessage {
    if (_source == _ImportSource.spotify) return _spotifyProgress?.errorMessage;
    return _youtubeProgress?.errorMessage;
  }

  void _startImport() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    _subscription?.cancel();

    setState(() {
      _isImporting = true;
      _spotifyProgress = null;
      _youtubeProgress = null;
    });

    if (_source == _ImportSource.spotify) {
      final service = ref.read(spotifyImportServiceProvider);
      _subscription = service.importPlaylist(input).listen(
        (progress) {
          if (mounted) setState(() { _spotifyProgress = progress; if (progress.isComplete) _isImporting = false; });
        },
        onError: (e) {
          if (mounted) setState(() { _isImporting = false; _spotifyProgress = SpotifyImportProgress(hasError: true, isComplete: true, errorMessage: e.toString()); });
        },
      );
    } else {
      final service = ref.read(youtubeImportServiceProvider);
      _subscription = service.importPlaylist(input).listen(
        (progress) {
          if (mounted) setState(() { _youtubeProgress = progress; if (progress.isComplete) _isImporting = false; });
        },
        onError: (e) {
          if (mounted) setState(() { _isImporting = false; _youtubeProgress = YoutubeImportProgress(hasError: true, isComplete: true, errorMessage: e.toString()); });
        },
      );
    }
  }

  void _reset() {
    _subscription?.cancel();
    setState(() {
      _isImporting = false;
      _spotifyProgress = null;
      _youtubeProgress = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spotifyGreen = const Color(0xFF1DB954);
    final youtubeRed = const Color(0xFFFF0000);
    final accentColor = _source == _ImportSource.spotify ? spotifyGreen : youtubeRed;
    final hasProgress = _spotifyProgress != null || _youtubeProgress != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FluentIcons.arrow_import_24_filled,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Import Playlist',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Source Toggle (only show when not importing)
              if (!_isImporting && !_isComplete) ...[
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _ToggleTab(
                        label: 'Spotify',
                        icon: Icons.music_note,
                        color: spotifyGreen,
                        selected: _source == _ImportSource.spotify,
                        onTap: () => setState(() { _source = _ImportSource.spotify; _controller.clear(); }),
                      ),
                      _ToggleTab(
                        label: 'YouTube',
                        icon: Icons.play_circle_fill,
                        color: youtubeRed,
                        selected: _source == _ImportSource.youtube,
                        onTap: () => setState(() { _source = _ImportSource.youtube; _controller.clear(); }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // URL Input
              if (!_isImporting && (!hasProgress || _hasError)) ...[
                CupertinoTextField(
                  controller: _controller,
                  placeholder: _source == _ImportSource.spotify
                      ? 'Paste Spotify Playlist URL'
                      : 'Paste YouTube Playlist URL',
                  placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : CupertinoColors.systemGrey6.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Icon(FluentIcons.link_24_regular, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
                  ),
                ),
                if (_hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.error_circle_24_regular, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage ?? 'An error occurred.',
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (hasProgress) ...[
                const SizedBox(height: 12),
                if (!_isComplete)
                  const SizedBox(
                    height: 56,
                    width: 56,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                else if (!_hasError)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(FluentIcons.checkmark_circle_48_filled, color: accentColor, size: 48),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_total > 0 && !_isComplete) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _total > 0 ? (_current / _total) : null,
                      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${((_current / _total) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isImporting) ...[
                    TextButton(
                      onPressed: _isComplete && !_hasError
                          ? () => Navigator.pop(context)
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isComplete && !_hasError ? 'Close' : 'Cancel',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!_isImporting && (!hasProgress || _hasError)) ...[
                      if (_hasError) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _reset,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Retry', style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _startImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Import', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
