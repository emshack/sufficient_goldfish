import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

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
      floatingActionButton: new FloatingActionButton.extended(
          icon: new Icon(Icons.shopping_cart),
          label: new Text("Reserved"),
          onPressed: null),
    );
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
            label: new Text('Save'),
            onPressed: () {
              //TODO
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
