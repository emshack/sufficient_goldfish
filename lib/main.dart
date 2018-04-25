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
    return FishPage([]);
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
  }

  @override
  Widget build(BuildContext context) {
    List<FishData> filteredFish = widget.allFish;
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
      body: Container(),
    );
  }

  void _removeFish(FishData fishOfInterest) {}

  void _reserveFish(FishData fishOfInterest) {}
}

class FishOptionsView extends StatelessWidget {
  final List<FishData> fish;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final ViewType viewType;

  FishOptionsView(
      this.fish, this.viewType, this.onAddedCallback, this.onRemovedCallback);

  @override
  Widget build(BuildContext context) {
    var fishOfInterest = FishData.data(null);
    return ProfileCard(
      fishOfInterest,
      viewType,
      () => onAddedCallback(fishOfInterest),
      () => onRemovedCallback(fishOfInterest),
      fishOfInterest.reservedBy == user.uid,
    );
  }

  onDismissed(int card, _) {}
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
          color: Colors.green,
          icon: Icon(Icons.check),
          label: Text('Add'),
          onPressed: null,
        ))
      ]));
    }
    return Column(children: contents);
  }

  Widget _showData(String name, String music, String pH) {
    var subHeadingStyle =
        TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
    var nameWidget = Text(
      name,
      style: subHeadingStyle,
      textAlign: TextAlign.center,
    );
    var musicWidget = Text('Favorite music: $music', style: subHeadingStyle);
    var phWidget = Text('Favorite pH: $pH', style: subHeadingStyle);
    return Container();
  }

  Widget _showProfilePicture(FishData fishData) {
    return Container();
  }
}
