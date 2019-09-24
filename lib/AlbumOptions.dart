import 'AlbumCard.dart';
import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';

class AlbumOptions extends StatefulWidget {
  AlbumOptions(
      {Key key, @required this.albumOptions, this.onTap, this.onLongPress})
      : super(key: key);
  final List<Album> albumOptions;
  final void Function(Album album) onTap;
  final void Function(Album album) onLongPress;

  @override
  _AlbumOptionsState createState() => new _AlbumOptionsState();
}

class _AlbumOptionsState extends State<AlbumOptions> {
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 16.0),
        children: widget.albumOptions
            .map((Album album) => AlbumCard(
                  albumObj: album,
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                ))
            .toList(),
      ),
    );
  }
}
