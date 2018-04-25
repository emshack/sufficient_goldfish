import 'dart:async';
import 'dart:io';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';

class FishData {
  final DocumentReference reference;
  String name;
  String favoriteMusic;
  String favoritePh;
  String profilePicture;
  String reservedBy;
  final String defaultImage =
      'https://firebasestorage.googleapis.com/v0/b/sufficientgoldfish.appspot.com/o/angelfish-silhouette.png?alt=media&token=76663301-d3d5-4c49-a7ea-db1f163d5c06';

  FishData.data(this.reference,
      [this.name,
      this.favoriteMusic,
      this.favoritePh,
      this.profilePicture,
      this.reservedBy]) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.name ??= 'Frank';
    this.favoriteMusic ??= 'Blubstep';
    this.favoritePh ??= '7.0';
    this.profilePicture ??= defaultImage;
  }

  factory FishData.parseData(DocumentSnapshot document) => FishData.data(
      document.reference,
      document.data['name'],
      document.data['favoriteMusic'],
      document.data['phValue'],
      document.data['profilePicture'],
      document.data['reservedBy']);

  void save() {
    reference.setData(serialize());
  }

  Map<String, dynamic> serialize() {
    return {
      'name': name,
      'favoriteMusic': favoriteMusic,
      'phValue': favoritePh,
      'profilePicture': profilePicture,
      'reservedBy': reservedBy,
    };
  }
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

  void initAudioLoop(String name) {}

  Future<Null> playAudio(String name) async {}
}
