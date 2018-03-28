import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

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
      home: new MyProfilePage(),//_getProfileDoc),
    );
  }

  /*DocumentReference get _getProfileDoc => Firestore.instance
      .collection('profiles')
      .document('Frank'); // TODO(efortuna): Could use google sign in and get "name" from that.
      */
}

// TODO(efortuna): Potential Matches page to highlight the
// StreamBuilder/QuerySnapshot thing for cloudFirestore?

enum Field {
  name, favoriteMusic, phValue
}

class MyProfilePage extends StatelessWidget {
  //DocumentReference _profile;

  MyProfilePage();//this._profile);

  /*Future<Null> _updateProfile(Field field, value) async {
    _profile.updateData({field.toString() : value});
  }*/

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new ListView(children: <Widget>[
          new Image.asset('assets/longhorn-cowfish.jpg'),
          new Text('Name: Frank'),
          new Text('Favorite Music: BlubStep'),
          new TextFormField(decoration:
            new InputDecoration(labelText: 'Favorite pH level'),
            //onFieldSubmitted: (submitted) => _updateProfile(Field.phValue, submitted),
          ),
          new Center(
              child: new RaisedButton(
                  onPressed: () {
                    Navigator.of(context).push(new MaterialPageRoute<Null>(
                        builder: (BuildContext context) {
                          return new FinderPage(targetLatitude, targetLongitude);
                        }
                    ));
                  },
                  child: new Text("Find your fish!")
              )
          ),
        ],)
    );
  }
}

typedef void LocationCallback(Map<String, double> location);

class LocationTools {
  final Location location = new Location();

  Future<Map<String, double>> getLocation() {
    return location.getLocation;
  }

  void initListener(LocationCallback callback) {
    location.onLocationChanged.listen((Map<String,double> currentLocation) {
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

  _FinderPageState() {
    locationTools = new LocationTools();
    locationTools.getLocation().then((Map<String, double> currentLocation) {
      _updateLocation(currentLocation);
    });
    locationTools.initListener(_updateLocation);
  }

  void _updateLocation(Map<String,double> currentLocation) {
    setState(() {
      latitude = currentLocation["latitude"];
      longitude = currentLocation["longitude"];
      accuracy = currentLocation["accuracy"];
    });
  }

  Color _colorFromLocationDiff() {
    int milesBetweenLines = 69;
    int feetInMile = 5280;
    int desiredFeetRange = 15;
    double multiplier = 2 * milesBetweenLines * feetInMile / desiredFeetRange;
    double latitudeDiff = (latitude - widget.targetLatitude).abs() * multiplier;
    double longitudeDiff = (longitude - widget.targetLongitude).abs() * multiplier;
    print(latitude);
    print(longitude);
    if (latitudeDiff > 1) {
      latitudeDiff = 1.0;
    }
    if (longitudeDiff > 1) {
      longitudeDiff = 1.0;
    }
    double totalDiff = (latitudeDiff + longitudeDiff) / 2;
    return Color.lerp(Colors.red, Colors.blue, totalDiff);
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
        )
    );
  }
}