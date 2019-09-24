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
import 'AlbumCard.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  final _formKey = GlobalKey<FormState>();
  final artistController = TextEditingController();
  final albumController = TextEditingController();
  final appBackgroundColor = Color.fromRGBO(25, 20, 20, 1);
  String apiKey = '';
  final pageController = PageController(initialPage: 0, keepPage: false);

  // Shit that's actually maniuplated for display
  List<Album> imageOpts = <Album>[];
  List<Album> savedRecords = <Album>[];

  // Shit regarding saving data locally
  // saved in a `.json` file and en/de-coded for use
  File jsonFile;
  Directory dir;
  String fileName = 'savedRecords.json';
  bool fileExists = false;
  var fileContents;

  @override
  void initState() {
    super.initState();

    SecretLoader(secretPath: "secrets.json").load().then((Secret x) {
      setState(() {
        apiKey = x.apiKey;
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

        List<Album> retypedRecords = getSavedRecordsFromJson();

        this.setState(() {
          fileContents = json.decode(jsonFileString);
          savedRecords = retypedRecords;
        });
      }
    });
  }

  List<Album> getSavedRecordsFromJson() {
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
    List<Album> retypedRecords = <Album>[];

    if (decodedRecordsObject.containsKey('savedRecords')) {
      var decodedRecords = decodedRecordsObject['savedRecords'];

      decodedRecords.forEach((record) => {
            retypedRecords.add(new Album(record['url'], record['artist'],
                record['album'], record['title'], record['uuid']))
          });
    }

    return retypedRecords;
  }

  void createFile(Album album, Directory dir, String fileName) {
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

  void writeToFile(Album album) {
    if (fileExists) {
      var savedJsonContentsString = jsonFile.readAsStringSync();
      var jsonFileContent;

      if (savedJsonContentsString.length == 0) {
        jsonFileContent = {
          'savedRecords': [
            new Album(
                album.url, album.artist, album.album, album.title, album.uuid)
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

  void removeRecord(Album album) {
    if (!fileExists) {
      return;
    }

    List<Album> recordListFromJson = getSavedRecordsFromJson();
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

  void saveRecord(Album album) {
    Album albumWithId = new Album(
        album.url, album.artist, album.album, album.title, new Uuid().v1());
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

  void _performSearch() async {
    if (artistController.text.length == 0) {
      return;
    }
    String baseUrl = "https://api.discogs.com";
    String query =
        Uri.encodeFull("${artistController.text} - ${albumController.text}");
    String url = "$baseUrl/database/search?type=release&q=$query&token=$apiKey";
    final response = await http.get(url, headers: {"Accept": "text/plain"});
    var list = json.decode(response.body);

    List<Album> newImageOpts = <Album>[];
    var i = 0;
    while (i < 10 || i > list["results"].length - 1) {
      newImageOpts.add(Album(list["results"][i]["thumb"], artistController.text,
          albumController.text, list["results"][i]["title"]));
      i++;
    }

    setState(() {
      imageOpts = newImageOpts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          backgroundColor: appBackgroundColor,
          body: Column(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              cursorColor: Colors.green,
                              style: TextStyle(color: Colors.white),
                              controller: artistController,
                              decoration: InputDecoration(
                                  hintText: 'Artist Name',
                                  hintStyle: TextStyle(color: Colors.grey)),
                              validator: (text) {
                                if (text.isEmpty) {
                                  return 'Please enter artist name';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              cursorColor: Colors.green,
                              style: TextStyle(color: Colors.white),
                              controller: albumController,
                              decoration: InputDecoration(
                                  hintText: 'Album Name',
                                  hintStyle: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              if (imageOpts.length > 0)
                Expanded(
                    child: AlbumOptions(
                        albumOptions: imageOpts, onTapAction: saveRecord))
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _performSearch,
            tooltip: 'Search for albums',
            child: Icon(Icons.add),
          ),
        ),
        Scaffold(
          appBar: AppBar(
            title: Text('Saved Records'),
          ),
          backgroundColor: appBackgroundColor,
          body: new ListView(
            padding: const EdgeInsets.all(16),
            children: savedRecords
                .map((album) => AlbumCard(
                      albumObj: album,
                      onTapAction: removeRecord,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
