import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Plenty of Goldfish',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ProfilePage(),
    );
  }
}

enum Field {
  id, // unique id to separate candidates (the document id)
  name,
  favoriteMusic,
  phValue,
  profilePicture1, // the main profile picture
  profilePicture2,
  profilePicture3,
  profilePicture4,
  lastSeenLatitude,
  lastSeenLongitude
}

class _PictureTile extends StatelessWidget {
  const _PictureTile(this.backgroundColor, this.iconData);

  final Color backgroundColor;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Image.asset('assets/longhorn-cowfish.jpg', fit: BoxFit.cover),
    );
  }
}

// we may decide not to do this part since a close variant is shown in our other talk.
class _ProfilePageState extends State<ProfilePage> {
  File _imageFile;
  DocumentReference _profile;
  bool _editing;
  Map<String, dynamic> _localValues;
  static String defaultPicturePath = 'assets/longhorn-cowfish.jpg';
  Set<String> _nonMatches;

  @override
  void initState() {
    super.initState();
    _profile = Firestore.instance.collection('profiles').document();
    _editing = false;
    _localValues = {};
    _nonMatches = new Set<String>()..add(_profile.documentID);
  }

  getImage() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    await _uploadToStorage(imageFile, Field.profilePicture1); // TODO: not only image 1
    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<Null> _uploadToStorage(File imageFile, Field profileImageLocation) async {
    var random = new Random().nextInt(10000);
    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
    var uploadTask = ref.put(imageFile);
    var downloadUrl = (await uploadTask.future).downloadUrl;
    _updateLocalData(profileImageLocation, downloadUrl);
  }

  void _updateLocalData(Field field, value) {
    setState(() {
      _localValues[field.toString()] = value;
    });
  }

  Future<Null> _updateProfile() async {
    /*if(_imageFile == null) {
      ByteData data = await rootBundle.load(defaultPicturePath);
      _uploadToStorage(new File(defaultPicturePath)); // TODO.
    }*/
    // Get GPS data just before sending.
    Map<String, double> currentLocation =
        await new LocationTools().getLocation();
    _localValues[Field.lastSeenLatitude.toString()] =
        currentLocation['latitude'];
    _localValues[Field.lastSeenLongitude.toString()] =
        currentLocation['longitude'];
    _profile.setData(_localValues, SetOptions.merge);
  }

  Widget _showProfilePicture() {
    Image image = _imageFile == null
        ? new Image.asset(defaultPicturePath)
        : new Image.file(_imageFile);
    if (_editing) {
      return new Stack(
        children: [
          new Container(
            child: image,
            foregroundDecoration: new BoxDecoration(
                color: new Color.fromRGBO(200, 200, 200, 0.5)),
          ),
          new IconButton(
            iconSize: 50.0,
            onPressed: getImage,
            tooltip: 'Pick Image',
            icon: new Icon(Icons.add_a_photo),
          ),
        ],
        alignment: new Alignment(0.0, 0.0),
      );
    } else {
      return image;
    }
  }

  List<Widget> _tiles = const <Widget>[
    const _PictureTile(Colors.green, Icons.widgets),
    const _PictureTile(Colors.lightBlue, Icons.wifi),
    const _PictureTile(Colors.amber, Icons.panorama_wide_angle),
  ];

  Widget _showPics() {
    return GridView.count(
      crossAxisCount: 3,
      children: _tiles,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      padding: EdgeInsets.all(4.0),
    );
  }

  Widget _showData(Field field) {
    String label;
    String defaultValue;
    String currentValue = _localValues[field.toString()];
    IconData iconData;
    switch (field) {
      case Field.name:
        label = 'Name';
        defaultValue = 'Frank';
        iconData = Icons.person;
        break;
      case Field.favoriteMusic:
        label = 'Favorite Music';
        defaultValue = 'Blubstep';
        iconData = Icons.music_note;
        break;
      case Field.phValue:
        label = 'Favorite pH level';
        defaultValue = '5';
        // other options: Icons.colorize, Icons.equalizer, Icons.pool, Icons.tune
        iconData = Icons.beach_access;
        break;
      default:
        break;
    }
    if (_editing) {
      return new TextField(
        decoration: new InputDecoration(labelText: label),
        onChanged: (changed) => _updateLocalData(field, changed),
        controller:
            new TextEditingController(text: currentValue ?? defaultValue),
      );
    } else {
      _localValues[field.toString()] = currentValue ?? defaultValue;
      return new ListTile(
          leading: new Icon(iconData),
          title: new Text(label),
          subtitle: new Text(currentValue ?? defaultValue));
    }
  }

