import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:sensors/sensors.dart';
import 'package:transparent_image/transparent_image.dart';

import 'utils.dart';

const backgroundAudio = 'background.mp3';
const removedAudio = 'removed.mp3';

var audioTools = LocalAudioTools();
FirebaseUser user;

main() async {
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
    return StreamBuilder(
        stream: Firestore.instance.collection('profiles').snapshots,
        builder: (_, AsyncSnapshot<QuerySnapshot> snapshot) {
          var documents = snapshot.data?.documents ?? [];
          var fish = documents
              .map((snapshot) => FishData.from(snapshot))
              .toList();
          return FishPage(fish);
        });
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
  ViewType _viewType = ViewType.available;

  @override
  Widget build(BuildContext context) {
    var filteredFish = widget.allFish;
    return Scaffold(
      appBar: AppBar(
        title: Text(_viewType == ViewType.available
            ? 'Sufficient Goldfish'
            : 'Your Reserved Fish'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _viewType == ViewType.available ? 0 : 1,
        onTap: (int index) {
          setState(() {
            _viewType = index == 0 ? ViewType.available : ViewType.reserved;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              title: Text('Available'), icon: Icon(Icons.home)),
          BottomNavigationBarItem(
              title: Text('Reserved'), icon: Icon(Icons.shopping_basket)),
        ],
      ),
      body: Container(
          color: Colors.indigo[900],
          child:
              FishOptions(filteredFish, _viewType, _reserveFish, _removeFish)),
    );
  }

  void _reserveFish(FishData fishOfInterest) {
    fishOfInterest.reservedBy = user.uid;
    fishOfInterest.save();
  }

  void _removeFish(FishData fishOfInterest) {
    fishOfInterest.reservedBy = null;
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
    var fishOfInterest = fish.isEmpty ? FishData.data(null) : fish[0];
    return ProfileCard(
      fishOfInterest,
      viewType,
      () => onAddedCallback(fishOfInterest),
      () => onRemovedCallback(fishOfInterest),
      fishOfInterest.reservedBy == user.uid,
    );
  }

  onDismissed(int index) {}
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
    return Card(child: _getCardContents());
  }

  Widget _getCardContents() {
    var contents = [
      Expanded(child: _showProfilePicture(data)),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    var children = _wrapInScrimAndExpand(Column(children: contents));
    if (viewType == ViewType.available) {
      children.add(Row(children: [
        Expanded(
            child: FlatButton(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          color: isReserved ? Colors.red : Colors.green,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(isReserved ? Icons.not_interested : Icons.check),
            Text(isReserved ? 'Release' : 'Catch',
                style: TextStyle(fontSize: 16.0))
          ]),
          onPressed: () {
            isReserved ? onRemovedCallback() : onAddedCallback();
          },
        ))
      ]));
    }
    return Column(children: children);
  }

  Widget _showData(String name, String music, String pH) {
    var subHeadingStyle =
        TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
    var nameWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
        textAlign: TextAlign.center,
      ),
    );
    var musicWidget = Text('Favorite music: $music', style: subHeadingStyle);
    var phWidget = Padding(
        child: Text('Favorite pH: $pH', style: subHeadingStyle),
        padding: EdgeInsets.only(bottom: 16.0));
    return Column(children: [nameWidget, musicWidget, phWidget]);
  }

  Widget _showProfilePicture(FishData fishData) {
    return FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: fishData.profilePicture,
        fit: BoxFit.cover,
    );
  }

  List<Widget> _wrapInScrimAndExpand(Widget child) {
    if (isReserved && viewType == ViewType.available) {
      child = Container(
          foregroundDecoration:
              BoxDecoration(color: Color.fromARGB(150, 30, 30, 30)),
          child: child);
    }
    child = Expanded(child: Row(children: [Expanded(child: child)]));
    return [child];
  }
}
