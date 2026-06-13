import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/screens/artist_screen.dart';
import 'package:yvl/screens/playlist_screen.dart';
import 'package:yvl/screens/album_screen.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/screens/playlist_details_screen.dart';
import 'package:yvl/services/ytm_home.dart';
import 'package:yvl/utils/page_routes.dart';

class HomeItemWidget extends ConsumerWidget {
  final HomeItem item;
  const HomeItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: item.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(FluentIcons.music_note_2_24_filled,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(FluentIcons.music_note_2_24_filled,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();

    if (item.videoId != null) {
      final muzoResult = MuzoItem(
        title: item.title,
        thumbnails: [
          if (item.thumbnailUrl != null)
            MuzoThumbnail(url: item.thumbnailUrl!, width: 500, height: 500),
        ],
        resultType: item.type == 'video_types' ? 'video' : 'song',
        isExplicit: false,
        videoId: item.videoId,
        artists: item.subtitle != null ? [MuzoArtist(name: item.subtitle!, id: null)] : null,
      );
      ref.read(audioHandlerProvider).playVideo(muzoResult);
    } else if (item.type == 'album' && item.browseId != null) {
      Navigator.push(context, SlidePageRoute(
        page: AlbumScreen(albumId: item.browseId!, albumName: item.title, thumbnailUrl: item.thumbnailUrl),
      ));
    } else if (item.playlistId != null || item.type == 'playlist') {
      final idToUse = item.playlistId ?? item.browseId;
      final storage = ref.read(storageServiceProvider);
      final localPlaylists = storage.getPlaylistNames();

      if (localPlaylists.contains(idToUse) || localPlaylists.contains(item.title)) {
        Navigator.push(context, SlidePageRoute(
          page: PlaylistDetailsScreen(
            playlistName: localPlaylists.contains(idToUse) ? idToUse! : item.title),
        ));
      } else if (idToUse != null) {
        Navigator.push(context, SlidePageRoute(
          page: PlaylistScreen(playlistId: idToUse, title: item.title, thumbnailUrl: item.thumbnailUrl),
        ));
      }
    } else if (item.browseId != null &&
        (item.type == 'artist' || item.browseId!.startsWith('UC'))) {
      Navigator.push(context, SlidePageRoute(
        page: ArtistScreen(browseId: item.browseId!, artistName: item.title, thumbnailUrl: item.thumbnailUrl),
      ));
    }
  }
}
