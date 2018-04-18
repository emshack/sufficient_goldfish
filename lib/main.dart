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
      home: FishPage(PageType.shopping, deviceId),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum PageType { shopping, reserved }

class FishPage extends StatefulWidget {
  final PageType pageType;
  final String deviceId;

  FishPage(this.pageType, this.deviceId);

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  bool _audioToolsReady = false;
  DocumentSnapshot _lastFish;

  FishPageState();

  @override
  void initState() {
    super.initState();
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
      body = Center(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            CircularProgressIndicator(),
            Text('Gone Fishing...'),
          ]));
    } else {
      body = StreamBuilder<List<DocumentSnapshot>>(
          stream: Firestore.instance
              .collection('profiles')
              .snapshots
              .map((QuerySnapshot snapshot) {
            if (widget.pageType == PageType.shopping) {
              // Filter out results that are already reserved.
              return snapshot.documents
                  .where((DocumentSnapshot aDoc) =>
                      !aDoc.data.containsKey('reservedBy') || aDoc.data['reservedBy'] == widget.deviceId)
                  .toList();
            } else {
              // TODO(efortuna): for responsiveness, consider building two
              // streams (one for the reserved and one for the shopping) and
              // just swap them out. (this would result in just one page and
              // eliminate Navigator.of though...)
              return snapshot.documents
                  .where((DocumentSnapshot aDoc) =>
                      aDoc.data['reservedBy'] == widget.deviceId)
                  .toList();
            }
          }),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            if (!snapshot.hasData || snapshot.data.length == 0)
              return Center(
                  child: const Text('There are plenty of fish in the sea...'));
            return CoverFlow((_, int index) {
              var fishOfInterest = snapshot.data[index % snapshot.data.length];
              var data = FishData.parse(fishOfInterest);
              return ProfileCard(
                  data, widget.pageType, () => _reserveFish(fishOfInterest));
            },
                viewportFraction: .85,
                dismissedCallback: (int card, DismissDirection direction) =>
                    onDismissed(card, direction, snapshot.data));
          });
      if (widget.pageType == PageType.shopping)
        audioTools.initAudioLoop(baseName);
    }

    return Scaffold(
      appBar: widget.pageType == PageType.shopping
          ? _getShoppingAppBar()
          : _getReservedAppBar(),
      body: body,
    );
  }

  AppBar _getShoppingAppBar() {
    return AppBar(
      title: Text('Sufficient Goldfish'),
      actions: <Widget>[
        FlatButton.icon(
            icon: Icon(Icons.shopping_cart),
            label: Text("2"), // TODO: Update with number in cart
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute<Null>(builder: (BuildContext context) {
                return FishPage(PageType.reserved, widget.deviceId);
              }));
            }),
      ],
    );
  }

  AppBar _getReservedAppBar() {
    return AppBar(
      title: Text('Your Reserved Fish'),
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
        .setData({'reservedBy': widget.deviceId}, SetOptions.merge);
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final PageType pageType;
  final Function onSavedCallback;

  ProfileCard(this.data, this.pageType, this.onSavedCallback);

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
    if (pageType == PageType.shopping) {
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
                child: child,
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0)))
            .toList());
  }

  Widget showProfilePicture(FishData fishData) {
    return Image.network(
      fishData.profilePicture.toString(),
      fit: BoxFit.cover,
    );
  }
}