  Future<MatchData> _getMatchData() async {
    // making the call.
    String query = _nonMatches.join('&id=');

    showDialog(
      context: context,
      barrierDismissible: false,
      child: new Dialog(
        child: new Container(
          padding: new EdgeInsets.all(20.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new CircularProgressIndicator(),
              new Text('Off Fishing...'),
            ],
        ),
      ),
      ),
    );
    Map<String, dynamic> response = json
        .decode((await http.get(
                'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=$query'))
            .body)
        .cast<String, dynamic>();
    Navigator.pop(context);


    return new MatchData(
        response[Field.id.toString()],
        response[Field.profilePicture1.toString()],
        response[Field.profilePicture2.toString()],
        response[Field.profilePicture3.toString()],
        response[Field.profilePicture4.toString()],
        response[Field.name.toString()],
        response[Field.favoriteMusic.toString()],
        response[Field.phValue.toString()],
        response[Field.lastSeenLatitude.toString()],
        response[Field.lastSeenLongitude.toString()]);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        floatingActionButton: new IconButton(
          onPressed: () {
            _updateProfile();
            setState(() {
              _editing = !_editing;
            });
          },
          tooltip: _editing ? 'Edit Profile' : 'Save Changes',
          icon: new Icon(_editing ? Icons.check : Icons.edit),
        ),
        // This simplifies the number of nested widgets compared to my
        // CustomScrollView implementatation (see commit
        // 1bf015c1a19808d387ba6f378f1d2b3bab5bf60d) but if you rotate the
        // screen it gets (understandably) mad at you for overflowing. We can
        // add back in the CustomScrollView if we decide we want that.
        body: new Column(
          children: <Widget>[
            new Card(child: new Image.asset('assets/longhorn-cowfish.jpg')),
            new GridView.count(crossAxisCount: 3, shrinkWrap: true, children: _tiles),
            _showData(Field.name),
            _showData(Field.favoriteMusic),
            _showData(Field.phValue),
            new Center(
                child: new RaisedButton.icon(
                    icon: new Icon(Icons.favorite),
                    onPressed: () async {
                      var matchData = await _getMatchData();
                      Navigator.of(context).push(new MaterialPageRoute<Null>(
                          builder: (BuildContext context) {
                        return new MatchPage(matchData);
                      }));
                    },
                    color: Colors.blue,
                    splashColor: Colors.lightBlueAccent,
                    label: new Text("Find your fish!"))),
          ],
        ));
  }
}

class ProfilePage extends StatefulWidget {
  _ProfilePageState createState() => new _ProfilePageState();
}

typedef void LocationCallback(Map<String, double> location);

class LocationTools {
  final Location location = new Location();

  Future<Map<String, double>> getLocation() {
    return location.getLocation;
  }

  void initListener(LocationCallback callback) {
    location.onLocationChanged.listen((Map<String, double> currentLocation) {
      callback(currentLocation);
    });
  }
}

class AudioTools {
  final AudioPlayer _audioPlayer;

  AudioTools() : _audioPlayer = new AudioPlayer();

  void initAudioLoop(String audioFile) {
    // restart audio if it has finished
    _audioPlayer.setCompletionHandler(() {
      _audioPlayer.play(audioFile);
    });
    // restart audio if it has been playing for at least 3 seconds
    _audioPlayer.setPositionHandler((Duration d) {
      if (d.inSeconds > 3) {
        playNewAudio(audioFile);
      }
    });
    _audioPlayer.play(audioFile);
  }

  void playNewAudio(String audioFile) {
    _audioPlayer.stop().then((result) {
      _audioPlayer.play(audioFile);
    });
  }

  void stopAudio() {
    _audioPlayer.setCompletionHandler(() {});
    _audioPlayer.setPositionHandler((Duration d) {});
    _audioPlayer.stop();
  }
}

class MatchPage extends StatelessWidget {
  final MatchData matchData;

