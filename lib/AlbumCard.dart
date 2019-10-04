import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatefulWidget {
  AlbumCard({Key key, @required this.albumObj, this.onTap, this.onLongPress})
      : super(key: key);

  final DiscogsAlbum albumObj;
  final void Function(DiscogsAlbum album) onTap;
  final void Function(DiscogsAlbum album) onLongPress;

  @override
  _AlbumCardState createState() => new _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
            onLongPress: () {
              if (widget.onLongPress != null) {
                widget.onLongPress(widget.albumObj);
              }
            },
            onTap: () {
              if (widget.onTap != null) {
                widget.onTap(widget.albumObj);
              }
            },
            child: Column(
              children: <Widget>[
                Image.network(widget.albumObj.url),
                Text.rich(
                  TextSpan(
                    text: widget.albumObj.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            )));
  }
}
