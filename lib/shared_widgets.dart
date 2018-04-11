import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'utils.dart';

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
  MatchData data;
  bool editing;
  FocusNode focus;

  SimpleProfile(this.data, this.editing, [this.focus]);

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: <Widget>[
      scrollableProfilePictures(editing, data),
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
    return new TextField(
      decoration: new InputDecoration(
          labelText: label,
          icon: new Icon(iconData),
          hintText: hintText,
          border: editing? null : InputBorder.none),
      onSubmitted: onChanged,
      focusNode: focus,
      enabled: editing,
      controller: new TextEditingController(text: text),
    );
  }

  Widget scrollableProfilePictures(bool editable, MatchData matchData) {
    var tiles = new List.generate(
        4,
        (i) => new Expanded(
            flex: i == 0 ? 0 : 1,
            child: new ProfilePicture(
                editable,
                (value) => matchData.setImageData(i, value),
                matchData.getImage(i))));

    var mainImage = tiles.removeAt(0);
    return new Column(children: <Widget>[
      mainImage,
      new Row(children: tiles),
    ]);
  }
}
