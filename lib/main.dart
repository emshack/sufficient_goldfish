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

import 'utils.dart';

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

// we may decide not to do this part since a close variant is shown in our other talk.
class _ProfilePageState extends State<ProfilePage> {
  DocumentReference _profile;
  bool _editing;
  Map<String, dynamic> _localValues;
  Set<String> _nonMatches;

  @override
  void initState() {
    super.initState();
    _profile = Firestore.instance.collection('profiles').document();
    _editing = false;
    _localValues = {};
    _nonMatches = new Set<String>()..add(_profile.documentID);
  }

  void _updateLocalData(Field field, value) {
    setState(() {
      _localValues[field.toString()] = value;
    });
  }

  Future<Null> _updateProfile() async {
    // Get GPS data just before sending.
    Map<String, double> currentLocation =
        await new LocationTools().getLocation();
    _localValues[Field.lastSeenLatitude.toString()] =
        currentLocation['latitude'];
    _localValues[Field.lastSeenLongitude.toString()] =
        currentLocation['longitude'];
    _profile.setData(_localValues, SetOptions.merge);
  }

  List<Widget> _profilePictures() {
    var tiles = <Widget>[
      new ProfilePicture(_editing, Field.profilePicture2, _updateLocalData),
      new ProfilePicture(_editing, Field.profilePicture3, _updateLocalData),
      new ProfilePicture(_editing, Field.profilePicture4, _updateLocalData),
    ];
    return <Widget>[
                new SliverList(
                 delegate: SliverChildListDelegate([new ProfilePicture(
                               _editing, Field.profilePicture1, _updateLocalData)]),
                ),
                new SliverGrid(gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4.0),
                    delegate: new SliverChildListDelegate(tiles)),];
  }

  Widget _showData(Field field) {
    String label;
    String defaultValue;
    IconData iconData;
    switch (field) {
      case Field.name:
        label = 'Name';
        defaultValue = 'e.g. Frank';
        iconData = Icons.person;
        break;
      case Field.favoriteMusic:
        label = 'Favorite Music';
        defaultValue = 'e.g. Blubstep';
        iconData = Icons.music_note;
        break;
      case Field.phValue:
        label = 'Favorite pH level';
        defaultValue = 'e.g. 5';
        // other options: Icons.colorize, Icons.equalizer, Icons.pool, Icons.tune
        iconData = Icons.beach_access;
        break;
      default:
        break;
    }
    return new TextField(
      decoration: new InputDecoration(labelText: label, icon: new Icon(iconData), hintText: defaultValue),
      onChanged: (changed) => _updateLocalData(field, changed),
      enabled: _editing,
    );
  }

  Future<MatchData> _getMatchData() async {
    // making the call.
    String query = _nonMatches.join('&id=');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => new Dialog(
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
        Uri.parse(response[Field.profilePicture1.toString()]),
        Uri.parse(response[Field.profilePicture2.toString()]),
        Uri.parse(response[Field.profilePicture3.toString()]),
        Uri.parse(response[Field.profilePicture4.toString()]),
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
        body: CustomScrollView(slivers: _profilePictures()..add(
          new SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                _showData(Field.name),
                _showData(Field.favoriteMusic),
                _showData(Field.phValue),
                new Center(
                    child: new RaisedButton.icon(
                        icon: new Icon(Icons.favorite),
                        onPressed: () async {
                          var matchData = await _getMatchData();
                          Navigator.of(context).push(
                              new MaterialPageRoute<Null>(
                                  builder: (BuildContext context) {
                            return new MatchPage(matchData);
                          }));
                        },
                        color: Colors.blue,
                        splashColor: Colors.lightBlueAccent,
                        label: new Text("Find your fish!"))),
              ],
            ),
          ))
        ));
  }
}

class ProfilePicture extends StatefulWidget {
  final bool editing;
  final Uri _imageFile;
  final Field imagePosition;
  final Function updateLocalValuesCallback;

  ProfilePicture(this.editing, this.imagePosition, this.updateLocalValuesCallback,
      [this._imageFile]);

  @override
  State<ProfilePicture> createState() => new _ProfilePictureState(_imageFile);
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uri _imageFile;
  _ProfilePictureState(this._imageFile);

  @override
  Widget build(BuildContext context) {
    var image = new Card(child: _imageFile == null
        ? new Image.asset('assets/fish-silhouette.png')
        : (_imageFile.toString().startsWith('http') ? new Image.network(_imageFile.toString(), fit: BoxFit.cover) : new Image.file(new File.fromUri(_imageFile), fit: BoxFit.cover)));
    if (widget.editing) {
      return new Stack(
        children: [
          new Container(
            child: image,
            foregroundDecoration: new BoxDecoration(
                color: new Color.fromRGBO(200, 200, 200, 0.5)),
          ),
          new IconButton(
            iconSize: 50.0,
            onPressed: _getImage,
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

  _getImage() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = imageFile.uri;
    });
    await _uploadToStorage(imageFile);
  }

  Future<Null> _uploadToStorage(File imageFile) async {
    var random = new Random().nextInt(10000);
    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
    var uploadTask = ref.put(imageFile);
    var downloadUrl = (await uploadTask.future).downloadUrl;
    widget.updateLocalValuesCallback(widget.imagePosition, downloadUrl.toString());
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
          title: new Text("Great catch!"),
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
  Uri profilePicture1,
      profilePicture2,
      profilePicture3,
      profilePicture4;
  String name;
  String favoriteMusic;
  String favoritePh;
  double targetLatitude;
  double targetLongitude;

  MatchData(
      this.id,
      this.profilePicture1,
      this.profilePicture2,
      this.profilePicture3,
      this.profilePicture4,
      this.name,
      this.favoriteMusic,
      this.favoritePh,
      this.targetLatitude,
      this.targetLongitude);
}
