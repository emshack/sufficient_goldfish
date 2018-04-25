import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:sensors/sensors.dart';

import 'utils.dart';

const backgroundAudio = 'background.wav';
const savedAudio = 'saved.mp3';

AudioTools audioTools = AudioTools();
FirebaseUser user;

Future<void> main() async {
  user = await FirebaseAuth.instance.signInAnonymously();
  audioTools.loadFile(backgroundAudio).then((_) {
    audioTools.initAudioLoop(backgroundAudio);
  });
  audioTools.loadFile(savedAudio);
  runApp(MaterialApp(
    title: 'Sufficient Goldfish',
    theme: ThemeData(primarySwatch: Colors.indigo),
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('profiles').snapshots,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        List<DocumentSnapshot> documents = snapshot.data?.documents ?? [];
        List<FishData> fish = documents.map((DocumentSnapshot snapshot) {
          return FishData.parseData(snapshot);
        }).toList();
        return FishPage(fish);
      },
    );
  }
}

enum ViewType { available, reserved }

class FishPage extends StatefulWidget {
  final List<FishData> allFish;

  FishPage(this.allFish);

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  FishData _undoData;
  ViewType _viewType = ViewType.available;

  @override
  initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.y.abs() >= 20 &&
          _undoData != null &&
          _viewType == ViewType.reserved) {
        _reserveFish(_undoData);
        _undoData = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FishData> filteredFish = widget.allFish.where((FishData data) {
      if (_viewType == ViewType.available) {
        return data.reservedBy == null || data.reservedBy == user.uid;
      } else {
        return data.reservedBy == user.uid;
      }
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Sufficient Goldfish'),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                colors: [Colors.blue, Colors.lightBlueAccent])),
        child: FishOptions(filteredFish, _viewType, _reserveFish, _removeFish),
      ),
    );
  }

  void _removeFish(FishData fishOfInterest) {
    _undoData = fishOfInterest;
    fishOfInterest.reservedBy = null;
    fishOfInterest.save();
  }

  void _reserveFish(FishData fishOfInterest) {
    fishOfInterest.reservedBy = user.uid;
    fishOfInterest.save();
  }
}

class FishOptions extends StatelessWidget {
  final List<FishData> fish;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final ViewType viewType;

  FishOptions(
      this.fish, this.viewType, this.onAddedCallback, this.onRemovedCallback);

  @override
  Widget build(BuildContext context) {
    return CoverFlow(
        dismissibleItems: viewType == ViewType.reserved,
        itemBuilder: (_, int index) {
          var fishOfInterest = fish.isEmpty ? FishData.data(null) : fish[index];
          var isReserved = fishOfInterest.reservedBy == user.uid;
          return ProfileCard(
            fishOfInterest,
            viewType,
            () => onAddedCallback(fishOfInterest),
            () => onRemovedCallback(fishOfInterest),
            isReserved,
          );
        },
        dismissedCallback: (int card, DismissDirection direction) =>
            onDismissed(card, direction),
        itemCount: fish.length);
  }

  onDismissed(int card, _) {
    FishData fishOfInterest = fish[card];
    onRemovedCallback(fishOfInterest);
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
      child: _getCardContents(),
    );
  }

  Widget _getCardContents() {
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
    return Column(children: contents);
  }

  Widget _showData(String name, String music, String pH) {
    var subHeadingStyle =
        TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
    Widget nameWidget = Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
          textAlign: TextAlign.center,
        ));
    Text musicWidget = Text('Favorite music: $music', style: subHeadingStyle);
    Text phWidget = Text('Favorite pH: $pH', style: subHeadingStyle);
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return Column(children: children);
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
