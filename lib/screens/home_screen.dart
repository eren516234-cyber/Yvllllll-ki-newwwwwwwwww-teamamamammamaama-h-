import 'dart:ui';
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
import 'package:yvl/services/storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yvl/screens/settings_screen.dart';
import 'package:yvl/providers/home_provider.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yvl/screens/charts_screen.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeIndexedStack(
        index: selectedIndex,
        children: [
          _HomeTab(),
          const ExploreScreen(),
          const ChartsScreen(),
          const LibraryScreen(),
          const SettingsScreen(),
        ],
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

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  void _playSong(HomeItem item) {
    if (item.videoId == null) return;
    HapticFeedback.lightImpact();
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

            // ── Greeting ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
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
              ),
            ),

            // ── Filter Chips ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterChips(context, ref)),

            // ── Sections ─────────────────────────────────────────────────
            homeSectionsAsync.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmpty(context, ref));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SectionRow(section: sections[i], delay: i * 60, onPlay: _playSong),
                    childCount: sections.length,
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(child: _buildLoading(context)),
              error: (_, __) => SliverToBoxAdapter(child: _buildEmpty(context, ref)),
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                )),
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
              _buildAvatarMenu(context, ref, storage, username, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarMenu(BuildContext context, WidgetRef ref, StorageService storage, String username, ThemeData theme) {
    return PopupMenuButton<String>(
      onOpened: () => HapticFeedback.lightImpact(),
      offset: const Offset(0, 50),
      color: Colors.transparent,
      elevation: 0,
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
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    final theme = Theme.of(context);
    final filters = ['All', 'Songs', 'Albums', 'Playlists'];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final selected = filter == f;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(homeFilterProvider.notifier).state = f;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: selected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Icon(FluentIcons.music_note_2_24_regular, size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Pull to refresh', style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 15)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(homeSectionsProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Section Row ──────────────────────────────────────────────────────────
class _SectionRow extends StatelessWidget {
  final HomeSection section;
  final int delay;
  final void Function(HomeItem) onPlay;

  const _SectionRow({required this.section, required this.delay, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              section.title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: section.items.length,
              itemBuilder: (ctx, i) {
                final item = section.items[i];
                final thumb = item.thumbnails.isNotEmpty
                    ? (item.thumbnails.first['url'] as String? ?? '')
                    : '';
                return GestureDetector(
                  onTap: () => onPlay(item),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: thumb,
                                width: 140,
                                height: 130,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 140, height: 130,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(FluentIcons.music_note_2_24_regular,
                                      size: 36, color: theme.colorScheme.primary),
                                ),
                              ),
                              Positioned(
                                bottom: 8, right: 8,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
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
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: Duration(milliseconds: delay + i * 30)).slideX(begin: 0.08);
              },
            ),
          ),
        ],
      ),
    );
  }
}
