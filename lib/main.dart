import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'utils.dart';
import 'my_profile_page.dart';

// From Hans:
// In a couple of days, I hope a more complete version of this will be the
// value of new ThemeData.day(), the M2 "light" theme. There will also
// be a new ThemeData.night().
final ThemeData m2Theme = new ThemeData(
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  backgroundColor: Colors.white,
  dividerColor: const Color(0xFFAAF7FE),
  buttonColor: Colors.blue[500],
  buttonTheme: new ButtonThemeData(
    textTheme: ButtonTextTheme.primary,
  ),
  errorColor: const Color(0xFFFF1744),
  highlightColor: Colors.transparent,
  splashColor: Colors.white24,
  splashFactory: InkRipple.splashFactory,
);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: m2Theme,
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
        _potentialMatches = suggestedMatches
            .map<MatchData>(
                (matchData) => new MatchData.parseResponse(matchData))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_potentialMatches.isEmpty) {
      body = new Center(
        child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new CircularProgressIndicator(),
              new Text('Gone Fishing...'),
            ]));
    } else {
      var matchData = _potentialMatches.first;
      body = new Padding(
          padding: EdgeInsets.all(10.0),
          child: new Dismissible(
            key: new ObjectKey(matchData),
            child: new ProfileCard(matchData),
            background: new Container(
                child: new Icon(Icons.thumb_down), color: Colors.red),
            secondaryBackground: new Container(
                child: new Icon(Icons.thumb_up), color: Colors.green),
            onDismissed: (dismissed) => _respondToChoice(matchData, dismissed)));
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Sufficient Goldfish'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: new FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new ProfilePage();
              }));
            },
            child: new Icon(Icons.person)),
        body: body);
  }

  _respondToChoice(MatchData matchData, DismissDirection direction) {
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
                matchData.targetLatitude, matchData.targetLongitude);
          }));
    }
  }
}

class ProfileCard extends StatelessWidget {
  MatchData data;
  ProfileCard(this.data);

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new ListView(shrinkWrap: true, children: <Widget>[
        new Padding(
          padding: const EdgeInsets.all(8.0),
          child: showProfilePictures(data),
        ),
        new Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: new Column(
            children: <Widget>[
              _showData('Name', data.name, Icons.person),
              _showData('Favorite Music', data.favoriteMusic, Icons.music_note),
              _showData(
                  'Favorite pH level', data.favoritePh, Icons.beach_access),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _showData(String label, String text, IconData iconData) {
    // TODO(emshack): Help me make this less ugly!
    return new Text('$label: $text');
  }

  Widget showProfilePictures(MatchData matchData) {
    var tiles = new List.generate(
        4,
        (i) => new Expanded(
            flex: i == 0 ? 0 : 1,
            child: new Card(
                child: new Image.network(matchData.getImage(i).toString(),
                    fit: BoxFit.cover))));
    var mainImage = tiles.removeAt(0);
    return new Column(children: <Widget>[
      mainImage,
      new Row(children: tiles),
    ]);
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
      latitude = currentLocation['latitude'];
      longitude = currentLocation['longitude'];
      accuracy = currentLocation['accuracy'];
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
            new Text(
              'Locate your match!',
              style: new TextStyle(
                  color: Colors.black,
                  fontSize: 32.0,
                  decoration: TextDecoration.none),
            ),
            new Image.asset('assets/location_ping.gif'),
            new FloatingActionButton.extended(
              icon: new Icon(Icons.cancel, color: Colors.black),
              label: new Text(
                'Cancel',
                style: new TextStyle(color: Colors.black, fontSize: 24.0),
              ),
              onPressed: () {
                audioTools.stopAudio();
                Navigator.pop(context);
              },
            ),
          ]),
    );
  }
}
