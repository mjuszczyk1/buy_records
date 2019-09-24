class Album {
  String url;
  String artist;
  String album;
  String title;
  dynamic uuid;

  Album(this.url, this.artist, this.album, this.title, [this.uuid]);

  Album.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        artist = json['artist'],
        album = json['album'],
        title = json['title'],
        uuid = json['uuid'];

  Map<String, dynamic> toJson() => {
        'url': url,
        'artist': artist,
        'album': album,
        'title': title,
        'uuid': uuid
      };
}
