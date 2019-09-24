import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatefulWidget {
  AlbumCard({Key key, this.albumObj, this.onTapAction}) : super(key: key);
  final Album albumObj;
  final void Function(Album album) onTapAction;

  @override
  _AlbumCardState createState() => new _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
            onTap: () {
              widget.onTapAction(widget.albumObj);
            },
            child: Column(
              children: <Widget>[
                Image.network(widget.albumObj.url),
                Text.rich(TextSpan(
                    text: widget.albumObj.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)))
              ],
            )));
  }
}
