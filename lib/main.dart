import 'dart:async';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'utils.dart';
import 'shared_widgets.dart';

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
  MatchData _matchData;
  Set<String> _nonMatches;
  bool _showFab;
  FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _profile = Firestore.instance.collection('profiles').document();
    _editing = false;
    _showFab = true;
    _focus = new FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        setState(() => _showFab = false);
      } else {
        setState(() => _showFab = true);
      }
    });
    _matchData = new MatchData();
    _nonMatches = new Set<String>()..add(_profile.documentID);
  }

  Future<Null> _updateProfile() async {
    // Get GPS data just before sending.
    Map<String, double> currentLocation =
        await new LocationTools().getLocation();
    _matchData.targetLongitude = currentLocation['latitude'];
    _matchData.targetLatitude = currentLocation['longitude'];
    _profile.setData(_matchData.serialize(), SetOptions.merge);
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
                  new Text('Gone Fishing...'),
                ],
              ),
            ),
          ),
    );
    Map<String, dynamic> response = json.decode((await http.get(
            'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=$query'))
        .body);
    Navigator.pop(context);

    return new MatchData.parseResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        floatingActionButton: _showFab
            ? new FloatingActionButton(
                onPressed: () {
                  _updateProfile();
                  setState(() {
                    _editing = !_editing;
                  });
                },
                tooltip: _editing ? 'Edit Profile' : 'Save Changes',
                backgroundColor: _editing ? Colors.green : Colors.blue,
                child: new Icon(_editing ? Icons.check : Icons.edit),
              )
            : null,
        body: createScrollableProfile(
            context,
            _editing,
            _focus,
            _matchData,
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
                    label: new Text("Find your fish!")))));
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

  Widget _displayData(String label, String data, IconData iconData) {
    return new TextField(
        controller: new TextEditingController(text: data),
        decoration:
            new InputDecoration(labelText: label, icon: new Icon(iconData)),
        enabled: false);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Nonmatch case.
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Great catch!"),
      ),
      body: createScrollableProfile(
        context,
        false,
        null,
        matchData,
        new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                  return new FinderPage(
                      matchData.targetLatitude, matchData.targetLongitude);
                }));
              },
              child: new Text("Accept")),
        ]),
      ),
    );
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
