import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import 'dart:async';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: new ThemeData.light(), // switch to ThemeData.day() when available
      home: new MatchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MatchPage extends StatefulWidget {
  @override
  State<MatchPage> createState() => new MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  DocumentReference _myProfile;
  List<MatchData> _potentialMatches;
  Set<String> _nonMatches;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _potentialMatches = [];
    _nonMatches = new Set<String>();
    _myProfile = Firestore.instance.collection('profiles').document();
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
      body = new CoverFlow(widgetBuilder, dismissedCallback: disposeDismissed);
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Sufficient Goldfish'),
      ),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: new Builder(builder: buildFab),
    );
  }

  Widget buildFab(BuildContext context) {
    return new FloatingActionButton(
        onPressed: () {
          _saveLocation(context);
        },
        child: new Icon(Icons.add_location));
  }

  Future<Null> _saveLocation(BuildContext context) async {
    Map<String, double> currentLocation =
    await new LocationTools().getLocation();
    // Make dummy profile data.
    var myData = new MatchData(_myProfile.documentID);
    myData.targetLongitude = currentLocation['latitude'];
    myData.targetLatitude = currentLocation['longitude'];

    await _myProfile.setData(myData.serialize(), SetOptions.merge);
    Scaffold.of(context).showSnackBar(new SnackBar(content: new Text('Location saved!')));
  }

  Widget widgetBuilder(BuildContext context, int index) {
    if (_potentialMatches.length == 0) {
      return new Center(child: new Text('You rejected all of your matches!'));
    } else {
      return new ProfileCard(
          _potentialMatches[index % _potentialMatches.length]);
    }
  }


  disposeDismissed(int card, DismissDirection direction) {
    _potentialMatches.removeAt(card % _potentialMatches.length);
  }
}

class ProfileCard extends StatelessWidget {
  final MatchData data;

  ProfileCard(this.data);

  @override
  Widget build(BuildContext context) {
    return new Card(
        child: new Container(
      padding: new EdgeInsets.all(16.0),
      child: new Column(children: <Widget>[
        new Expanded(flex: 1, child: showProfilePicture(data)),
        _showData(data.name, data.favoriteMusic, data.favoritePh),
        new RaisedButton.icon(
            color: Colors.green,
            icon: new Icon(Icons.check),
            label: new Text('Meet'),
            onPressed: () {
              Navigator.of(context).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new FinderPage(
                    data.targetLatitude, data.targetLongitude);
              }));
            }),
      ]),
    ));
  }

  Widget _showData(String name, String music, String pH) {
    Text nameWidget = new Text(name,
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0));
    Text musicWidget = new Text('Favorite music: $music',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    Text phWidget = new Text('Favorite pH: $pH',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return new Column(
        children: children
            .map((child) =>
                new Padding(child: child, padding: new EdgeInsets.all(8.0)))
            .toList());
  }

  Widget showProfilePicture(MatchData matchData) {
    return new Image.network(
      matchData.profilePicture.toString(),
      fit: BoxFit.cover,
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