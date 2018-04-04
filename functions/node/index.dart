import 'package:firebase_functions_interop/firebase_functions_interop.dart' as interop;
import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  interop.functions['matchFish'] =
      interop.FirebaseFunctions.https.onRequest(matchFish);
}

enum Field {
  name,
  favoriteMusic,
  phValue,
  profilePicture,
  lastSeenLatitude,
  lastSeenLongitude,
  id
}

void matchFish(interop.ExpressHttpRequest request) async {
  Set<String> nonMatches = request.uri.queryParametersAll['id'].toSet();

  final serviceAccountKeyFilename = 'node/sufficientgoldfish-firebase-adminsdk-hvu1h-0814254aaa.json';
  final admin = FirebaseAdmin.instance;
  final cert = admin.certFromPath(serviceAccountKeyFilename);
  final app = admin.initializeApp(new AppOptions(
    credential: cert,
    databaseURL: "https://sufficientgoldfish.firebaseio.com",
  ));


  QuerySnapshot response = await app.firestore().collection('profiles').get();
  List<DocumentSnapshot> profiles = response.documents;

  DocumentSnapshot match;
  bool foundMatch = false;
  request.response.writeln('docs size ${profiles.length} ${Field.values}');

  while (profiles.length > 0 && !foundMatch) {
    int index = new Random().nextInt(profiles.length);
    match = profiles[index];
    if (nonMatches.contains(match.documentID)) {
      profiles.remove(index);
    } else {
      foundMatch = true;
    }
  }

  request.response.writeln(json.encode(match != null ? match.data.toMap() : {}));

  request.response.close();
}
