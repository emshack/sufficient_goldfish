import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as interop;
import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  interop.functions['matchFish'] =
      interop.FirebaseFunctions.https.onRequest(matchFish);
}

/// Responds to an HTTP request for matches. Profiles that should not be
/// considered are passed in as "id" variables to the request. Returns a list of
/// potential matches, ordered from best match to least likely match.
void matchFish(interop.ExpressHttpRequest request) async {
  Set<String> nonMatches = request.uri.queryParametersAll['id'].toSet();

  final serviceAccountKeyFilename =
      'node/sufficientgoldfish-firebase-adminsdk-hvu1h-0814254aaa.json';
  final admin = FirebaseAdmin.instance;
  final cert = admin.certFromPath(serviceAccountKeyFilename);
  final app = admin.initializeApp(new AppOptions(
    credential: cert,
    databaseURL: "https://sufficientgoldfish.firebaseio.com"));

  QuerySnapshot response = await app.firestore().collection('profiles').get();
  List<DocumentSnapshot> profiles = response.documents;

  // Remove nonmatches.
  profiles = profiles.where((DocumentSnapshot snapshot) => !nonMatches.contains(snapshot.documentID)).toList();

  // SUPER SECRET MATCH SELECTION ALGORITHM!
  profiles.shuffle(new Random());

  request.response.writeln(json.encode(profiles.map(
          (DocumentSnapshot snapshot) => snapshot.data.toMap()).toList()));

  request.response.close();
}
