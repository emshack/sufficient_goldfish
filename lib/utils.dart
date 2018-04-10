import 'package:flutter/material.dart';

enum Field {
  id, // unique id to separate candidates (the document id)
  name,
  favoriteMusic,
  phValue,
  profilePicture1, // the main profile picture
  profilePicture2,
  profilePicture3,
  profilePicture4,
  lastSeenLatitude,
  lastSeenLongitude
}

class MatchData {
  String id;
  Uri profilePicture1, profilePicture2, profilePicture3, profilePicture4;
  String name;
  String favoriteMusic;
  String favoritePh;
  double targetLatitude;
  double targetLongitude;

  MatchData();

  MatchData.data(
      this.id,
      this.name,
      this.favoriteMusic,
      this.favoritePh,
      String profilePicture1,
      String profilePicture2,
      String profilePicture3,
      String profilePicture4,
      this.targetLatitude,
      this.targetLongitude) {
    this.name ??= 'Frank';
    this.favoriteMusic ??= 'Blubstep';
    this.favoritePh ??= '7.0';
    this.profilePicture1 =
        profilePicture1 == null ? null : Uri.parse(profilePicture1);
    this.profilePicture2 =
        profilePicture2 == null ? null : Uri.parse(profilePicture2);
    this.profilePicture3 =
        profilePicture3 == null ? null : Uri.parse(profilePicture3);
    this.profilePicture4 =
        profilePicture4 == null ? null : Uri.parse(profilePicture4);
  }

  factory MatchData.parseResponse(Map<String, dynamic> response) =>
      MatchData.data(
          response[Field.id.toString()],
          response[Field.name.toString()],
          response[Field.favoriteMusic.toString()],
          response[Field.phValue.toString()],
          response[Field.profilePicture1.toString()],
          response[Field.profilePicture2.toString()],
          response[Field.profilePicture3.toString()],
          response[Field.profilePicture4.toString()],
          response[Field.lastSeenLatitude.toString()],
          response[Field.lastSeenLongitude.toString()]);

  Map<String, dynamic> serialize() {
    return {
      Field.id.toString(): id,
      Field.profilePicture1.toString(): profilePicture1.toString(),
      Field.profilePicture2.toString(): profilePicture2.toString(),
      Field.profilePicture3.toString(): profilePicture3.toString(),
      Field.profilePicture4.toString(): profilePicture4.toString(),
      Field.name.toString(): name,
      Field.favoriteMusic.toString(): favoriteMusic,
      Field.phValue.toString(): favoritePh,
      Field.lastSeenLatitude.toString(): targetLatitude,
      Field.lastSeenLongitude.toString(): targetLongitude
    };
  }

  setImageData(int imageNum, Uri uri) {
    // Yes this is really hacky and not how you would really do it.
    if (imageNum == 0) {
      profilePicture1 = uri;
    } else if (imageNum == 1) {
      profilePicture2 = uri;
    } else if (imageNum == 2) {
      profilePicture3 = uri;
    } else if (imageNum == 3) {
      profilePicture4 = uri;
    } else {
      print('invalid image position');
    }
  }

  Uri getImage(int imageNum) {
    // Yes this is terrible.
    if (imageNum == 0) {
      return profilePicture1;
    } else if (imageNum == 1) {
      return profilePicture2;
    } else if (imageNum == 2) {
      return profilePicture3;
    } else if (imageNum == 3) {
      return profilePicture4;
    } else {
      print('invalid image position');
    }
  }
}
