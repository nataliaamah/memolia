import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new diary entry with feeling, description, locked status, and optional image
  static Future<void> createDiary(
      String feeling,
      String description,
      bool isLocked,
      String? imageBase64 // Changed from File? to String?
      ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Initialize diary data
      Map<String, dynamic> diaryData = {
        'feeling': feeling,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'locked': isLocked,
      };

      // Add base64 encoded image to diary data if provided
      if (imageBase64 != null) {
        diaryData['imageBase64'] = imageBase64;
      }

      // Add diary to Firestore
      await _db.collection('diaries').add(diaryData);
    }
  }

  // Get all diaries for the current user, including images
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _db
          .collection('diaries')
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.map((doc) {
        // Convert document data to map
        Map<String, dynamic> diaryData = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        };

        return diaryData;
      }).toList();
    }
    return [];
  }

  // Update an existing diary entry, including image
  static Future<void> updateDiary(
      String id,
      String feeling,
      String description,
      bool isLocked,
      String? imageBase64 // Changed from File? to String?
      ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Prepare update data
      Map<String, dynamic> updateData = {
        'feeling': feeling,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
        'locked': isLocked,
      };

      // Add base64 encoded image to update data if provided
      if (imageBase64 != null) {
        updateData['imageBase64'] = imageBase64;
      }

      // Update the diary in Firestore
      await _db.collection('diaries').doc(id).update(updateData);
    }
  }

  // Delete a diary entry
  static Future<void> deleteDiary(String id) async {
    await _db.collection('diaries').doc(id).delete();
  }

  // Utility method to convert File to base64 (optional, but can be useful)
  static Future<String?> fileToBase64(File? file) async {
    if (file == null) return null;

    try {
      List<int> imageBytes = await file.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return null;
    }
  }
}