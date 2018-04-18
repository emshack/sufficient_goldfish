import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:sensors/sensors.dart';

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
  final DocumentReference userProfile;

  FishPage(this.pageType, [this.userProfile]);

  @override
  State<FishPage> createState() => new FishPageState(userProfile);
}

class FishPageState extends State<FishPage> {
  DocumentReference _myProfile;
  bool _audioToolsReady = false;
  DocumentSnapshot _lastFish;

  FishPageState(this._myProfile);

  @override
  void initState() {
    super.initState();
    if (_myProfile == null) {
      _myProfile = Firestore.instance.collection('buyers').document();
    }
    if (!_audioToolsReady) populateAudioTools();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.y.abs() >= 20 && _lastFish != null) {
        // Shake-to-undo last action.
        if (widget.pageType == PageType.shopping) {
          _removeFish(_lastFish);
        } else {
          _reserveFish(_lastFish);
        }
        _lastFish = null;
      }
    });
  }

  Future<Null> populateAudioTools() async {
    await audioTools.loadFile(baseAudio, baseName);
    await audioTools.loadFile(dismissedAudio, dismissedName);
    await audioTools.loadFile(savedAudio, savedName);
    setState(() {
      _audioToolsReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_audioToolsReady) {
      body = new Center(
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            new CircularProgressIndicator(),
            new Text('Gone Fishing...'),
          ]));
    } else {
      body = new StreamBuilder<List<DocumentSnapshot>>(
          stream: Firestore.instance
              .collection('profiles')
              .snapshots
              .map((QuerySnapshot snapshot) {
            if (widget.pageType == PageType.shopping) {
              // Filter out results that are already reserved.
              return snapshot.documents
                  .where((DocumentSnapshot aDoc) =>
                      !aDoc.data.containsKey('reservedBy'))
                  .toList();
            } else {
              // TODO(efortuna): for responsiveness, consider building two
              // streams (one for the reserved and one for the shopping) and
              // just swap them out. (this would result in just one page and
              // eliminate Navigator.of though...)
              return snapshot.documents
                  .where((DocumentSnapshot aDoc) =>
                      aDoc.data['reservedBy'] == _myProfile.documentID)
                  .toList();
            }
          }),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            if (!snapshot.hasData || snapshot.data.length == 0)
              return new Center(
                  child: const Text('There are plenty of fish in the sea...'));
            return new CoverFlow((_, int index) {
              var fishOfInterest = snapshot.data[index % snapshot.data.length];
              var data = new FishData.parse(fishOfInterest);
              return new ProfileCard(
                  data, widget.pageType, () => _reserveFish(fishOfInterest));
            },
                dismissedCallback: (int card, DismissDirection direction) =>
                    onDismissed(card, direction, snapshot.data));
          });
      if (widget.pageType == PageType.shopping)
        audioTools.initAudioLoop(baseName);
    }

    return new Scaffold(
      appBar: widget.pageType == PageType.shopping
          ? _getShoppingAppBar()
          : _getReservedAppBar(),
      body: body,
    );
  }

  AppBar _getShoppingAppBar() {
    return new AppBar(
      title: new Text('Sufficient Goldfish'),
      actions: <Widget>[
        new FlatButton.icon(
            icon: new Icon(Icons.shopping_cart),
            label: new Text("2"), // TODO: Update with number in cart
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                return new FishPage(PageType.reserved, _myProfile);
              }));
            }),
      ],
    );
  }

  AppBar _getReservedAppBar() {
    return new AppBar(
      title: new Text('Your Reserved Fish'),
    );
  }

  onDismissed(
      int card, DismissDirection direction, List<DocumentSnapshot> allFish) {
    audioTools.playAudio(dismissedName);
    DocumentSnapshot fishOfInterest = allFish[card % allFish.length];
    if (widget.pageType == PageType.reserved) {
      // Write this fish back to the list of available fish in Firebase.
      _removeFish(fishOfInterest);
    }
    _lastFish = fishOfInterest;
  }

  void _removeFish(DocumentSnapshot fishOfInterest) {
    var existingData = fishOfInterest.data;
    existingData.remove('reservedBy');
    fishOfInterest.reference.setData(existingData);
  }

  void _reserveFish(DocumentSnapshot fishOfInterest) {
    fishOfInterest.reference
        .setData({'reservedBy': _myProfile.documentID}, SetOptions.merge);
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final PageType pageType;
  final Function onSavedCallback;

  ProfileCard(this.data, this.pageType, this.onSavedCallback);

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Column(children: _getCardContents()),
    );
  }

  List<Widget> _getCardContents() {
    List<Widget> contents = <Widget>[
      new Expanded(flex: 1, child: showProfilePicture(data)),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    if (pageType == PageType.shopping) {
      contents.add(new Row(children: [
        new Expanded(
            flex: 1,
            child: new FlatButton.icon(
                color: Colors.green,
                icon: new Icon(Icons.check),
                label: new Text('Save'),
                onPressed: () {
                  audioTools.playAudio(savedName);
                  onSavedCallback();
                }))
      ]));
    }
    return contents;
  }

  Widget _showData(String name, String music, String pH) {
    Widget nameWidget = new Padding(
        padding: new EdgeInsets.all(16.0),
        child: new Text(
          name,
          style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
          textAlign: TextAlign.center,
        ));
    Text musicWidget = new Text('Favorite music: $music',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    Text phWidget = new Text('Favorite pH: $pH',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return new Column(
        children: children
            .map((child) => new Padding(
                child: child,
                padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0)))
            .toList());
  }

  Widget showProfilePicture(FishData fishData) {
    return new Image.network(
      fishData.profilePicture.toString(),
      fit: BoxFit.cover,
    );
  }
}
