import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';

enum Field {
  id, // unique id to separate candidates (the document id)
  name,
  favoriteMusic,
  phValue,
  profilePicture, // the main profile picture
}

class FishData {
  String id;
  Uri profilePicture;
  String name;
  String favoriteMusic;
  String favoritePh;
  final String defaultImage =
      'https://firebasestorage.googleapis.com/v0/b/sufficientgoldfish.appspot.com/o/angelfish-silhouette.png?alt=media&token=76663301-d3d5-4c49-a7ea-db1f163d5c06';

  factory FishData(String id) => new FishData.data(id);

  FishData.data(this.id,
      [this.name,
      this.favoriteMusic,
      this.favoritePh,
      String profilePicture1]) {
    this.name ??= 'Frank';
    this.favoriteMusic ??= 'Blubstep';
    this.favoritePh ??= '7.0';
    this.profilePicture =
        Uri.parse(profilePicture1 == null ? defaultImage : profilePicture1);
  }

  factory FishData.parseResponse(Map<String, dynamic> response) =>
      FishData.data(
          response[Field.id.toString()],
          response[Field.name.toString()],
          response[Field.favoriteMusic.toString()],
          response[Field.phValue.toString()],
          response[Field.profilePicture.toString()]);

  Map<String, dynamic> serialize() {
    return {
      Field.id.toString(): id,
      Field.profilePicture.toString(): profilePicture.toString(),
      Field.name.toString(): name,
      Field.favoriteMusic.toString(): favoriteMusic,
      Field.phValue.toString(): favoritePh
    };
  }
}

class AudioTools {
  final AudioPlayer _audioPlayer;
  final Map<String, String> _nameToPath = {};

  AudioTools() : _audioPlayer = new AudioPlayer();

  Future loadFile(String url, String name) async {
    final bytes = await readBytes(url);
    final dir = await getApplicationDocumentsDirectory();
    final file = new File('${dir.path}/$name.mp3');

    await file.writeAsBytes(bytes);
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
