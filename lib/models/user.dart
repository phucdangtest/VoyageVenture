import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class User{
  String id, name, email, phone,password, latitude, longitude, lastlat, lastlong, lastup;
  List<String> friends;
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.latitude,
    required this.longitude,
    required this.lastlat,
    required this.lastlong,
    required this.lastup,
    required this.friends,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'phone': this.phone,
      'password': this.password,
      'latitude': this.latitude,
      'longitude': this.longitude,
      'lastlat': this.lastlat,
      'lastlong': this.lastlong,
      'lastup': this.lastup,
    };
  }
  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      password: map['password'] as String,
      latitude: map['latitude'] as String,
      longitude: map['longitude'] as String,
      lastlat: map['lastlat'] as String,
      lastlong: map['lastlong'] as String,
      lastup: map['lastup'] as String,
      friends: map['friends'] as List<String>,
    );
  }

}

// class UserSnapshot {
//   User User;
//   DocumentReference ref;
//
//   UserSnapshot({
//     required this.User,
//     required this.ref,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'User': this.User,
//       'ref': this.ref,
//     };
//   }
//
//   factory UserSnapshot.fromJson(DocumentSnapshot docSnap) {
//     return UserSnapshot(
//       User: User.fromJson(docSnap.data() as Map<String, dynamic>),
//       ref: docSnap.reference,
//     );
//   }
//   static Future<DocumentReference> add(User User) async {
//     return FirebaseFirestore.instance
//         .collection("Users")
//         .add(User.toJson());
//   }
//
//   Future<void> update(User User) async {
//     return ref.update(User.toJson());
//   }
//
//   static Stream<List<UserSnapshot>> getAll() {
//     Stream<QuerySnapshot> sqs =
//     FirebaseFirestore.instance.collection("Users").snapshots();
//     return sqs.map((qs) =>
//         qs.docs.map((docSnap) => UserSnapshot.fromJson(docSnap)).toList());
//   }
//
//   static Future<UserSnapshot> getUserByRef(DocumentReference ref) async {
//     DocumentSnapshot docSnap = await ref.get();
//     if (!docSnap.exists) {
//       throw Exception('Document does not exist');
//     }
//     return UserSnapshot.fromJson(docSnap);
//   }
// }

