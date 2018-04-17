import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: new ThemeData.light(), // switch to ThemeData.day() when available
      home: new FishPage(PageType.shopping),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum PageType { shopping, reserved }

class FishPage extends StatefulWidget {
  final PageType pageType;

  FishPage(this.pageType);

  @override
  State<FishPage> createState() => new FishPageState();
}

class FishPageState extends State<FishPage> {
  DocumentReference _myProfile;
  List<FishData> _fishList;
  Set<String> _rejectedFish;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _fishList = [];
    _rejectedFish = new Set<String>();
    _myProfile = Firestore.instance.collection('profiles').document();
    fetchFishData();
  }

  fetchFishData() {
    // TODO: Pull down reserved fish if widget.pageType == PageType.reserved
    // and pull down list of available fish if widget.pageType == PageType.shopping
    String query = _rejectedFish.join('&id=');
    http.get(cloudFunctionUrl + query).then((response) {
      var suggestedMatches = json.decode(response.body);
      setState(() {
        _fishList = suggestedMatches
            .map<FishData>((fishData) => new FishData.parseResponse(fishData))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_fishList.isEmpty) {
      body = new Center(
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            new CircularProgressIndicator(),
            new Text('Gone Fishing...'),
          ]));
    } else {
      body = new CoverFlow(widgetBuilder, dismissedCallback: disposeDismissed);
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.pageType == PageType.shopping
            ? 'Sufficient Goldfish'
            : 'Your Reserved Fish'),
      ),
      body: body,
      floatingActionButton: widget.pageType == PageType.shopping
          ? new FloatingActionButton.extended(
              icon: new Icon(Icons.shopping_cart),
              label: new Text("Reserved"),
              onPressed: () {
                Navigator.of(context).push(new MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                  return new FishPage(PageType.reserved);
                }));
              })
          : null,
    );
  }

  Widget widgetBuilder(BuildContext context, int index) {
    if (_fishList.length == 0) {
      return new Center(
          child: new Text('There are plenty of fish in the sea...'));
    } else {
      return new ProfileCard(_fishList[index % _fishList.length]);
    }
  }

  disposeDismissed(int card, DismissDirection direction) {
    _fishList.removeAt(card % _fishList.length);
    // TODO: If widget.pageType == PageType.reserved, write this fish back to
    // the list of available fish in Firebase
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;

  ProfileCard(this.data);

  @override
  Widget build(BuildContext context) {
    return new Card(
        child: new Container(
      padding: new EdgeInsets.all(16.0),
      child: new Column(children: <Widget>[
        new Expanded(flex: 1, child: showProfilePicture(data)),
        _showData(data.name, data.favoriteMusic, data.favoritePh),
        new RaisedButton.icon(
            color: Colors.green,
            icon: new Icon(Icons.check),
            label: new Text('Save'),
            onPressed: () {
              //TODO
            }),
      ]),
    ));
  }

  Widget _showData(String name, String music, String pH) {
    Text nameWidget = new Text(name,
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0));
    Text musicWidget = new Text('Favorite music: $music',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    Text phWidget = new Text('Favorite pH: $pH',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return new Column(
        children: children
            .map((child) =>
                new Padding(child: child, padding: new EdgeInsets.all(8.0)))
            .toList());
  }

  Widget showProfilePicture(FishData fishData) {
    return new Image.network(
      fishData.profilePicture.toString(),
      fit: BoxFit.cover,
    );
  }
}
