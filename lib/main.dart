import 'dart:async';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter/material.dart';
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
      home: new MatchPage(),
    );
  }
}

class MatchPage extends StatefulWidget {
  @override
  State<MatchPage> createState() => new MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  DocumentReference _profile;
  List<MatchData> _potentialMatches;
  Set<String> _nonMatches;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _potentialMatches = [];
    _nonMatches = new Set<String>();
    fetchMatchData();
  }

  fetchMatchData() {
    String query = _nonMatches.join('&id=');
    http.get(cloudFunctionUrl + query).then((response) {
      var suggestedMatches = json.decode(response.body);
      setState(() {
        _potentialMatches = suggestedMatches.map<MatchData>(
                (matchData) => new MatchData.parseResponse(matchData)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_potentialMatches.isEmpty) {
      return new Scaffold(
          appBar: new AppBar(
            title: new Text('Plenty of Goldfish'),
          ),
        body: Center(
          child: new Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                new CircularProgressIndicator(),
                new Text('Gone Fishing...'),
              ]),
        )
      );

    } else {
      var matchData = _potentialMatches.first;
      return new Scaffold(
        appBar: new AppBar(
          title: new Text('Plenty of Goldfish'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: new FloatingActionButton(onPressed: () {
          Navigator.of(context).push(new MaterialPageRoute<Null>(
              builder: (BuildContext context)
              {
                return new ProfilePage();
              }));

        }, child: new Icon(Icons.person)),
        body: new Padding(
            padding: EdgeInsets.all(10.0),
            child: new Dismissible(
              key: new ObjectKey(matchData),
              child: new Card(child: new SimpleProfile(matchData, false)),
              background: new Container(
                  child: new Text('Reject'), color: Colors.red),
              secondaryBackground: new Container(
                  child: new Center(child: new Text('Accept')),
                  color: Colors.green),
              onDismissed: (direction) {
                setState(() {
                  _potentialMatches.removeAt(0);
                });
                if (direction == DismissDirection.startToEnd) {
                  _nonMatches.add(matchData.id);
                  if (_potentialMatches.isEmpty) fetchMatchData();
                } else {
                  Navigator.of(context).push(new MaterialPageRoute<Null>(
                      builder: (BuildContext context) {
                        return new FinderPage(
                            matchData.targetLatitude,
                            matchData.targetLongitude);
                      }));
                }
              },
            )),
      );
    }
  }
}

class ProfilePage extends StatefulWidget {
  _ProfilePageState createState() => new _ProfilePageState();
}

// we may decide not to do this part since a close variant is shown in our other talk.
class _ProfilePageState extends State<ProfilePage> {
  DocumentReference _profile;
  bool _editing;
  MatchData _myData;
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
      if (_focus.hasFocus) setState(() => _showFab = false);
      else setState(() => _showFab = true);
    });
    _myData = new MatchData(_profile.documentID);
  }

  Future<Null> _updateProfile() async {
    // Get GPS data just before sending.
    Map<String, double> currentLocation =
        await new LocationTools().getLocation();
    _myData.targetLongitude = currentLocation['latitude'];
    _myData.targetLatitude = currentLocation['longitude'];
    _profile.setData(_myData.serialize(), SetOptions.merge);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
          appBar: new AppBar(
          title: new Text('My Profile'),
        ),
        floatingActionButton: _showFab
            ? new FloatingActionButton(
                onPressed: () {
                  _updateProfile();
                  setState(() {
                    _editing = !_editing;
                  });
                },
                tooltip: _editing ? 'Edit Profile' : 'Save Changes',
                child: new Icon(_editing ? Icons.check : Icons.edit),
              )
            : null,
        body: new SimpleProfile(_myData, _editing, _focus));
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
