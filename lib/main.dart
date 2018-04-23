import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:sensors/sensors.dart';

import 'utils.dart';

const backgroundAudio = 'background.mp3';
const dismissedAudio = 'dismissed.mp3';
const savedAudio = 'saved.mp3';

AudioTools audioTools = AudioTools();
FirebaseUser user;

Future<void> main() async {
  user = await FirebaseAuth.instance.signInAnonymously();
  audioTools.loadFile(backgroundAudio).then((_) {
    audioTools.initAudioLoop(backgroundAudio);
  });
  audioTools.loadFile(dismissedAudio);
  audioTools.loadFile(savedAudio);
  runApp(MaterialApp(
    title: 'Sufficient Goldfish',
    theme: ThemeData(primarySwatch: Colors.indigo), // switch to ThemeData.day() when available
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
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        List<DocumentSnapshot> documents = snapshot.data?.documents ?? [];
        List<FishData> fish = documents.map((DocumentSnapshot snapshot) {
          return FishData.parseData(snapshot);
        }).toList();
        return new FishPage(fish);
      },
    );
  }
}

class ShakeDetector extends StatelessWidget {
  ShakeDetector({this.onShake, this.child});

  final VoidCallback onShake;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder(
      stream: accelerometerEvents,
      builder:
          (BuildContext context, AsyncSnapshot<AccelerometerEvent> snapshot) {
        if (snapshot.hasData && snapshot.data.y.abs() >= 20) onShake();
        return child;
      },
    );
  }
}

enum ViewType { available, reserved }

class FishPage extends StatefulWidget {
  FishPage(this.fish);

  final List<FishData> fish;

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  FishData _undoData;
  ViewType _viewType = ViewType.available;

  @override
  Widget build(BuildContext context) {
    return new ShakeDetector(
      onShake: () {
        if (_undoData != null) {
          // Shake-to-undo last action.
          if (_viewType == ViewType.available) {
            _removeFish(_undoData);
          } else {
            _reserveFish(_undoData);
          }
          _undoData = null;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: new Text('Sufficient Goldfish'),
        ),
        bottomNavigationBar: new BottomNavigationBar(
          currentIndex: _viewType == ViewType.available ? 0 : 1,
          onTap: (int index) {
            setState(() {
              _viewType = index == 0 ? ViewType.available : ViewType.reserved;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                title: Text('Available'), icon: Icon(Icons.home)),
            BottomNavigationBarItem(
                title: Text('Reserved'), icon: Icon(Icons.shopping_basket)),
          ],
        ),
        body: Container(
          decoration: new BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.lightBlueAccent])),
          child: FishOptionsView(
            widget.fish.where((FishData data) {
              if (_viewType == ViewType.available) {
                return data.reservedBy != user.uid;
              } else {
                return data.reservedBy == user.uid;
              }
            }).toList(),
            _viewType,
            _reserveFish,
            _removeFish,
          ),
        ),
      ),
    );
  }

  void _removeFish(FishData fishOfInterest) {
    fishOfInterest.reservedBy = null;
    fishOfInterest.save();
  }

  void _reserveFish(FishData fishOfInterest) {
    fishOfInterest.reservedBy = user.uid;
    fishOfInterest.save();
  }
}

class FishOptionsView extends StatelessWidget {
  final List<FishData> _fishList;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final ViewType _viewType;

  // NB: This assumes _fishList != null && _fishList.length > 0.
  FishOptionsView(this._fishList, this._viewType, this.onAddedCallback,
      this.onRemovedCallback) : super(key: new ObjectKey(_fishList));

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
    audioTools.playAudio(dismissedAudio);
    FishData fishOfInterest = _fishList[card];
    if (_viewType == ViewType.reserved) {
      // Write this fish back to the list of available fish in Firebase.
      onRemovedCallback(fishOfInterest);
    }
    //_undoData = fishOfInterest;
  }

  /*void _rejectFish(DocumentSnapshot fishOfInterest) {
    var fishData = new FishData.parseData(fishOfInterest);
    fishData.addRejectedBy(widget.deviceId);
    fishOfInterest.reference.setData(fishData.serialize());
  }*/
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
      key: new ValueKey(data.id),
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
                  audioTools.playAudio(savedAudio);
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
