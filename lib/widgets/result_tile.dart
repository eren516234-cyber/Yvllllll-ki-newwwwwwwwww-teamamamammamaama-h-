import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'package:yvl/models/muzo_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/screens/artist_screen.dart';
import 'package:yvl/screens/playlist_screen.dart';
import 'package:yvl/screens/channel_screen.dart';
import 'package:yvl/screens/album_screen.dart';
import 'package:yvl/widgets/song_options_menu.dart';
import 'package:yvl/utils/page_routes.dart';
import 'package:yvl/services/navigator_key.dart';
import 'package:yvl/providers/search_provider.dart';

class ResultTile extends ConsumerStatefulWidget {
  final MuzoItem result;
  final bool compact;
  final bool fromHistory;

  const ResultTile({
    super.key,
    required this.result,
    this.compact = false,
    this.fromHistory = false,
  });

  @override
  ConsumerState<ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends ConsumerState<ResultTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  void _handleTap() {
    HapticFeedback.lightImpact();
    final result = widget.result;
    final type = result.resultType.toLowerCase();
    final bId = result.browseId;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (type == 'artist' && bId != null && bId.isNotEmpty) {
      nav.push(SlidePageRoute(
        page: ArtistScreen(
          browseId: bId,
          artistName: result.title,
          thumbnailUrl: result.thumbnails.lastOrNull?.url,
        ),
      ));
    } else if (type == 'playlist' && bId != null && bId.isNotEmpty) {
      nav.push(SlidePageRoute(
        page: PlaylistScreen(
          playlistId: bId,
          title: result.title,
          thumbnailUrl: result.thumbnails.lastOrNull?.url,
        ),
      ));
    } else if (type == 'album' && bId != null && bId.isNotEmpty) {
      nav.push(SlidePageRoute(
        page: AlbumScreen(
          albumId: bId,
          albumName: result.title,
          thumbnailUrl: result.thumbnails.lastOrNull?.url,
        ),
      ));
    } else if (type == 'channel' && bId != null && bId.isNotEmpty) {
      nav.push(SlidePageRoute(
        page: ChannelScreen(
          channelId: bId,
          title: result.title,
          thumbnailUrl: result.thumbnails.lastOrNull?.url,
          subscriberCount: result.subscriberCount,
          videoCount: result.videoCount,
          description: result.description,
        ),
      ));
    } else if (result.videoId != null) {
      ref.read(audioHandlerProvider).playVideo(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    String imageUrl = '';
    if (result.thumbnails.isNotEmpty) {
      imageUrl = result.thumbnails.last.url;
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        child: Padding(
          padding: widget.compact
              ? const EdgeInsets.symmetric(horizontal: 0, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  final isVideo = result.resultType == 'video';
                  final defaultWidth = isVideo ? 100.0 : 56.0;
                  const height = 56.0;
                  return Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: height,
                              fit: BoxFit.fitHeight,
                              placeholder: (context, url) => Container(
                                height: height,
                                width: defaultWidth,
                                color: Colors.grey[900],
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: height,
                                width: defaultWidth,
                                color: Colors.grey[900],
                                child: const Icon(
                                  FluentIcons.error_circle_24_regular,
                                  size: 20,
                                ),
                              ),
                            )
                          : Container(
                              height: height,
                              width: defaultWidth,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              child: Icon(
                                FluentIcons.music_note_2_24_regular,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      () {
                        String subtitle = result.displayArtist;
                        if (result.resultType == 'artist') {
                          subtitle = 'Artist';
                        } else if (result.resultType == 'playlist') {
                          subtitle = 'Playlist';
                        }
                        if (result.duration != null) {
                          if (subtitle.isNotEmpty && subtitle != 'Unknown') {
                            subtitle += ' • ';
                          }
                          subtitle += result.duration!;
                        }
                        if (result.views != null) {
                          if (subtitle.isNotEmpty && subtitle != 'Unknown') {
                            subtitle += ' • ';
                          }
                          subtitle += '${result.views} views';
                        }
                        return subtitle == 'Unknown' && result.duration == null
                            ? ''
                            : subtitle;
                      }(),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) {
                  if (result.videoId == null) return const SizedBox.shrink();
                  final storage = ref.read(storageServiceProvider);
                  return ValueListenableBuilder<List<MuzoItem>>(
                    valueListenable: storage.favoritesListenable,
                    builder: (context, favorites, _) {
                      return IconButton(
                        icon: Icon(
                          FluentIcons.more_vertical_24_regular,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          SongOptionsMenu.show(
                            ref,
                            result,
                            fromHistory: widget.fromHistory,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