  MatchPage(this.matchData);

  @override
  Widget build(BuildContext context) {
    // TODO: Nonmatch case.
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("You've caught a fish!"),
        ),
        body: new Column(
          children: [
            //new Image.asset(matchData.profilePicture), TODO: re-enable
            new Text("Name: ${matchData.name}"),
            new Text("Favorite Music: ${matchData.favoriteMusic}"),
            new Text("Favorite pH: ${matchData.favoritePh}"),
            new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new FlatButton(
                      onPressed: () {
                        //_nonMatches.add(matchData.id), TODO
                        Navigator.pop(context);
                      },
                      child: new Text("Reject")),
                  new FlatButton(
                      onPressed: () {
                        Navigator.of(context).push(new MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                          return new FinderPage(matchData.targetLatitude,
                              matchData.targetLongitude);
                        }));
                      },
                      child: new Text("Accept")),
                ]),
          ],
        ));
  }
}

class FinderPage extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final AudioTools audioTools = new AudioTools();

  FinderPage(this.targetLatitude, this.targetLongitude);

  @override
  _FinderPageState createState() => new _FinderPageState(audioTools);
}

class _FinderPageState extends State<FinderPage> {
  LocationTools locationTools;
  AudioTools audioTools;
  double latitude = 0.0;
  double longitude = 0.0;
  double accuracy = 0.0;
  final String searchingAudio =
      'https://freesound.org/data/previews/28/28693_98464-lq.mp3';
  final String foundAudio =
      'https://freesound.org/data/previews/397/397354_4284968-lq.mp3';

  _FinderPageState(this.audioTools) {
    locationTools = new LocationTools();
    locationTools.getLocation().then((Map<String, double> currentLocation) {
      _updateLocation(currentLocation);
    });
    locationTools.initListener(_updateLocation);
    audioTools.initAudioLoop(searchingAudio);
  }

  void _updateLocation(Map<String, double> currentLocation) {
    setState(() {
      latitude = currentLocation["latitude"];
      longitude = currentLocation["longitude"];
      accuracy = currentLocation["accuracy"];
    });
  }

  double _getLocationDiff() {
    int milesBetweenLines = 69;
    int feetInMile = 5280;
    int desiredFeetRange = 15;
    double multiplier = 2 * milesBetweenLines * feetInMile / desiredFeetRange;
    double latitudeDiff = (latitude - widget.targetLatitude).abs() * multiplier;
    double longitudeDiff =
        (longitude - widget.targetLongitude).abs() * multiplier;
    if (latitudeDiff > 1) {
      latitudeDiff = 1.0;
    }
    if (longitudeDiff > 1) {
      longitudeDiff = 1.0;
    }
    double diff = (latitudeDiff + longitudeDiff) / 2;
    if (diff < 0.1) {
      audioTools.stopAudio();
      audioTools.playNewAudio(foundAudio);
    }
    return diff;
  }

  Color _colorFromLocationDiff() {
    return Color.lerp(Colors.red, Colors.blue, _getLocationDiff());
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: _colorFromLocationDiff(),
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new FlatButton.icon(
              icon: new Icon(Icons.cancel, size: 32.0),
              label: new Text(
                "Cancel",
                textScaleFactor: 2.0,
              ),
              onPressed: () {
                audioTools.stopAudio();
                Navigator.pop(context);
              },
            ),
            new Image.asset('assets/location_ping.gif'),
          ]),
    );
  }
}

class MatchData {
  String id;
  String profilePicture1, profilePicture2, profilePicture3, profilePicture4; //TODO: Probably switch this to a File
  String name;
  String favoriteMusic;
  String favoritePh;
  double targetLatitude;
  double targetLongitude;

  MatchData(this.id, this.profilePicture1, this.profilePicture2,
      this.profilePicture3, this.profilePicture4, this.name, this.favoriteMusic,
      this.favoritePh, this.targetLatitude, this.targetLongitude);

  // TODO: Populate this via Firebase
  MatchData.generate() {
    profilePicture = 'assets/koi.jpg';
    name = 'Finnegan';
    favoriteMusic = 'Goldies';
    favoritePh = '7';
    targetLatitude = 37.785844;
    targetLongitude = -122.406427;
  }
}
