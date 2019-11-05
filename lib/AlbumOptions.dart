import 'AlbumCard.dart';
import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';

class AlbumOptions extends StatefulWidget {
  AlbumOptions({
    Key key,
    @required this.albumOptions,
    @required this.showImages,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);
  final List<DiscogsAlbum> albumOptions;
  final void Function(DiscogsAlbum album) onTap;
  final void Function(DiscogsAlbum album) onLongPress;
  final bool showImages;

  @override
  _AlbumOptionsState createState() => new _AlbumOptionsState();
}

class _AlbumOptionsState extends State<AlbumOptions> {
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        children: widget.albumOptions
            .map((DiscogsAlbum album) => AlbumCard(
                  albumObj: album,
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  showImages: widget.showImages,
                ))
            .toList(),
      ),
    );
  }
}
