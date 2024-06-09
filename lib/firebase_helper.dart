import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> createDiary(String feeling, String? description) async {
    await _db.collection('diaries').add({
      'feeling': feeling,
      'description': description,
      'createdAt': Timestamp.now(),
    });
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    QuerySnapshot querySnapshot = await _db.collection('diaries').orderBy('createdAt').get();
    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      'feeling': doc['feeling'],
      'description': doc['description'],
      'createdAt': doc['createdAt'],
    }).toList();
  }

  static Future<void> updateDiary(String id, String feeling, String? description) async {
    await _db.collection('diaries').doc(id).update({
      'feeling': feeling,
      'description': description,
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> deleteDiary(String id) async {
    await _db.collection('diaries').doc(id).delete();
  }
}
