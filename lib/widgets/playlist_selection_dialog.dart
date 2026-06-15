import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yvl/models/muzo_item.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/widgets/glass_snackbar.dart';
import 'package:yvl/widgets/app_alert_dialog.dart';

class PlaylistSelectionDialog extends ConsumerStatefulWidget {
  final MuzoItem song;

  const PlaylistSelectionDialog({super.key, required this.song});

  @override
  ConsumerState<PlaylistSelectionDialog> createState() =>
      _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState
    extends ConsumerState<PlaylistSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final playlists = storage.getPlaylistNames();

    return AppAlertDialog(
      title: 'Add to Playlist',
      content: SizedBox(
        width: double.maxFinite,
        child: playlists.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No playlists created yet.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              )
            : Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SizedBox(
                    height:
                        playlists.length * 56.0 >
                            MediaQuery.of(context).size.height * 0.5
                        ? MediaQuery.of(context).size.height * 0.5
                        : playlists.length * 56.0,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final name = playlists[index];
                        return ListTile(
                          leading: Icon(
                            FluentIcons.music_note_2_24_regular,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            storage.addToPlaylist(name, widget.song);
                            Navigator.pop(context);
                            showGlassSnackBar(context, 'Added to $name');
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _showCreatePlaylistDialog(context, storage);
          },
          child: Text(
            'New Playlist',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, StorageService storage) {
    final controller = TextEditingController();
    showAppAlertDialog(
      context: context,
      title: 'Create Playlist',
      content: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: CupertinoTextField(
          controller: controller,
          placeholder: 'Playlist Name',
          placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
          style: const TextStyle(color: CupertinoColors.white),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context);
              // Await createPlaylist so the local state is updated before
              // addToPlaylist checks for the playlist's existence.
              await storage.createPlaylist(name);
              await storage.addToPlaylist(name, widget.song);
              if (context.mounted) {
                showGlassSnackBar(context, 'Added to $name');
              }
            }
          },
          child: Text(
            'Create',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
