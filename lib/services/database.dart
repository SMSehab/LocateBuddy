import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinbo/model/buddy.dart';
import 'package:kinbo/model/user.dart';

class DatabaseService {
  final String ? uid;
  String ? query;

  DatabaseService({this.uid, this.query});

  // Instance of database collection
  final CollectionReference buddyCollection =
      FirebaseFirestore.instance.collection('buddies');

  //updates specific user data.
  Future updateUserData(
      {String ? uuid,
      String ? name,
      String ? bio,
      GeoPoint ? location,
      String ? time,
      List ? friends,
      String ? image}) async {
    return await buddyCollection.doc(uid).update({
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (time != null) 'time': time,
      if (image != null) 'image': image,
      if (uuid != null) 'uid': uuid,
      if (friends != null) 'friends': friends,
    });
  }

  // Sets new user data during registration
  Future setNewUserData(
      {String ? uuid,
      String ? name,
      String ? bio,
      GeoPoint ? location,
      String ? time,
      List ? friends,
      String ? image}) async {
    return await buddyCollection.doc(uid).set({
      'name': name,
      'bio': bio,
      'location': location,
      'time': time,
      'image': image,
      'uid': uuid,
      'friends': friends,
    });
  }

//
//--------------------------------------------------------------------
// Create list of Buddy model locally from snapshot.

  List<Buddy> _buddyListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Buddy(
        uid: doc.id,
        name: doc['name'] as String?,
        bio: doc['bio'] as String?,
        location: doc['location'] as GeoPoint?,
        time: doc['time'] as String?,
        image: doc['image'] as String?,
        friends: List.from(doc['friends'] ?? []),
      );
    }).toList();
  }


  // Stream to notify for only searched user's update.
  Stream<List<Buddy>> get buddySearch {
    return buddyCollection
        //.orderBy('bio')
        .where('name', isEqualTo: query ?? "")
        .snapshots()
        .map(_buddyListFromSnapshot);
  }

  // Stream to notify for ALL users' update from whole database.
  Stream<List<Buddy>> get buddies {
    return buddyCollection.snapshots().map(_buddyListFromSnapshot);
  }

//
//-------------------------------------------------------------
// Create UserData model locally
  UserData ? userDataFromSnapshot(DocumentSnapshot doc) {
    if (doc.exists) {
      return UserData(
        uid: doc.id,
        name: doc['name'] as String?,
        bio: doc['bio'] as String?,
        location: doc['location'] as GeoPoint?,
        image: doc['image'] as String?,
        time: doc['time'] as String?,
        friends: List.from(doc['friends'] ?? []),
      );
    } else {
      return null;
    }
  }


  // Stream for a specific user data.
  // Stream <UserData?> get userData {
  //   return buddyCollection.doc(uid).snapshots().map(userDataFromSnapshot);
  // }

  Stream<UserData> get userData {
    return buddyCollection
        .doc(uid)
        .snapshots()
        .map((doc) => userDataFromSnapshot(doc) ?? UserData());
  }

//
//--------------------------------------------------------------------
// Create Friend model locally from snapshot.
//   List<Friend?> _friendListFromSnapshot(QuerySnapshot snapshot) {
//     return snapshot.docs.map((doc) {
//       return Friend(
//               uid: doc.id,
//               name: doc['name'] ?? null,
//               bio: doc['bio'] ?? null,
//               location: doc['location'] ?? null,
//               time: doc['time'] ?? null,
//               image: doc['image'] ?? null,
//               friends: doc['friends']) ??
//           null;
//     }).toList();
//   }

  List<Friend> _friendListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      if (doc.data() == null) return null;

      return Friend(
        uid: doc.id,
        name: doc['name'] ?? '',
        bio: doc['bio'] ?? '',
        location: doc['location'] ?? '',
        time: doc['time'] ?? '',
        image: doc['image'] ?? '',
        friends: (doc['friends'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }).whereType<Friend>().toList();
  }



  // Stream to notify for only friends' update.
  // Stream<List<Friend?>> get friends {
  //   return buddyCollection
  //       .where('friends', arrayContainsAny: [this.uid])
  //       .snapshots()
  //       .map(_friendListFromSnapshot);
  // }

  Stream<List<Friend>> get friends {
    return buddyCollection
        .where('friends', arrayContainsAny: [this.uid])
        .snapshots()
        .map((snapshot) {
      return _friendListFromSnapshot(snapshot)
          .whereType<Friend>()
          .toList();
    });
  }



//
//----------------------------------------------------------------------
// Future method to initiate friends' marker icons.
  Future<List<Friend?>> buddyImages() {
    return buddyCollection
        .where('friends', arrayContainsAny: [this.uid])
        .get()
        .then(_friendListFromSnapshot);
  }
}
