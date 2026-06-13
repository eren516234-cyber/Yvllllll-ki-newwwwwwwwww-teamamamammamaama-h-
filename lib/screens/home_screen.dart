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
import 'package:yvl/providers/search_provider.dart';
import 'package:yvl/screens/library_screen.dart';
import 'package:yvl/screens/subscribed_channels_screen.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/models/user_data.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yvl/screens/settings_screen.dart';
import 'package:yvl/widgets/glass_container.dart';
import 'package:yvl/services/update_service.dart';
import 'package:yvl/providers/home_provider.dart';
import 'package:yvl/widgets/home_section_widget.dart';
import 'package:yvl/widgets/rect_home_item.dart';
import 'package:yvl/widgets/home_item_widget.dart';
import 'package:yvl/services/ytm_home.dart';
import 'package:yvl/widgets/skeleton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';


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
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeIndexedStack(
          index: selectedIndex,
          children: [
            _buildHomeTab(context, ref),    // 0: Home feed
            const ExploreScreen(),          // 1: Explore (spinning dialer)
            const LibraryScreen(),          // 2: Library
            const SubscribedChannelsScreen(), // 3: Channels
            const SettingsScreen(),         // 4: Settings
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, WidgetRef ref) {
    final homeSectionsAsync = ref.watch(filteredHomeSectionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white),
        onRefresh: () async {
          await ref.read(homeSectionsProvider.notifier).refresh();
          await ref.read(storageServiceProvider).refreshAll();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, ref, isDesktop)),
            SliverToBoxAdapter(child: _buildFilterChipsRow(context, ref, isDesktop)),

            // Recents label
            if (ref.read(storageServiceProvider).historyListenable.value.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 24, 16, 16),
                  child: Text('Recents',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                ),
              ),

            _buildRecentsGrid(context, ref, isDesktop),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // YTM home sections
            if (ref.watch(storageServiceProvider).showYtmHome)
              homeSectionsAsync.when(
                data: (sections) {
                  if (sections.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyHomeState(context, ref),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => HomeSectionWidget(section: sections[index]),
                      childCount: sections.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: HomeSkeletonList(),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Error loading home: $err', style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ),

            _buildFavoritesSection(context, ref),
            _buildYourPlaylistsSection(context, ref),

            const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHomeState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(FluentIcons.music_note_2_24_regular, size: 56,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Nothing here yet',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Search for songs or explore trending music',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => ref.read(homeSectionsProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.arrow_sync_24_regular, size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text('Refresh', style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDesktop) {
    final storage = ref.watch(storageServiceProvider);
    final username = storage.username ?? 'User';
    final hPad = isDesktop ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isDesktop ? 28 : 16, hPad, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', height: isDesktop ? 34 : 28, width: isDesktop ? 34 : 28),
              const SizedBox(width: 10),
              Text('YVL',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isDesktop ? 26 : 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(FluentIcons.search_24_regular,
                    color: Theme.of(context).colorScheme.onSurface, size: isDesktop ? 28 : 24),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
              const SizedBox(width: 8),
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
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (storage.email != null)
                                      Text(storage.email!,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                        const SizedBox(height: 4),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(FluentIcons.person_24_regular, color: Theme.of(context).colorScheme.onSurface, size: 20),
                          title: Text('Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          },
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(FluentIcons.settings_24_regular, color: Theme.of(context).colorScheme.onSurface, size: 20),
                          title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
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
                        return SvgPicture.string(cachedSvg, height: isDesktop ? 40 : 32, width: isDesktop ? 40 : 32, fit: BoxFit.cover);
                      }
                      if (avatarUrl != null) {
                        if (isSvg) {
                          return SvgPicture.network(avatarUrl, height: isDesktop ? 40 : 32, width: isDesktop ? 40 : 32, fit: BoxFit.cover,
                              placeholderBuilder: (context) => Container(padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2)));
                        } else {
                          return CachedNetworkImage(imageUrl: avatarUrl, height: isDesktop ? 40 : 32, width: isDesktop ? 40 : 32, fit: BoxFit.cover,
                              placeholder: (context, url) => Container(padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (context, url, error) => Icon(FluentIcons.person_24_filled, size: isDesktop ? 24 : 20));
                        }
                      }
                      return SvgPicture.network('https://api.dicebear.com/9.x/rings/svg?seed=$username',
                          height: isDesktop ? 40 : 32, width: isDesktop ? 40 : 32, fit: BoxFit.cover,
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

  Widget _buildFilterChipsRow(BuildContext context, WidgetRef ref, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 12, isDesktop ? 24 : 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Songs', 'Podcasts', 'Albums', 'Playlists']
              .map((label) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(context, ref, label),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label) {
    final currentFilter = ref.watch(homeFilterProvider);
    final isSelected = currentFilter == label;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(homeFilterProvider.notifier).state = label;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildRecentsGrid(BuildContext context, WidgetRef ref, bool isDesktop) {
    final storage = ref.watch(storageServiceProvider);
    return ValueListenableBuilder<List<MuzoItem>>(
      valueListenable: storage.historyListenable,
      builder: (context, history, _) {
        if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final hPad = isDesktop ? 24.0 : 16.0;
        final crossAxisCount = isDesktop ? 4 : 2;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = history[index];
                return RectHomeItem(item: item);
              },
              childCount: history.take(isDesktop ? 8 : 6).length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesSection(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    return ValueListenableBuilder<List<MuzoItem>>(
      valueListenable: storage.favoritesListenable,
      builder: (context, favorites, _) {
        if (favorites.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Liked Songs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favorites.take(15).length,
                itemBuilder: (context, index) => _MuzoCard(item: favorites[index]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildYourPlaylistsSection(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    return ValueListenableBuilder(
      valueListenable: storage.playlistsListenable,
      builder: (context, playlists, _) {
        if (playlists.isEmpty) return const SizedBox.shrink();
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Your Playlists',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3)),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final pl = playlists[index];
                  final thumb = pl.songs.isNotEmpty && pl.songs.first.thumbnails.isNotEmpty
                      ? pl.songs.first.thumbnails.first.url
                      : '';
                  return _PlaylistCard(name: pl.name, thumbnailUrl: thumb);
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── Compact card for MuzoItem in horizontal lists ────────────────────────
class _MuzoCard extends StatelessWidget {
  final MuzoItem item;
  const _MuzoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.first.url : '';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // play via navigator or provider — handled upstream
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: thumb,
                width: 140, height: 140,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 140, height: 140,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.music_note, color: Colors.white38, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600, fontSize: 13)),
            if (item.artists?.isNotEmpty ?? false)
              Text(item.artists!.first.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Card for user Playlists ──────────────────────────────────────────────
class _PlaylistCard extends StatelessWidget {
  final String name;
  final String thumbnailUrl;
  const _PlaylistCard({required this.name, required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    width: 140, height: 140,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(context),
                  )
                : _placeholder(context),
          ),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.queue_music_rounded, color: Colors.white38, size: 40),
    );
  }
}
