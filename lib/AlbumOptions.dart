import 'AlbumCard.dart';
import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';

class AlbumOptions extends StatefulWidget {
  AlbumOptions({Key key, @required this.albumOptions, this.onTap})
      : super(key: key);
  final List<Album> albumOptions;
  final void Function(Album album) onTap;

  @override
  _AlbumOptionsState createState() => new _AlbumOptionsState();
}

class _AlbumOptionsState extends State<AlbumOptions> {
  Widget build(BuildContext context) {
    return ListView(
      children: widget.albumOptions
          .map((Album album) => AlbumCard(albumObj: album, onTap: widget.onTap))
          .toList(),
    );
  }
}
