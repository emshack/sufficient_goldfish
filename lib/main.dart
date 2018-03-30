import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// TODO: Better populate these
const double targetLatitude = 37.785844;
const double targetLongitude = -122.406427;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Plenty of Goldfish',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ProfilePage(),
    );
  }
}

enum Field { name, favoriteMusic, phValue, profilePicture }

// we may decide not to do this part since a close variant is shown in our other talk.
class _ProfilePageState extends State<ProfilePage> {
  File _imageFile;
  DocumentReference _profile;
  DocumentSnapshot _details;
  bool _editing;

  @override
  void initState() {
    super.initState();
    _profile = Firestore.instance.collection('profiles').document();
    _editing = false;
  }

  getImage() async {
    var imageFile = await ImagePicker.pickImage();
    var random = new Random().nextInt(10000);
    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
    var uploadTask = ref.put(imageFile);
    var downloadUrl = (await uploadTask.future).downloadUrl;
    _profile.setData({Field.profilePicture.toString(): downloadUrl}, SetOptions.merge);
    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<Null> _updateProfile(Field field, value) async {
    _profile.setData({field.toString(): value}, SetOptions.merge);
  }

  Widget _showProfilePicture() {
    Image image = _imageFile == null
        ? new Image.asset('assets/longhorn-cowfish.jpg')
        : new Image.file(_imageFile);
    if (_editing) {
      return new Stack(
        children: [
          new Container(
            child: image,
            foregroundDecoration: new BoxDecoration(color: new Color.fromRGBO(200, 200, 200, 0.5)),
          ),
          new IconButton(
            iconSize: 50.0,
            onPressed: getImage,
            tooltip: 'Pick Image',
            icon: new Icon(Icons.add_a_photo),
          ),
        ],
        alignment: new Alignment(0.0, 0.0),
      );
    } else {
      return image;
    }
  }

  Widget _showData(Field field) {
    String label;
    String defaultValue;
    // TODO: Update when we have actual values to populate this with
    String currentValue;
    switch (field) {
      case Field.name:
        label = 'Name';
        defaultValue = 'Goldie';
        break;
      case Field.favoriteMusic:
        label = 'Favorite Music';
        defaultValue = 'Blubstep';
        break;
      case Field.phValue:
        label = 'Favorite pH level';
        defaultValue = '5';
        break;
      default:
        break;
    }
    if (_editing) {
      return  new TextFormField(
        decoration: new InputDecoration(labelText: label),
        onFieldSubmitted: (submitted) =>
            _updateProfile(field, submitted),
        initialValue: currentValue ?? defaultValue,
      );
    } else {
      return new Text('$label: ${currentValue ?? defaultValue}');
    }
  }

  // TODO(efortuna): Maybe do something prettier here with StreamBuilder like the cloud firestore example.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      floatingActionButton: new IconButton(
        onPressed: () {
          setState(() {
            _editing = !_editing;
          });
        },
        tooltip: _editing ? 'Edit Profile' : 'Save Changes',
        icon: new Icon(_editing ? Icons.check : Icons.edit),
      ),
      body: new ListView(
      children: <Widget>[
        _showProfilePicture(),
        _showData(Field.name),
        _showData(Field.favoriteMusic),
        _showData(Field.phValue),
        new Center(
            child: new RaisedButton(
                onPressed: matchFish,
                child: new Text("Find your fish!"))),
      ],
    ));
  }

  matchFish() {
    http.get('https://us-central1-sufficientgoldfish.cloudfunctions.net/helloWorld')
        .then((fileContents) {
          print('contents ${fileContents.body}');
    });
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new FinderPage(targetLatitude, targetLongitude);
        }));
  }
}

class ProfilePage extends StatefulWidget {
  _ProfilePageState createState() => new _ProfilePageState();
}

typedef void LocationCallback(Map<String, double> location);

class LocationTools {
  final Location location = new Location();

  Future<Map<String, double>> getLocation() {
    return location.getLocation;
  }

  void initListener(LocationCallback callback) {
    location.onLocationChanged.listen((Map<String, double> currentLocation) {
      callback(currentLocation);
    });
  }
}

class FinderPage extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;

  FinderPage(this.targetLatitude, this.targetLongitude);

  @override
  _FinderPageState createState() => new _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  LocationTools locationTools;
  double latitude = 0.0;
  double longitude = 0.0;
  double accuracy = 0.0;

  final searchingAudio =
      'https://freesound.org/data/previews/28/28693_98464-lq.mp3';
  final foundAudio =
      'https://freesound.org/data/previews/397/397354_4284968-lq.mp3';

  AudioPlayer audioPlayer = new AudioPlayer();

  void _initAudio(String loopFile) {
    // restart audio if it has finished
    audioPlayer.setCompletionHandler(() {
      audioPlayer.play(loopFile);
    });
    // restart audio if it has been playing for at least 3 seconds
    audioPlayer.setPositionHandler((Duration d) {
      if (d.inSeconds > 3) {
        _playNewAudio(loopFile);
      }
    });
    audioPlayer.play(loopFile);
  }

  void _playNewAudio(String audioFile) {
    audioPlayer.stop().then((result) {
      audioPlayer.play(audioFile);
    });
  }

  _FinderPageState() {
    locationTools = new LocationTools();
    locationTools.getLocation().then((Map<String, double> currentLocation) {
      _updateLocation(currentLocation);
    });
    locationTools.initListener(_updateLocation);
    _initAudio(searchingAudio);
  }

  void _updateLocation(Map<String, double> currentLocation) {
    setState(() {
      latitude = currentLocation["latitude"];
      longitude = currentLocation["longitude"];
      accuracy = currentLocation["accuracy"];
    });
  }

  double _getLocationDiff() {
    int milesBetweenLines = 69;
    int feetInMile = 5280;
    int desiredFeetRange = 15;
    double multiplier = 2 * milesBetweenLines * feetInMile / desiredFeetRange;
    double latitudeDiff = (latitude - widget.targetLatitude).abs() * multiplier;
    double longitudeDiff =
        (longitude - widget.targetLongitude).abs() * multiplier;
    if (latitudeDiff > 1) {
      latitudeDiff = 1.0;
    }
    if (longitudeDiff > 1) {
      longitudeDiff = 1.0;
    }
    double diff = (latitudeDiff + longitudeDiff) / 2;
    if (diff < 0.1) {
      _playNewAudio(foundAudio);
    }
    return diff;
  }

  Color _colorFromLocationDiff() {
    return Color.lerp(Colors.red, Colors.blue, _getLocationDiff());
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Find your fish!"),
        ),
        body: new Container(
          color: _colorFromLocationDiff(),
          child: new Center(
            child: new Image.asset('assets/location_ping.gif'),
          ),
        ));
  }
}
