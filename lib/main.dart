import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
const reservedBy = 'reservedBy';

AudioTools audioTools = AudioTools();
FirebaseUser user;

Future<void> main() async {
  user = await FirebaseAuth.instance.signInAnonymously();
  audioTools.loadFile(baseAudio, baseName).then((_) {
    audioTools.initAudioLoop(baseName);
  });
  audioTools.loadFile(dismissedAudio, dismissedName);
  audioTools.loadFile(savedAudio, savedName);
  runApp(MaterialApp(
    title: 'Sufficient Goldfish',
    theme: ThemeData.light(), // switch to ThemeData.day() when available
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatelessWidget {
  MyApp();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('profiles').snapshots,
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot> snapshot) {
        List<DocumentSnapshot> documents = snapshot.data?.documents ?? [];
        List<FishData> fish = documents.map((DocumentSnapshot snapshot) {
          return FishData.parseData(snapshot);
        }).toList();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: new Text('Sufficient Goldfish'),
              backgroundColor: Colors.indigo,
              bottom: new TabBar(
                tabs: <Tab>[
                  new Tab(
                    icon: Icon(Icons.home),
                  ),
                  new Tab(
                    icon: Icon(Icons.shopping_basket),
                  ),
                ],
              ),
            ),
            body: Container(
                decoration: new BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        colors: [Colors.blue, Colors.lightBlueAccent])),
                child: TabBarView(
                  children: <Widget>[
                    new FishPage(fish: fish, viewType: ViewType.available),
                    new FishPage(fish: fish, viewType: ViewType.reserved),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }
}

class ShakeDetector extends StatelessWidget {
  ShakeDetector({ this.onShake, this.child });
  final VoidCallback onShake;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder(
      stream: accelerometerEvents,
      builder: (BuildContext context, AsyncSnapshot<AccelerometerEvent> snapshot) {
        if (snapshot.hasData && snapshot.data.y.abs() >= 20)
          onShake();
        return child;
      }
    );
  }
}

enum ViewType { available, reserved }

class FishPage extends StatefulWidget {
  FishPage({ this.fish, this.viewType });
  final List<FishData> fish;
  final ViewType viewType;

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  FishData _undoData;

  @override
  Widget build(BuildContext context) {

    Widget body = Container();
    var fishList = widget.fish.where((FishData data) {
      if (widget.viewType == ViewType.available) {
        return data.reservedBy != user.uid;
      } else {
        return data.reservedBy == user.uid;
      }
    }).toList();
    if (fishList.length > 0) body = FishOptionsView(fishList, widget.viewType, _reserveFish, _removeFish);

    return new ShakeDetector(
      onShake: () {
        if (_undoData != null) {
          // Shake-to-undo last action.
          if (widget.viewType == ViewType.available) {
            _removeFish(_undoData);
          } else {
            _reserveFish(_undoData);
          }
          _undoData = null;
        }
      },
      child: body,
    );
  }

  void _removeFish(FishData fishOfInterest) {
    DocumentReference reference = Firestore.instance.collection('profiles').document(fishOfInterest.id);
    reference.setData({ reservedBy: null });
  }

  void _reserveFish(FishData fishOfInterest) {
    DocumentReference reference = Firestore.instance.collection('profiles').document(fishOfInterest.id);
    reference.setData({ reservedBy: user.uid });
  }
}

class FishOptionsView extends StatelessWidget {
  final List<FishData> _fishList;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final ViewType _viewType;

  // NB: This assumes _fishList != null && _fishList.length > 0.
  FishOptionsView(this._fishList, this._viewType, this.onAddedCallback, this.onRemovedCallback);

  @override
  Widget build(BuildContext context) {
    return CoverFlow(
        dismissibleItems: _viewType == ViewType.reserved,
        itemBuilder: (_, int index) {
          var fishOfInterest = _fishList[index];
          var isReserved = fishOfInterest.reservedBy == user.uid;
          return ProfileCard(
              fishOfInterest,
              _viewType,
                  () => onAddedCallback(fishOfInterest),
                  () => onRemovedCallback(fishOfInterest),
              isReserved);
        },
        dismissedCallback: (int card, DismissDirection direction) =>
            onDismissed(card, direction),
        itemCount: _fishList.length);
  }

  onDismissed(int card, _) {
    audioTools.playAudio(dismissedName);
    FishData fishOfInterest = _fishList[card];
    if (_viewType == ViewType.reserved) {
      // Write this fish back to the list of available fish in Firebase.
      onRemovedCallback(fishOfInterest);
    }
    //_undoData = fishOfInterest;
  }

}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final ViewType viewType;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final bool isReserved;

  ProfileCard(this.data, this.viewType, this.onAddedCallback,
      this.onRemovedCallback, this.isReserved);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isReserved && viewType == ViewType.available
          ? Colors.white30
          : Colors.white,
      child: Column(children: _getCardContents()),
    );
  }

  List<Widget> _getCardContents() {
    List<Widget> contents = <Widget>[
      _showProfilePicture(data),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    if (viewType == ViewType.available) {
      contents.add(Row(children: [
        Expanded(
            child: FlatButton.icon(
                color: isReserved ? Colors.red : Colors.green,
                icon: Icon(isReserved ? Icons.not_interested : Icons.check),
                label: Text(isReserved ? 'Remove' : 'Add'),
                onPressed: () {
                  audioTools.playAudio(savedName);
                  isReserved ? onRemovedCallback() : onAddedCallback();
                }))
      ]));
    }
    return contents;
  }

  Widget _showData(String name, String music, String pH) {
    var subHeadingStyle =
        TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
    Widget nameWidget = Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
          textAlign: TextAlign.center,
        ));
    Text musicWidget = Text('Favorite music: $music', style: subHeadingStyle);
    Text phWidget = Text('Favorite pH: $pH', style: subHeadingStyle);
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return Column(
        children: children
            .map((child) =>
                Padding(child: child, padding: EdgeInsets.only(bottom: 8.0)))
            .toList());
  }

  Widget _showProfilePicture(FishData fishData) {
    return Expanded(
      child: Image.network(
        fishData.profilePicture,
        fit: BoxFit.cover,
      ),
    );
  }
}
