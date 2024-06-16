import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> createDiary(String feeling, String description) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('diaries').add({
        'feeling': feeling,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid, // Add user ID
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _db
          .collection('diaries')
          .where('userId', isEqualTo: user.uid) // Filter by user ID
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();
    }
    return [];
  }

  static Future<void> deleteDiary(String id) async {
    await _db.collection('diaries').doc(id).delete();
  }

  static Future<void> updateDiary(String id, String feeling, String description) async {
    await _db.collection('diaries').doc(id).update({
      'feeling': feeling,
      'description': description,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
