import 'dart:async';
import 'dart:io';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';

enum Field {
  id, // unique id to separate candidates (the document id)
  name,
  favoriteMusic,
  phValue,
  profilePicture, // the main profile picture
  reservedBy,
}

class FishData {
  String id;
  String profilePicture;
  String name;
  String favoriteMusic;
  String favoritePh;
  List rejectedBy;
  String reservedBy;
  final String defaultImage =
      'https://firebasestorage.googleapis.com/v0/b/sufficientgoldfish.appspot.com/o/angelfish-silhouette.png?alt=media&token=76663301-d3d5-4c49-a7ea-db1f163d5c06';
  final DocumentReference reference;

  factory FishData(String id) => FishData.data(id);

  FishData.data(this.id,
      [this.name,
      this.favoriteMusic,
      this.favoritePh,
      this.profilePicture,
      this.reservedBy,
      this.rejectedBy,
      this.reference]) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.name ??= 'Frank';
    this.favoriteMusic ??= 'Blubstep';
    this.favoritePh ??= '7.0';
    this.profilePicture ??= defaultImage;
    this.rejectedBy ??= [];
    this.rejectedBy = new List.from(rejectedBy);
  }

  factory FishData.parseData(DocumentSnapshot document) => FishData.data(
      document.reference.documentID,
      document.data[Field.name.toString()],
      document.data[Field.favoriteMusic.toString()],
      document.data[Field.phValue.toString()],
      document.data[Field.profilePicture.toString()],
      document.data[Field.reservedBy.toString()],
      document.data['rejectedBy'],
      document.reference);

  void save() {
    reference.setData(serialize());
  }

  Map<String, dynamic> serialize() {
    return {
      Field.id.toString(): id,
      Field.profilePicture.toString(): profilePicture.toString(),
      Field.name.toString(): name,
      Field.favoriteMusic.toString(): favoriteMusic,
      Field.phValue.toString(): favoritePh,
      Field.reservedBy.toString(): reservedBy,
      'reservedBy': reservedBy,
    };
  }

  addRejectedBy(String identifier) => rejectedBy.add(identifier);
}

class AudioTools {
  final AudioPlayer _audioPlayer;
  final Map<String, String> _nameToPath = {};

  AudioTools() : _audioPlayer = AudioPlayer();

  Future loadFile(String name) async {
    final bytes = await rootBundle.load('assets/$name');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(new Uint8List.view(bytes.buffer));
    if (await file.exists()) _nameToPath[name] = file.path;
  }

  void initAudioLoop(String name) {
    // restart audio if it has finished
    _audioPlayer.setCompletionHandler(() {
      playAudio(name);
    });
    playAudio(name);
  }

  Future<Null> playAudio(String name) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(_nameToPath[name], isLocal: true);
  }
}
