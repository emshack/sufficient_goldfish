import 'package:location/location.dart';
import 'package:audioplayer/audioplayer.dart';

import 'dart:async';

enum Field {
  id, // unique id to separate candidates (the document id)
  name,
  favoriteMusic,
  phValue,
  profilePicture, // the main profile picture
  lastSeenLatitude,
  lastSeenLongitude
}

class MatchData {
  String id;
  Uri profilePicture;
  String name;
  String favoriteMusic;
  String favoritePh;
  double targetLatitude;
  double targetLongitude;
  final String defaultImage =
      'https://firebasestorage.googleapis.com/v0/b/sufficientgoldfish.appspot.com/o/fish-silhouette.png?alt=media&token=27fed5f3-9a70-4355-a3d7-7ec378c40acd';

  factory MatchData(String id) => new MatchData.data(id);

  MatchData.data(this.id,
      [this.name,
      this.favoriteMusic,
      this.favoritePh,
      String profilePicture1,
      this.targetLatitude,
      this.targetLongitude]) {
    this.name ??= 'Frank';
    this.favoriteMusic ??= 'Blubstep';
    this.favoritePh ??= '7.0';
    this.profilePicture =
        Uri.parse(profilePicture1 == null ? defaultImage : profilePicture1);
  }

  factory MatchData.parseResponse(Map<String, dynamic> response) =>
      MatchData.data(
          response[Field.id.toString()],
          response[Field.name.toString()],
          response[Field.favoriteMusic.toString()],
          response[Field.phValue.toString()],
          response[Field.profilePicture.toString()],
          response[Field.lastSeenLatitude.toString()],
          response[Field.lastSeenLongitude.toString()]);

  Map<String, dynamic> serialize() {
    return {
      Field.id.toString(): id,
      Field.profilePicture.toString(): profilePicture.toString(),
      Field.name.toString(): name,
      Field.favoriteMusic.toString(): favoriteMusic,
      Field.phValue.toString(): favoritePh,
      Field.lastSeenLatitude.toString(): targetLatitude,
      Field.lastSeenLongitude.toString(): targetLongitude
    };
  }
}

typedef void LocationCallback(Map<String, double> location);

class LocationTools {
  final Location location = new Location();

  Future<Map<String, double>> getLocation() {
    return location.getLocation;
  }

  void initListener(LocationCallback callback) {
    location.onLocationChanged.listen((Map<String, double> currentLocation) {
      callback(currentLocation);
    });
  }
}

class AudioTools {
  final AudioPlayer _audioPlayer;

  AudioTools() : _audioPlayer = new AudioPlayer();

  void initAudioLoop(String audioFile) {
    // restart audio if it has finished
    _audioPlayer.setCompletionHandler(() {
      _audioPlayer.play(audioFile);
    });
    // restart audio if it has been playing for at least 3 seconds
    _audioPlayer.setPositionHandler((Duration d) {
      if (d.inSeconds > 3) {
        playNewAudio(audioFile);
      }
    });
    _audioPlayer.play(audioFile);
  }

  void playNewAudio(String audioFile) {
    _audioPlayer.stop().then((result) {
      _audioPlayer.play(audioFile);
    });
  }

  void stopAudio() {
    _audioPlayer.setCompletionHandler(() {});
    _audioPlayer.setPositionHandler((Duration d) {});
    _audioPlayer.stop();
  }
}
