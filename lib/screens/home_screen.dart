import 'dart:ui';
import 'dart:math' as math;
import 'package:yvl/screens/profile_screen.dart';
import 'package:yvl/screens/search_screen.dart';
import 'package:yvl/screens/explore_screen.dart';
import 'package:yvl/widgets/glass_menu_content.dart';
import 'package:yvl/widgets/fade_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/navigation_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yvl/screens/library_screen.dart';
import 'package:yvl/screens/subscribed_channels_screen.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yvl/screens/settings_screen.dart';
import 'package:yvl/widgets/glass_container.dart';
import 'package:yvl/services/update_service.dart';
import 'package:yvl/providers/home_provider.dart';
import 'package:yvl/services/ytm_home.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Filter helper: returns true if text contains Devanagari (Hindi) script
bool _isHindiText(String text) => RegExp(r'[\u0900-\u097F]').hasMatch(text);
bool _shouldShowItem({required String title, required String? artist}) =>
    !_isHindiText(title) && !_isHindiText(artist ?? '');


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = ref.read(storageServiceProvider);
      storage.refreshAll(silent: true);
      storage.fetchAndCacheUserAvatar();
      UpdateService().checkForUpdates(context);
      _checkAndShowSpotifyAnnouncement();
    });
  }

  void _checkAndShowSpotifyAnnouncement() async {
    final storage = ref.read(storageServiceProvider);
    if (!storage.hasSeenSpotifyAnnouncement) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => _buildSpotifyAnnouncementDialog(context, storage),
      );
    }
  }

  Widget _buildSpotifyAnnouncementDialog(BuildContext context, StorageService storage) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const spotifyGreen = Color(0xFF1DB954);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: spotifyGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(FluentIcons.music_note_2_24_filled, color: spotifyGreen, size: 56),
              ),
              const SizedBox(height: 28),
              Text('Spotify Import', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Easily bring your favorite Spotify playlists to YVL. Head over to the Library to get started!',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { storage.setHasSeenSpotifyAnnouncement(true); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(backgroundColor: spotifyGreen, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('Awesome', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () { storage.setHasSeenSpotifyAnnouncement(true); Navigator.pop(context); },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: Colors.transparent,
        child: FadeIndexedStack(
          index: selectedIndex,
          children: [
            _HomeTab(),
            const ExploreScreen(),
            const LibraryScreen(),
            const SubscribedChannelsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final ScrollController _scroll = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      setState(() => _scrollOffset = _scroll.offset);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final homeSectionsAsync = ref.watch(filteredHomeSectionsProvider);
    final storage = ref.watch(storageServiceProvider);
    final username = storage.username ?? 'Music Lover';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: theme.colorScheme.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async {
          await ref.read(homeSectionsProvider.notifier).refresh();
          await storage.refreshAll();
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(context, ref, storage, username),
            ),

            // ── Welcome Heading ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildWelcomeHeading(context, username),
            ),

            // ── Recent chips from first section ─────────────────────────
            homeSectionsAsync.maybeWhen(
              data: (sections) {
                if (sections.isEmpty || sections.first.items.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _buildRecentChips(context, sections.first.items.take(6).toList()),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Sections from data ──────────────────────────────────────
            homeSectionsAsync.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState(context, ref));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _HomeSectionCard(section: sections[i], delay: i * 80),
                    childCount: sections.length,
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(child: _buildLoading(context)),
              error: (_, __) => SliverToBoxAdapter(child: _buildEmptyState(context, ref)),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, StorageService storage, String username) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', height: 28, width: 28),
              const SizedBox(width: 10),
              Text('YVL',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(FluentIcons.search_24_regular, color: theme.colorScheme.onSurface, size: 24),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onOpened: () => HapticFeedback.lightImpact(),
                offset: const Offset(0, 50),
                color: Colors.transparent, elevation: 0,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: GlassMenuContent(
                      width: 260,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              ClipOval(
                                child: Builder(builder: (context) {
                                  final avatarUrl = storage.avatarUrl;
                                  final cachedSvg = storage.getUserAvatar();
                                  final isSvg = avatarUrl == null || avatarUrl.contains('.svg') || avatarUrl.contains('dicebear');
                                  if (isSvg && cachedSvg != null) {
                                    return SvgPicture.string(cachedSvg, height: 36, width: 36, fit: BoxFit.cover);
                                  }
                                  if (avatarUrl != null && !isSvg) {
                                    return CachedNetworkImage(imageUrl: avatarUrl, height: 36, width: 36, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(FluentIcons.person_24_filled, size: 20));
                                  }
                                  return SvgPicture.network('https://api.dicebear.com/9.x/rings/svg?seed=$username',
                                      height: 36, width: 36, fit: BoxFit.cover);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(username,
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (storage.email != null)
                                      Text(storage.email!,
                                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        const SizedBox(height: 4),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(FluentIcons.person_24_regular, color: theme.colorScheme.onSurface, size: 20),
                          title: Text('Profile', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          },
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(FluentIcons.settings_24_regular, color: theme.colorScheme.onSurface, size: 20),
                          title: Text('Settings', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                child: ClipOval(
                  child: ValueListenableBuilder(
                    valueListenable: storage.userAvatarListenable,
                    builder: (context, box, _) {
                      final avatarUrl = storage.avatarUrl;
                      final cachedSvg = storage.getUserAvatar();
                      final isSvg = avatarUrl == null || avatarUrl.contains('.svg') || avatarUrl.contains('dicebear');
                      if (isSvg && cachedSvg != null) {
                        return SvgPicture.string(cachedSvg, height: 32, width: 32, fit: BoxFit.cover);
                      }
                      if (avatarUrl != null) {
                        if (isSvg) {
                          return SvgPicture.network(avatarUrl, height: 32, width: 32, fit: BoxFit.cover,
                              placeholderBuilder: (context) => Container(padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2)));
                        } else {
                          return CachedNetworkImage(imageUrl: avatarUrl, height: 32, width: 32, fit: BoxFit.cover,
                              placeholder: (context, url) => Container(padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (context, url, error) => Icon(FluentIcons.person_24_filled, size: 20));
                        }
                      }
                      return SvgPicture.network('https://api.dicebear.com/9.x/rings/svg?seed=$username',
                          height: 32, width: 32, fit: BoxFit.cover,
                          placeholderBuilder: (context) => Container(padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2)));
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeading(BuildContext context, String username) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'Find the best\nmusic for you',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 80.ms).slideY(begin: 0.08),
        ],
      ),
    );
  }

  Widget _buildRecentChips(BuildContext context, List<HomeItem> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Recently played',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final thumb = item.thumbnails.isNotEmpty
                  ? (item.thumbnails.first['url'] as String? ?? '')
                  : '';
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.videoId == null) return;
                  final muzo = MuzoItem(
                    title: item.title,
                    resultType: item.type ?? 'song',
                    isExplicit: false,
                    artists: item.subtitle != null ? [MuzoArtist(name: item.subtitle!)] : null,
                    thumbnails: item.thumbnails.map((t) => MuzoThumbnail(
                      url: (t['url'] as String?) ?? '', width: 0, height: 0)).toList(),
                    videoId: item.videoId,
                  );
                  ref.read(audioHandlerProvider).playVideo(muzo);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          width: 38, height: 38,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 38, height: 38,
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: Icon(FluentIcons.music_note_2_24_regular,
                                size: 18, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 18, width: 120, margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8))),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    width: 140, height: 140, margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(FluentIcons.music_note_2_24_regular, size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Nothing here yet',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Search for songs or explore trending music',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => ref.read(homeSectionsProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.arrow_sync_24_regular, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text('Refresh', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Pill ─────────────────────────────────────────────────────────────
class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Home Section Card ──────────────────────────────────────────────────────
class _HomeSectionCard extends ConsumerWidget {
  final HomeSection section;
  final int delay;

  const _HomeSectionCard({required this.section, required this.delay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Choose card style based on section type
    final isPodcast = section.title.toLowerCase().contains('podcast');
    final isAlbum = section.title.toLowerCase().contains('album');

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _sectionColor(section.title, theme).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_sectionIcon(section.title), size: 16, color: _sectionColor(section.title, theme)),
                ),
                const SizedBox(width: 10),
                Text(
                  section.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Text('See all', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Cards
          if (isAlbum)
            _buildAlbumRow(context, ref, theme)
          else if (isPodcast)
            _buildPodcastRow(context, ref, theme)
          else
            _buildSongRow(context, ref, theme),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay)).slideY(begin: 0.08);
  }

  Color _sectionColor(String title, ThemeData theme) {
    final t = title.toLowerCase();
    if (t.contains('song')) return theme.colorScheme.primary;
    if (t.contains('podcast')) return const Color(0xFF9C27B0);
    if (t.contains('album')) return const Color(0xFFFF6B6B);
    return theme.colorScheme.primary;
  }

  IconData _sectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('song')) return FluentIcons.music_note_2_24_filled;
    if (t.contains('podcast')) return FluentIcons.headphones_24_filled;
    if (t.contains('album')) return FluentIcons.album_24_filled;
    return FluentIcons.music_note_2_24_regular;
  }

  Widget _buildSongRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: section.items.length,
        itemBuilder: (ctx, i) {
          final item = section.items[i];
          final thumb = item.thumbnails.isNotEmpty ? (item.thumbnails.first['url'] as String? ?? '') : '';
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (item.videoId == null) return;
              final muzo = MuzoItem(
                title: item.title,
                resultType: item.type ?? 'song',
                isExplicit: false,
                artists: item.subtitle != null ? [MuzoArtist(name: item.subtitle!)] : null,
                thumbnails: item.thumbnails.map((t) => MuzoThumbnail(url: (t['url'] as String?) ?? '', width: 0, height: 0)).toList(),
                videoId: item.videoId,
              );
              ref.read(audioHandlerProvider).playVideo(muzo);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumb,
                          width: 140, height: 130,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surface,
                            child: Icon(FluentIcons.music_note_2_24_regular, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 36),
                          ),
                        ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                  if (item.subtitle != null)
                    Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodcastRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: section.items.length,
        itemBuilder: (ctx, i) {
          final item = section.items[i];
          final thumb = item.thumbnails.isNotEmpty ? (item.thumbnails.first['url'] as String? ?? '') : '';
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (item.videoId == null) return;
              final muzo = MuzoItem(
                title: item.title,
                resultType: item.type ?? 'podcast',
                isExplicit: false,
                artists: item.subtitle != null ? [MuzoArtist(name: item.subtitle!)] : null,
                thumbnails: item.thumbnails.map((t) => MuzoThumbnail(url: (t['url'] as String?) ?? '', width: 0, height: 0)).toList(),
                videoId: item.videoId,
              );
              ref.read(audioHandlerProvider).playVideo(muzo);
            },
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: thumb, width: 64, height: 64, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                        width: 64, height: 64,
                        child: const Icon(FluentIcons.headphones_24_filled, color: Color(0xFF9C27B0), size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                        if (item.subtitle != null)
                          Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF9C27B0), size: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: section.items.length,
        itemBuilder: (ctx, i) {
          final item = section.items[i];
          final thumb = item.thumbnails.isNotEmpty ? (item.thumbnails.first['url'] as String? ?? '') : '';
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (item.videoId == null) return;
              final muzo = MuzoItem(
                title: item.title,
                resultType: 'album',
                isExplicit: false,
                artists: item.subtitle != null ? [MuzoArtist(name: item.subtitle!)] : null,
                thumbnails: item.thumbnails.map((t) => MuzoThumbnail(url: (t['url'] as String?) ?? '', width: 0, height: 0)).toList(),
                videoId: item.videoId,
              );
              ref.read(audioHandlerProvider).playVideo(muzo);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: thumb, width: 130, height: 130, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                        width: 130, height: 130,
                        child: const Icon(FluentIcons.album_24_filled, color: Color(0xFFFF6B6B), size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                  if (item.subtitle != null)
                    Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
