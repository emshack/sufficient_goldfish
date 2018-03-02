import 'package:flutter/material.dart';
import 'package:location/location.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new LocationWidget()
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: null,
        tooltip: 'This button does nothing',
        child: new Icon(Icons.update),
      ),
    );
  }
}

class LocationWidget extends StatefulWidget {
  final Location location = new Location();

  @override
  _LocationWidgetState createState() => new _LocationWidgetState(location);
}

class _LocationWidgetState extends State<LocationWidget> {
  Location location;
  double latitude;
  double longitude;
  double accuracy;
  double altitude;

  _LocationWidgetState(this.location) {
    _oneTimeRefreshLocation();
    _initListener();
  }

  void _oneTimeRefreshLocation() {
    location.getLocation.then((Map<String,double> currentLocation) {
      _updateLocation(currentLocation);
    });
  }

  void _initListener() {
    location.onLocationChanged.listen((Map<String,double> currentLocation) {
      _updateLocation(currentLocation);
    });
  }

  void _updateLocation(Map<String,double> currentLocation) {
    setState(() {
      latitude = currentLocation["latitude"];
      longitude = currentLocation["longitude"];
      accuracy = currentLocation["accuracy"];
      altitude = currentLocation["altitude"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Text(
          'Your location is:',
        ),
        new Text(
          'Latitude: $latitude',
          style: Theme.of(context).textTheme.display1,
        ),
        new Text(
          'Longitude: $longitude',
          style: Theme.of(context).textTheme.display1,
        ),
        new Text(
          'Accuracy: $accuracy',
          style: Theme.of(context).textTheme.display1,
        ),
        new Text(
          'Altitude: $altitude',
          style: Theme.of(context).textTheme.display1,
        ),
      ],
    );
  }
}