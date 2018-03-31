import 'package:firebase_functions_interop/firebase_functions_interop.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  functions['matchFish'] =
      FirebaseFunctions.https.onRequest(matchFish);
}

void matchFish(ExpressHttpRequest request) async {
  //Stream<QuerySnapshot> profiles = Firestore.instance.collection('profiles').snapshots;


  /*QuerySnapshot queryResult = await Firestore.instance.collection('profiles').getDocuments();
  List<DocumentSnapshot> profiles = queryResult.documents();
  DocumentSnapshot match = profiles[new Random().nextInt(profiles.length)];

  request.response.writeln(json.encode(match.data));*/

  //DocumentReference profiles = Firestore.instance.collection('profiles').document('index');

  request.response.writeln('body of request ${request.body}');
  request.response.writeln('uri of request ${request.uri}');
  request.response.writeln('requestedUri of request ${request.requestedUri}');
  request.response.close();
}
