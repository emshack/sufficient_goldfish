import 'package:firebase_functions_interop/firebase_functions_interop.dart' as interop;
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart' as fs;
import 'package:firebase/src/assets/assets.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  interop.functions['matchFish'] =
      interop.FirebaseFunctions.https.onRequest(matchFish);
}

void matchFish(interop.ExpressHttpRequest request) async {
  Set<String> nonMatches = request.uri.queryParametersAll['id'].toSet();

  fb.initializeApp(apiKey: "AIzaSyBH8u34jiFkYsM7SKRAwkRGG9qPET10OSA",
      authDomain: "sufficientgoldfish.firebaseapp.com",
      databaseURL: "https://sufficientgoldfish.firebaseio.com",
      projectId: "sufficientgoldfish",
      storageBucket: "sufficientgoldfish.appspot.com",
      messagingSenderId: "611138263249");
  fs.QuerySnapshot response = await fb.firestore().collection('profiles').get();
  List<fs.DocumentSnapshot> profiles = response.docs;

  fs.DocumentSnapshot match;
  bool foundMatch = false;

  while (profiles.length > 0 && !foundMatch) {
    int index = new Random().nextInt(profiles.length);
    match = profiles[index];
    if (nonMatches.contains(match.id)) {
      profiles.remove(index);
    } else {
      foundMatch = true;
    }
  }

  request.response.writeln('hello!');
  request.response.writeln(json.encode(match != null ? match.data : {}));

  request.response.close();
}
