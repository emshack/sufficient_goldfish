import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

const baseAudio =
    'http://freesound.org/data/previews/243/243953_1565498-lq.mp3';
const dismissedAudio =
    'http://freesound.org/data/previews/398/398025_7586736-lq.mp3';
const savedAudio =
    'http://freesound.org/data/previews/189/189499_1970026-lq.mp3';
const baseName = 'base';
const dismissedName = 'dismissed';
const savedName = 'saved';

AudioTools audioTools = new AudioTools();

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: new ThemeData.light(), // switch to ThemeData.day() when available
      home: new FishPage(PageType.shopping),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum PageType { shopping, reserved }

class FishPage extends StatefulWidget {
  final PageType pageType;

  FishPage(this.pageType);

  @override
  State<FishPage> createState() => new FishPageState();
}

class FishPageState extends State<FishPage> {
  DocumentReference _myProfile;
  List<FishData> _fishList;
  Set<String> _rejectedFish;
  bool _audioToolsReady = false;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _fishList = [];
    _rejectedFish = new Set<String>();
    _myProfile = Firestore.instance.collection('buyers').document();
    if (!_audioToolsReady) populateAudioTools();
    fetchFishData();
  }

  Future<Null> populateAudioTools() async {
    await audioTools.loadFile(baseAudio, baseName);
    await audioTools.loadFile(dismissedAudio, dismissedName);
    await audioTools.loadFile(savedAudio, savedName);
    setState(() {
      _audioToolsReady = true;
    });
  }

  fetchFishData() {
    // TODO: Pull down reserved fish if widget.pageType == PageType.reserved
    // and pull down list of available fish if widget.pageType == PageType.shopping
    String query = _rejectedFish.join('&id=');
    http.get(cloudFunctionUrl + query).then((response) {
      var suggestedMatches = json.decode(response.body);
      setState(() {
        _fishList = suggestedMatches
            .map<FishData>((fishData) => new FishData.parseResponse(fishData))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_fishList.isEmpty || !_audioToolsReady) {
      body = new Center(
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            new CircularProgressIndicator(),
            new Text('Gone Fishing...'),
          ]));
    } else {
      body = new StreamBuilder<DocumentSnapshot>(
          stream: Firestore.instance.collection('profiles').snapshots.map((QuerySnapshot snapshot) =>
            snapshot.documents).expand((List<DocumentSnapshot> docs) => docs).where((DocumentSnapshot aDoc) =>
              !aDoc.data.containsKey('reservedBy')),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (!snapshot.hasData) return const Text('There are plenty of fish in the sea...');
            return new CoverFlow((_, int index) {
                var data = new FishData.data(snapshot.data.documentID, snapshot.data['Field.name'], snapshot.data['Field.favoriteMusic'], snapshot.data['Field.phValue'], snapshot.data['Field.profilePicture']);
                return new ProfileCard(data, widget.pageType);
            }, dismissedCallback: (int card, DismissDirection direction) => onDismissed(card, direction, snapshot.data));
          });
      if (widget.pageType == PageType.shopping)
        audioTools.initAudioLoop(baseName);
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.pageType == PageType.shopping
            ? 'Sufficient Goldfish'
            : 'Your Reserved Fish'),
      ),
      body: body,
      floatingActionButton: widget.pageType == PageType.shopping
          ? new FloatingActionButton.extended(
              icon: new Icon(Icons.shopping_cart),
              label: new Text("Reserved"),
              onPressed: () {
                Navigator.of(context).push(new MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                  return new FishPage(PageType.reserved);
                }));
              })
          : null,
    );
  }

  Widget widgetBuilder(BuildContext context, int index) {
    if (_fishList.length == 0) {
      return new Center(
          child: new Text('There are plenty of fish in the sea...'));
    } else {
      return new ProfileCard(
          _fishList[index % _fishList.length], widget.pageType);
    }
  }

  onDismissed(int card, DismissDirection direction, DocumentSnapshot fishOfInterest) {
    audioTools.playAudio(dismissedName);
    // TODO: If widget.pageType == PageType.reserved, write this fish back to
    // the list of available fish in Firebase
    fishOfInterest.reference.setData({'reservedBy': _myProfile.documentID}, SetOptions.merge);
    _myProfile.setData({'savedFish': fishOfInterest.documentID}, SetOptions.merge);
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final PageType pageType;

  ProfileCard(this.data, this.pageType);

  @override
  Widget build(BuildContext context) {
    return new Card(
        child: new Container(
      padding: new EdgeInsets.all(16.0),
      child: new Column(children: _getCardContents()),
    ));
  }

  List<Widget> _getCardContents() {
    List<Widget> contents = <Widget>[
      new Expanded(flex: 1, child: showProfilePicture(data)),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    if (pageType == PageType.shopping) {
      contents.add(new RaisedButton.icon(
          color: Colors.green,
          icon: new Icon(Icons.check),
          label: new Text('Save'),
          onPressed: () {
            audioTools.playAudio(savedName);
            //TODO
          }));
    }
    return contents;
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

  Widget showProfilePicture(FishData fishData) {
    return new Image.network(
      fishData.profilePicture.toString(),
      fit: BoxFit.cover,
    );
  }
}
