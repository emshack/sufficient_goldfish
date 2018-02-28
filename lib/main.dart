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
  Location location = new Location();
  double latitude;
  double longitude;
  double accuracy;
  double altitude;

  _MyHomePageState() {
    _updateLocation();
  }

  void _updateLocation() {
    location.getLocation.then((Map<String, double> currentLocation) {
      setState(() {
        latitude = currentLocation["latitude"];
        longitude = currentLocation["longitude"];
        accuracy = currentLocation["accuracy"];
        altitude = currentLocation["altitude"];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
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
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _updateLocation,
        tooltip: 'Update Location',
        child: new Icon(Icons.update),
      ),
    );
  }
}
