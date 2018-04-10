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

// we may decide not to do this part since a close variant is shown in our other talk.
class _ProfilePageState extends State<ProfilePage> {
  DocumentReference _profile;
  bool _editing;
  MatchData _matchData;
  Set<String> _nonMatches;
  bool _showFab;
  FocusNode _focus;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

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
    _matchData = new MatchData();//_profile.documentID);
    _nonMatches = new Set<String>()..add(_matchData.id);
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
            cloudFunctionUrl + query)).body);
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
                        return new MatchPage2(matchData, (id) =>
                            _nonMatches.add(matchData.id));
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

class MatchPage extends StatefulWidget {
  @override
  State<MatchPage> createState() => new MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  DocumentReference _profile;
  bool _hasData;
  List<MatchData> _potentialMatches;
  MatchData _matchData;
  Set<String> _nonMatches;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _matchData = new MatchData();
    _potentialMatches = [_matchData];
    _hasData = false;
    _nonMatches = new Set<String>();
    fetchMatchData();
  }

  fetchMatchData() {
    String query = _nonMatches.join('&id=');
    http.get(cloudFunctionUrl + query).then((response) {
      MatchData matchData = new MatchData.parseResponse(json.decode(response.body));
      // TODO: return a lsit of results.
      setState(() {
        _hasData = true;
        _matchData = matchData;
        _potentialMatches = [matchData];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      // TODO.
      /*Scaffold.of(context).showSnackBar(new SnackBar(content: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          new CircularProgressIndicator(),
          new Text('Gone Fishing...'),
        ],
      )));*/
    }
    var matchCard = new Card(child: new SimpleProfile(_matchData, false));
    // TODO: Need to notify that the state of the images has been updated.
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Plenty of Goldfish'),
      ),
      body: new Column(children: [
        new Padding(
            padding: EdgeInsets.all(10.0),
            child: new Dismissible(
                key: new Key(_matchData.toString()),
                child: matchCard,
              background: new Container(child: new Text('Reject'), color: Colors.red),
              secondaryBackground: new Container(child: new Center(child: new Text('Accept')), color: Colors.green),
              onDismissed: (direction) {
                  if(direction == DismissDirection.startToEnd) {
                    _nonMatches.add(_matchData.id);
                    _hasData = false;
                    fetchMatchData();
                  } else {
                    Navigator.of(context).push(new MaterialPageRoute<Null>(
                        builder: (BuildContext context) {
                          return new FinderPage(
                              _matchData.targetLatitude, _matchData.targetLongitude);
                        }));
                  }
                  _potentialMatches.remove(matchCard);
              },
            )),
        new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          new FlatButton(
              onPressed: () {
                _nonMatches.add(_matchData.id);
                _hasData = false;
                fetchMatchData();
              },
              child: new Text("Reject")),
          new FlatButton(
              onPressed: () {

              },
              child: new Text("Accept")),
        ])
      ]),
    );
  }

}

class MatchPage2 extends StatelessWidget {
  final MatchData matchData;
  final Function rejectCallback;

  MatchPage2(this.matchData, this.rejectCallback);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Plenty of Goldfish'),
      ),
      body: createScrollableProfile(
        context,
        false,
        null,
        matchData,
        new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          new FlatButton(
              onPressed: () {
                rejectCallback(matchData.id);
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
