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
const reservedBy = 'reservedBy';

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
  DocumentSnapshot _undoData;
  List<DocumentSnapshot> _availableFish;
  List<DocumentSnapshot> _reservedFish;
  ViewType _viewType = ViewType.available;

  @override
  void initState() {
    super.initState();
    populateAudioTools();
    _createStream(ViewType.available).listen((data) {
      setState(() => _availableFish = data);
    });
    _createStream(ViewType.reserved).listen((data) {
      setState(() => _reservedFish = data);
    });
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.y.abs() >= 20 && _undoData != null) {
        // Shake-to-undo last action.
        if (_viewType == ViewType.available) {
          _removeFish(_undoData);
        } else {
          _reserveFish(_undoData);
        }
        _undoData = null;
      }
    });
  }

  Future<Null> populateAudioTools() async {
    await audioTools.loadFile(baseAudio, baseName);
    await audioTools.loadFile(dismissedAudio, dismissedName);
    await audioTools.loadFile(savedAudio, savedName);
    setState(() => _audioToolsReady = true);
  }

  Stream<List<DocumentSnapshot>> _createStream(ViewType viewType) {
    return Firestore.instance.collection('profiles').snapshots.map(
        (QuerySnapshot snapshot) =>
            snapshot.documents.where((DocumentSnapshot aDoc) {
              if (viewType == ViewType.available) {
                return aDoc.data[reservedBy] == widget.deviceId ||
                    !aDoc.data.containsKey(reservedBy);
              } else {
                return aDoc.data[reservedBy] == widget.deviceId;
              }
            }).toList());
  }

  Widget _displayFish() {
    List<DocumentSnapshot> fishList =
        _viewType == ViewType.available ? _availableFish : _reservedFish;
    if (fishList == null || fishList.length == 0)
      return Center(
          child: const Text('There are plenty of fish in the sea...'));
    return CoverFlow(
        itemBuilder: (_, int index) {
          var fishOfInterest = fishList[index];
          var isReserved = fishOfInterest.data[reservedBy] == widget.deviceId;
          return ProfileCard(
              FishData.parseData(fishOfInterest),
              _viewType,
              () => _reserveFish(fishOfInterest),
              () => _removeFish(fishOfInterest),
              isReserved);
        },
        dismissedCallback: (int card, DismissDirection direction) =>
            onDismissed(card, direction, fishList),
        itemCount: fishList.length);
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
            onPressed: () => setState(() => _viewType = ViewType.available),
          ),
          title: Text(_viewType == ViewType.available
              ? 'Sufficient Goldfish'
              : 'Saved Fish'),
          backgroundColor: Colors.indigo,
          actions: <Widget>[
            FlatButton.icon(
              icon: Icon(Icons.shopping_basket),
              label: Text(_reservedFish?.length.toString()),
              textColor: Colors.white,
              onPressed: () => setState(() => _viewType = ViewType.reserved),
            )
          ],
        ),
        body: Container(
            decoration: new BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    colors: [Colors.blue, Colors.lightBlueAccent])),
            child: body));
  }

  onDismissed(int card, _, List<DocumentSnapshot> allFish) {
    audioTools.playAudio(dismissedName);
    DocumentSnapshot fishOfInterest = allFish[card];
    if (_viewType == ViewType.reserved) {
      // Write this fish back to the list of available fish in Firebase.
      _removeFish(fishOfInterest);
    }
    _undoData = fishOfInterest;
  }

  void _removeFish(DocumentSnapshot fishOfInterest) {
    var existingData = fishOfInterest.data;
    existingData.remove(reservedBy);
    fishOfInterest.reference.setData(existingData);
  }

  void _reserveFish(DocumentSnapshot fishOfInterest) {
    var fishData = fishOfInterest.data;
    fishData[reservedBy] = widget.deviceId;
    fishOfInterest.reference.setData(fishData);
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
