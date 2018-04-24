import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'utils.dart';

// Old file -- should be ignored. Left here for ease of populating the firebase
// database, but will not stay in for I/O presentation.

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: new ThemeData.light(), // switch to ThemeData.day() when available
      home: new ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  _ProfilePageState createState() => new _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DocumentReference _profile;
  bool _editing;
  FishData _myData;
  bool _showFab;
  FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _profile = Firestore.instance.collection('profiles').document();
    _editing = false;
    _showFab = true;
    _focus = new FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus)
        setState(() => _showFab = false);
      else
        setState(() => _showFab = true);
    });
    _myData = new FishData.data(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('My Profile'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _showFab
            ? new FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _editing = !_editing;
                  });
                },
                tooltip: _editing ? 'Edit Profile' : 'Save Changes',
                child: new Icon(_editing ? Icons.check : Icons.edit),
              )
            : null,
        body: new SimpleProfile(_myData, _editing, _focus));
  }
}

class ProfilePicture extends StatefulWidget {
  final bool editing;
  final Uri _imageFile;
  final Function updateLocalValuesCallback;

  ProfilePicture(this.editing, this.updateLocalValuesCallback,
      [this._imageFile]);

  @override
  State<ProfilePicture> createState() => new _ProfilePictureState(_imageFile);
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uri _imageFile;
  _ProfilePictureState(this._imageFile);

  @override
  Widget build(BuildContext context) {
    var image = new Card(
        child: _imageFile == null
            ? new Image.asset('assets/fish-silhouette.png')
            : (_imageFile.toString().startsWith('http')
                ? new Image.network(_imageFile.toString(), fit: BoxFit.cover)
                : new Image.file(new File.fromUri(_imageFile),
                    fit: BoxFit.cover)));
    if (widget.editing) {
      return new Stack(
        children: [
          new Container(
            child: image,
            foregroundDecoration: new BoxDecoration(
                color: new Color.fromRGBO(200, 200, 200, 0.5)),
          ),
          new IconButton(
            iconSize: 50.0,
            onPressed: _getImage,
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

  _getImage() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = imageFile.uri;
    });
    await _uploadToStorage(imageFile);
  }

  Future<Null> _uploadToStorage(File imageFile) async {
    var random = new Random().nextInt(10000);
    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
    var uploadTask = ref.put(imageFile);
    var downloadUrl = (await uploadTask.future).downloadUrl;
    widget.updateLocalValuesCallback(downloadUrl);
  }
}

class SimpleProfile extends StatelessWidget {
  final FishData data;
  final bool editing;
  final FocusNode focus;

  SimpleProfile(this.data, this.editing, [this.focus]);

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: <Widget>[
      new Padding(
        padding: const EdgeInsets.all(8.0),
        child: scrollableProfilePictures(editing, data),
      ),
      new Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: new Column(
          children: <Widget>[
            _showData('Name', data.name, 'e.g. Frank', Icons.person, editing,
                focus, (changed) => data.name = changed),
            _showData(
                'Favorite Music',
                data.favoriteMusic,
                'e.g. Blubstep',
                Icons.music_note,
                editing,
                focus,
                (changed) => data.favoriteMusic = changed),
            _showData(
                'Favorite pH level',
                data.favoritePh,
                'e.g. 5',
                Icons.beach_access,
                editing,
                focus,
                (changed) => data.favoritePh = changed),
          ],
        ),
      ),
    ]);
  }

  Widget _showData(String label, String text, String hintText,
      IconData iconData, bool editing, FocusNode focus, Function onChanged) {
    return new Padding(
      padding: new EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 8.0),
      child: new TextField(
        decoration: new InputDecoration(
            labelText: label,
            icon: new Icon(iconData),
            hintText: hintText,
            border: editing ? const OutlineInputBorder() : InputBorder.none),
        onSubmitted: onChanged,
        focusNode: focus,
        enabled: editing,
        controller: new TextEditingController(text: text),
      ),
    );
  }

  Widget scrollableProfilePictures(bool editable, FishData fishData) {
    return new ProfilePicture(editable,
        (value) => fishData.profilePicture = value, Uri.parse(fishData.profilePicture));
  }
}
