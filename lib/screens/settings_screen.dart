import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/settings_provider.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yvl/screens/settings/components/font_picker_dialog.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yvl/screens/about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final currentQuality = settingsState.audioQuality;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(context, 'Appearance', [
                ListTile(
                  title: Text('App Theme',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(_themeLabel(settingsState.themeType),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  trailing: Icon(FluentIcons.paint_brush_24_regular,
                      color: Theme.of(context).colorScheme.onSurface),
                  onTap: () => _showThemeDialog(context, ref, settingsState.themeType),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Consumer(
                  builder: (context, ref, _) {
                    final currentFont = ref.watch(settingsProvider).appFontFamily;
                    return ListTile(
                      title: Text('App Font',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      subtitle: Text(currentFont,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                      trailing: Icon(FluentIcons.text_font_24_regular,
                          color: Theme.of(context).colorScheme.onSurface),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const FontPickerDialog(),
                        );
                      },
                    );
                  },
                ),
              ]),

              _buildSection(context, 'Audio Quality', [
                _buildQualityOption(context, ref, 'High', AudioQuality.high, currentQuality),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _buildQualityOption(context, ref, 'Medium', AudioQuality.medium, currentQuality),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _buildQualityOption(context, ref, 'Low', AudioQuality.low, currentQuality),
              ]),

              Consumer(
                builder: (context, ref, _) {
                  final storage = ref.watch(storageServiceProvider);
                  return ValueListenableBuilder(
                    valueListenable: storage.settingsListenable,
                    builder: (context, box, _) {
                      return _buildSection(context, 'Playback', [
                        ValueListenableBuilder<bool>(
                          valueListenable: ref.watch(audioHandlerProvider).isLofiModeNotifier,
                          builder: (context, isLofi, _) {
                            return ListTile(
                              title: Text('Lofi Mode',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              subtitle: Text('Apply speed and pitch effects',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                              trailing: Switch(
                                value: isLofi,
                                onChanged: (value) =>
                                    ref.read(audioHandlerProvider).toggleLofiMode(),
                                activeThumbColor: Theme.of(context).colorScheme.primary,
                                activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          title: Text('Lofi Mode Fine-tuning',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('Adjust Speed and Pitch',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Icon(FluentIcons.music_note_2_24_regular,
                              color: Theme.of(context).colorScheme.onSurface),
                          onTap: () => _showLofiSettingsDialog(context, ref, storage),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          title: Text('Auto Queue',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('Automatically add recommended songs to queue',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Switch(
                            value: storage.isAutoQueueEnabled,
                            onChanged: (value) => storage.setAutoQueueEnabled(value),
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          title: Text('Open YouTube Links in App',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('Intercept YouTube URLs to play locally',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Switch(
                            value: storage.handleAppLinks,
                            onChanged: (value) async => await storage.setHandleAppLinks(value),
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          title: Text('Show YouTube Music on Home',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('Display dynamic content rows from YTM on your Home Feed',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: StatefulBuilder(
                            builder: (context, setState) {
                              return Switch(
                                value: storage.showYtmHome,
                                onChanged: (value) async {
                                  await storage.setShowYtmHome(value);
                                  setState(() {});
                                },
                                activeThumbColor: Theme.of(context).colorScheme.primary,
                                activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              );
                            },
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          title: Text('Ignore Battery Optimizations',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('Prevent app from being suspended',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Icon(FluentIcons.battery_warning_24_regular,
                              color: Theme.of(context).colorScheme.onSurface),
                          onTap: () async =>
                              await Permission.ignoreBatteryOptimizations.request(),
                        ),
                      ]);
                    },
                  );
                },
              ),

              // About section
              _buildSection(context, 'About', [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF00BCD4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00BCD4).withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('YVL',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('YVL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text('Premium Music Client',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                ListTile(
                  leading: Icon(FluentIcons.info_24_regular, color: Theme.of(context).colorScheme.onSurface, size: 20),
                  title: Text('Version', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Text('2.1.6', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                ListTile(
                  leading: Icon(FluentIcons.person_24_regular, color: Theme.of(context).colorScheme.onSurface, size: 20),
                  title: Text('Developer', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Text('w shourya', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                ListTile(
                  leading: Icon(FluentIcons.code_24_regular, color: Theme.of(context).colorScheme.onSurface, size: 20),
                  title: Text('About YVL', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Icon(FluentIcons.open_24_regular, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQualityOption(BuildContext context, WidgetRef ref, String title,
      AudioQuality quality, AudioQuality currentQuality) {
    final isSelected = quality == currentQuality;
    return ListTile(
      title: Text(title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )),
      trailing: isSelected ? const Icon(FluentIcons.checkmark_24_regular, color: Colors.white) : null,
      onTap: () => ref.read(settingsProvider.notifier).setAudioQuality(quality),
    );
  }

  void _showLofiSettingsDialog(BuildContext context, WidgetRef ref, StorageService storage) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            title: Text('Lofi Mode Settings',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Playback Speed',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                Row(children: [
                  Text('${storage.lofiSpeed.toStringAsFixed(2)}x',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: storage.lofiSpeed,
                      min: 0.5, max: 1.5, divisions: 20,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      onChanged: (value) {
                        setState(() => storage.setLofiSpeed(value));
                        ref.read(audioHandlerProvider).updateLofiSettings();
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text('Playback Pitch',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                Row(children: [
                  Text('${storage.lofiPitch.toStringAsFixed(2)}x',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: storage.lofiPitch,
                      min: 0.5, max: 1.5, divisions: 20,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      onChanged: (value) {
                        setState(() => storage.setLofiPitch(value));
                        ref.read(audioHandlerProvider).updateLofiSettings();
                      },
                    ),
                  ),
                ]),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(ThemeType t) {
    switch (t) {
      case ThemeType.auto: return 'Auto (System)';
      case ThemeType.dark: return 'Dark (Ultra Black)';
      case ThemeType.light: return 'Light';
      case ThemeType.sky: return 'Sky (Animated)';
      case ThemeType.doodle: return 'Doodle (Animated)';
      case ThemeType.cozyNight: return 'Cozy Night Studio';
      case ThemeType.almondDark: return 'Almond Dark';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeType currentTheme) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final cur = ref.watch(settingsProvider).themeType;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('App Theme',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    const SizedBox(height: 20),
                    // Row 1: Auto, Dark, Light
                    Row(children: [
                      _buildThemeCard(context, ref, ThemeType.auto, cur,
                          icon: FluentIcons.phone_24_regular, label: 'Auto', sublabel: 'Follow system',
                          topColor: const Color(0xFF1a1a2e), bottomColor: const Color(0xFFf0f4ff), splitDiagonal: true),
                      const SizedBox(width: 10),
                      _buildThemeCard(context, ref, ThemeType.dark, cur,
                          icon: Icons.brightness_3, label: 'Dark', sublabel: 'Ultra black',
                          topColor: const Color(0xFF000000), bottomColor: const Color(0xFF0A0A0A), splitDiagonal: false),
                      const SizedBox(width: 10),
                      _buildThemeCard(context, ref, ThemeType.light, cur,
                          icon: FluentIcons.weather_sunny_24_regular, label: 'Light', sublabel: 'Always light',
                          topColor: const Color(0xFFfafafa), bottomColor: const Color(0xFFe8eaf6), splitDiagonal: false),
                    ]),
                    const SizedBox(height: 12),
                    // Row 2: Sky (full width)
                    _buildThemeCardWide(context, ref, ThemeType.sky, cur,
                        icon: Icons.cloud_outlined, label: 'Sky', sublabel: 'Animated sky gradient',
                        color1: const Color(0xFF010A18), color2: const Color(0xFF006064), color3: const Color(0xFF0D47A1)),
                    const SizedBox(height: 12),
                    // Row 3: Doodle (full width)
                    _buildThemeCardWide(context, ref, ThemeType.doodle, cur,
                        icon: Icons.music_note_rounded, label: 'Doodle', sublabel: 'Warm cream with animated music notes',
                        color1: const Color(0xFFFF6B6B), color2: const Color(0xFFFFB347), color3: const Color(0xFF4ECDC4)),
                    const SizedBox(height: 12),
                    // Row 4: Cozy Night Studio (full width)
                    _buildThemeCardWide(context, ref, ThemeType.cozyNight, cur,
                        icon: Icons.nights_stay_rounded, label: 'Cozy Night', sublabel: 'Warm amber studio with rain & lamp glow',
                        color1: const Color(0xFF100A06), color2: const Color(0xFFFFB347), color3: const Color(0xFF3D2010)),
                    const SizedBox(height: 12),
                    // Row: Almond Dark
                    _buildThemeCardWide(context, ref, ThemeType.almondDark, cur,
                        icon: Icons.coffee_rounded, label: 'Almond Dark', sublabel: 'Ultra dark with warm almond & mocha tones',
                        color1: const Color(0xFF0C0A08), color2: const Color(0xFFC8A87A), color3: const Color(0xFF3A2E1E)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, ThemeType theme, ThemeType currentTheme, {
    required IconData icon, required String label, required String sublabel,
    required Color topColor, required Color bottomColor, required bool splitDiagonal,
  }) {
    final isSelected = theme == currentTheme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(settingsProvider.notifier).setThemeType(theme);
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                SizedBox(
                  height: 120,
                  child: splitDiagonal
                      ? CustomPaint(
                          size: const Size(double.infinity, 120),
                          painter: _DiagonalSplitPainter(topColor, bottomColor),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [topColor, bottomColor],
                            ),
                          ),
                        ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(FluentIcons.checkmark_circle_24_filled, size: 16,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 3),
                          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface))),
                        ]),
                        Text(sublabel, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCardWide(BuildContext context, WidgetRef ref, ThemeType theme, ThemeType currentTheme, {
    required IconData icon, required String label, required String sublabel,
    required Color color1, required Color color2, required Color color3,
  }) {
    final isSelected = theme == currentTheme;
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeType(theme);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            width: isSelected ? 2.5 : 1.5,
          ),
          gradient: LinearGradient(
            colors: [color1, color2, color3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x6600E5FF), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagonalSplitPainter extends CustomPainter {
  final Color top;
  final Color bottom;
  const _DiagonalSplitPainter(this.top, this.bottom);

  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()..color = top;
    final paintBottom = Paint()..color = bottom;
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    final path2 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paintTop);
    canvas.drawPath(path2, paintBottom);
  }

  @override
  bool shouldRepaint(_DiagonalSplitPainter old) => old.top != top || old.bottom != bottom;
}
