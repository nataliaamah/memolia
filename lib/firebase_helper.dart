import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new diary entry with the feeling, description, and locked status
  static Future<void> createDiary(String feeling, String description, bool isLocked) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('diaries').add({
        'feeling': feeling,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid, // Add user ID
        'locked': isLocked, // Store lock status
      });
    }
  }

  // Get all diaries for the current user, including locked status
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _db
          .collection('diaries')
          .where('userId', isEqualTo: user.uid) // Filter by user ID
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic> // Include locked status in the data
      }).toList();
    }
    return [];
  }

  // Delete a diary entry by its ID
  static Future<void> deleteDiary(String id) async {
    await _db.collection('diaries').doc(id).delete();
  }

  // Update an existing diary entry, including the locked status
  static Future<void> updateDiary(String id, String feeling, String description, bool isLocked) async {
    await _db.collection('diaries').doc(id).update({
      'feeling': feeling,
      'description': description,
      'updatedAt': DateTime.now().toIso8601String(),
      'locked': isLocked, // Update the lock status
    });
  }
}
