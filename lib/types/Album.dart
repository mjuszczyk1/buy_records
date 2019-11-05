class DiscogsAlbum {
  String url;
  String artist;
  String album;
  String title;
  String spotifyUrl;
  dynamic uuid;

  // DiscogsAlbum(this.url, this.artist, this.album, this.title, this.spotifyUrl,
  //     [this.uuid]);
  DiscogsAlbum({
    this.album,
    this.artist,
    this.title,
    this.url,
    this.spotifyUrl = '',
    this.uuid = '',
  });

  DiscogsAlbum.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        artist = json['artist'],
        album = json['album'],
        title = json['title'],
        spotifyUrl = json['spotifyUrl'],
        uuid = json['uuid'];

  Map<String, dynamic> toJson() => {
        'url': url,
        'artist': artist,
        'album': album,
        'title': title,
        'spotifyUrl': spotifyUrl,
        'uuid': uuid
      };
}
