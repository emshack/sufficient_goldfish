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

AudioTools audioTools = AudioTools();

Future<void> main() async {
  var deviceId = await DeviceTools.getDeviceId();
  runApp(MyApp(deviceId));
}

class MyApp extends StatelessWidget {
  final String deviceId;
  MyApp(this.deviceId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sufficient Goldfish',
      theme: ThemeData.light(), // switch to ThemeData.day() when available
      home: FishPage(deviceId),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum ViewType { available, reserved }

class FishPage extends StatefulWidget {
  final String deviceId;

  FishPage(this.deviceId);

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  bool _audioToolsReady = false;
  DocumentSnapshot _lastFish;
  List<DocumentSnapshot> availableFish;
  List<DocumentSnapshot> reservedFish;
  ViewType viewType;

  FishPageState() : viewType = ViewType.available;

  @override
  void initState() {
    super.initState();
    if (!_audioToolsReady) populateAudioTools();
    _createStream(ViewType.available).listen((data) {
      setState(() => availableFish = data);
    });
    _createStream(ViewType.reserved).listen((data) {
      setState(() => reservedFish = data);
    });
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.y.abs() >= 20 && _lastFish != null) {
        // Shake-to-undo last action.
        if (viewType == ViewType.available) {
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

  Stream<List<DocumentSnapshot>> _createStream(ViewType viewType) {
    return Firestore.instance
        .collection('profiles')
        .snapshots
        .map((QuerySnapshot snapshot) {
      if (viewType == ViewType.available) {
        // Filter out results that are already reserved.
        return snapshot.documents
            .where((DocumentSnapshot aDoc) =>
                !aDoc.data.containsKey('reservedBy') ||
                aDoc.data['reservedBy'] == widget.deviceId)
            .toList();
      } else {
        return snapshot.documents
            .where((DocumentSnapshot aDoc) =>
                aDoc.data['reservedBy'] == widget.deviceId)
            .toList();
      }
    });
  }

  Widget _displayFish() {
    List<DocumentSnapshot> fishList =
        viewType == ViewType.available ? availableFish : reservedFish;
    if (fishList.length == 0)
      return Center(
          child: const Text('There are plenty of fish in the sea...'));
    return CoverFlow((_, int index) {
      var fishOfInterest = fishList[index % fishList.length];
      var data = FishData.parse(fishOfInterest);
      return ProfileCard(data, viewType, () => _reserveFish(fishOfInterest));
    },
        viewportFraction: .85,
        dismissedCallback: (int card, DismissDirection direction) =>
            onDismissed(card, direction, fishList));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_audioToolsReady) {
      body = Center(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        CircularProgressIndicator(),
        Text('Gone Fishing...'),
      ]));
    } else {
      body = _displayFish();
      audioTools.initAudioLoop(baseName);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: new Icon(Icons.home),
          onPressed: () {
            setState(() {
              viewType = ViewType.available;
            });
          },
        ),
        title: Text(viewType == ViewType.available
            ? 'Sufficient Goldfish'
            : 'Your Shopping Cart'),
        actions: <Widget>[
          FlatButton.icon(
              icon: Icon(Icons.shopping_cart),
              label: Text(reservedFish?.length.toString()),
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  viewType = ViewType.reserved;
                });
              }),
        ],
      ),
      body: body,
    );
  }

  onDismissed(
      int card, DismissDirection direction, List<DocumentSnapshot> allFish) {
    audioTools.playAudio(dismissedName);
    DocumentSnapshot fishOfInterest = allFish[card % allFish.length];
    if (viewType == ViewType.reserved) {
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
        .setData({'reservedBy': widget.deviceId}, SetOptions.merge);
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final ViewType viewType;
  final Function onSavedCallback;

  ProfileCard(this.data, this.viewType, this.onSavedCallback);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: _getCardContents()),
    );
  }

  List<Widget> _getCardContents() {
    List<Widget> contents = <Widget>[
      Expanded(flex: 1, child: showProfilePicture(data)),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    if (viewType == ViewType.available) {
      contents.add(Row(children: [
        Expanded(
            flex: 1,
            child: FlatButton.icon(
                color: Colors.green,
                icon: Icon(Icons.check),
                label: Text('Save'),
                onPressed: () {
                  audioTools.playAudio(savedName);
                  onSavedCallback();
                }))
      ]));
    }
    return contents;
  }

  Widget _showData(String name, String music, String pH) {
    Widget nameWidget = Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
          textAlign: TextAlign.center,
        ));
    Text musicWidget = Text('Favorite music: $music',
        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    Text phWidget = Text('Favorite pH: $pH',
        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return Column(
        children: children
            .map((child) => Padding(
                child: child, padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0)))
            .toList());
  }

  Widget showProfilePicture(FishData fishData) {
    return Image.network(
      fishData.profilePicture.toString(),
      fit: BoxFit.cover,
    );
  }
}
