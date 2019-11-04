import 'dart:io';
import 'package:buy_records/secrets/Secret.dart';
import 'package:buy_records/secrets/SecretLoader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:buy_records/AlbumOptions.dart';
import 'package:buy_records/types/Album.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spotify/spotify_io.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buy Records! Nerd.',
      theme: ThemeData(primarySwatch: Colors.green),
      home: MyHomePage(title: 'Buy Records! Nerd.'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Finals - think of these like js `const` (?)
  final albumFieldFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final artistController = TextEditingController();
  final albumController = TextEditingController();
  final appBackgroundColor = Color.fromRGBO(25, 20, 20, 1);
  final pageController = PageController(initialPage: 0, keepPage: false);

  // Shit that's actually maniuplated for display
  List<DiscogsAlbum> imageOpts = <DiscogsAlbum>[];
  List<DiscogsAlbum> savedRecords = <DiscogsAlbum>[];

  // Shit regarding saving data locally
  // saved in a `.json` file and en/de-coded for use
  File jsonFile;
  Directory dir;
  String fileName = 'savedRecords.json';
  bool fileExists = false;
  var fileContents;

  // Shhhh
  String apiKey = '';
  String spotifyClientId = '';
  String spotifyClientSecret = '';

  @override
  void initState() {
    super.initState();

    SecretLoader(secretPath: "secrets.json").load().then((Secret x) {
      setState(() {
        apiKey = x.apiKey;
        spotifyClientId = x.spotifyClientId;
        spotifyClientSecret = x.spotifyClientSecret;
      });
      return;
    });

    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      jsonFile = new File(dir.path + '/' + fileName);
      fileExists = jsonFile.existsSync();
      if (fileExists) {
        String jsonFileString = jsonFile.readAsStringSync();
        if (jsonFileString.length == 0) {
          return;
        }

        List<DiscogsAlbum> retypedRecords = getSavedRecordsFromJson();

        this.setState(() {
          fileContents = json.decode(jsonFileString);
          savedRecords = retypedRecords;
        });
      }
    });
  }

  List<DiscogsAlbum> getSavedRecordsFromJson() {
    /**
     * Language is reallly weird.. First, encoding when using magic key
     * ie, `json.encode({[savedRecordsKey]: [album]})`
     * does NOT work - it just won't encode. You can use it when decoing though
     * ie, `json.decode(file.asString())[savedRecordsKey])`
     * second, I'd like to use `.map().toList()` here but that wasn't working
     * so use forEach and `.add()` new records that way.
     */
    Map<String, dynamic> decodedRecordsObject =
        json.decode(jsonFile.readAsStringSync());
    // If you plan on pushing, you need it initialize it with an empty array
    // for some reason... what's the point of typing if I have to initialize it anyway
    // (this pattern is repeated elsewhere as well.)
    List<DiscogsAlbum> retypedRecords = <DiscogsAlbum>[];

    if (decodedRecordsObject.containsKey('savedRecords')) {
      var decodedRecords = decodedRecordsObject['savedRecords'];

      decodedRecords.forEach((record) => {
            retypedRecords.add(DiscogsAlbum(
              url: record['url'],
              artist: record['artist'],
              album: record['album'],
              spotifyUrl: record['spotifyUrl'],
              title: record['title'],
              uuid: record['uuid'],
            ))
          });
    }

    return retypedRecords;
  }

  void createFile(DiscogsAlbum album, Directory dir, String fileName) {
    File file = new File(dir.path + '/' + fileName);
    file.createSync();
    var fileContentsString = json.encode({
      'savedRecords': [album]
    });
    file.writeAsStringSync(fileContentsString);
    this.setState(() => {
          fileExists = true,
          fileContents = json.decode(fileContentsString),
          jsonFile = file
        });
  }

  void writeToFile(DiscogsAlbum album) {
    if (fileExists) {
      var savedJsonContentsString = jsonFile.readAsStringSync();
      var jsonFileContent;

      if (savedJsonContentsString.length == 0) {
        jsonFileContent = {
          'savedRecords': [
            DiscogsAlbum(
              url: album.url,
              artist: album.artist,
              album: album.album,
              title: album.title,
              spotifyUrl: album.spotifyUrl,
              uuid: album.uuid,
            )
          ]
        };
      } else {
        jsonFileContent = json.decode(savedJsonContentsString);
        jsonFileContent['savedRecords'].add(album);
      }

      jsonFile.writeAsStringSync(json.encode(jsonFileContent));
    } else {
      createFile(album, dir, fileName);
    }
    this.setState(
        () => {fileContents = json.decode(jsonFile.readAsStringSync())});
  }

  void removeRecord(DiscogsAlbum album) {
    if (!fileExists) {
      return;
    }

    List<DiscogsAlbum> recordListFromJson = getSavedRecordsFromJson();
    recordListFromJson.removeWhere((a) => a.uuid == album.uuid);
    var jsonString = json.encode({'savedRecords': recordListFromJson});
    jsonFile.writeAsStringSync(jsonString);
    setState(() {
      fileContents = json.decode(jsonString);
      savedRecords = recordListFromJson;
    });

    Fluttertoast.showToast(
        msg: 'Album Removed!',
        fontSize: 24,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white);
  }

  void saveRecord(DiscogsAlbum album) async {
    var credentials =
        new SpotifyApiCredentials(spotifyClientId, spotifyClientSecret);
    var spotify = new SpotifyApi(credentials);
    List<Page<Object>> search =
        await spotify.search.get(Uri.encodeFull(album.title)).first(10);
    List<AlbumSimple> sAlbums = <AlbumSimple>[];
    search.forEach((Page<Object> page) {
      page.items.forEach((Object item) {
        if (item is AlbumSimple) {
          sAlbums.add(item);
        }
      });
    });

    print(sAlbums.length > 0 && sAlbums.first.externalUrls != null
        ? sAlbums.first.externalUrls.spotify
        : '');

    DiscogsAlbum albumWithId = DiscogsAlbum(
      url: album.url,
      artist: album.artist,
      album: album.album,
      title: album.title,
      spotifyUrl: sAlbums.length > 0 && sAlbums.first.externalUrls != null
          ? sAlbums.first.externalUrls.spotify
          : '',
      uuid: new Uuid().v1(),
    );

    setState(() {
      savedRecords.add(albumWithId);
    });

    writeToFile(albumWithId);

    Fluttertoast.showToast(
        msg: 'Album Saved!',
        fontSize: 24,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white);
  }

  void openSpotify(DiscogsAlbum test) async {
    String url = test.spotifyUrl;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: 'No Spotify URL',
        fontSize: 24,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _performSearch(String query) async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    final String baseUrl = "https://api.discogs.com";
    final String type = albumController.text.isNotEmpty ? 'release' : 'artist';
    final String url =
        "$baseUrl/database/search?type=$type&q=$query&token=$apiKey";
    final response = await http.get(url, headers: {"Accept": "text/plain"});
    Map<String, dynamic> list = json.decode(response.body);

    if (!list.containsKey("results")) {
      return;
    }

    List<DiscogsAlbum> newImageOpts = <DiscogsAlbum>[];
    var i = 0;
    while (i < list["results"].length) {
      newImageOpts.add(DiscogsAlbum(
        url: list["results"][i]["thumb"].isNotEmpty
            ? list["results"][i]["thumb"]
            : 'http://placehold.it/150x150',
        artist: artistController.text,
        album: albumController.text,
        title: list["results"][i]["title"],
      ));
      i++;
    }

    setState(() {
      imageOpts = newImageOpts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        backgroundColor: Colors.black,
        body: TabBarView(
          children: <Widget>[
            Scaffold(
              backgroundColor: appBackgroundColor,
              body: Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 16, left: 16, right: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            cursorColor: Colors.green,
                            style: TextStyle(color: Colors.white),
                            controller: artistController,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (v) {
                              FocusScope.of(context)
                                  .requestFocus(albumFieldFocusNode);
                            },
                            decoration: InputDecoration(
                                hintText: 'Artist Name',
                                hintStyle: TextStyle(color: Colors.grey)),
                            validator: (String text) {
                              if (text.isEmpty) {
                                return 'Please enter artist name';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            onFieldSubmitted: (String album) {
                              String query = artistController.text;
                              query += album.isNotEmpty ? " - $album" : '';
                              _performSearch(Uri.encodeFull(query));
                            },
                            focusNode: albumFieldFocusNode,
                            cursorColor: Colors.green,
                            style: TextStyle(color: Colors.white),
                            controller: albumController,
                            decoration: InputDecoration(
                                hintText: 'Album Name',
                                hintStyle: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (imageOpts.length > 0)
                    AlbumOptions(
                      albumOptions: imageOpts,
                      onTap: saveRecord,
                    ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  String query = artistController.text;
                  query += albumController.text.isNotEmpty
                      ? ' - ${albumController.text}'
                      : '';
                  _performSearch(Uri.encodeFull(query));
                },
                tooltip: 'Search for albums',
                child: Icon(Icons.search),
              ),
            ),
            Scaffold(
              backgroundColor: appBackgroundColor,
              body: Column(
                children: <Widget>[
                  AlbumOptions(
                    albumOptions: savedRecords,
                    onLongPress: removeRecord,
                    onTap: openSpotify,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.graphic_eq),
              ),
              Tab(
                icon: Icon(Icons.album),
              ),
            ],
            labelColor: Colors.green,
            unselectedLabelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: Colors.green),
      ),
    );
  }
}
