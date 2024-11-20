import 'package:flutter/material.dart';
import 'dart:convert';
import 'firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddEditPage extends StatelessWidget {
  final String? id;
  final Map<String, dynamic>? existingDiary;
  final VoidCallback refreshDiaries;

  const AddEditPage({
    Key? key,
    this.id,
    this.existingDiary,
    required this.refreshDiaries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String selectedEmotion = existingDiary?['feeling'] ?? '';
    TextEditingController descriptionController = TextEditingController(
      text: existingDiary?['description'] ?? "",
    );

    void _saveDiary() async {
      final now = DateTime.now();
      final diary = {
        'id': id ?? now.toString(),
        'feeling': selectedEmotion,
        'description': descriptionController.text,
        'createdAt': now.toIso8601String(),
      };

      if (FirebaseAuth.instance.currentUser == null) {
        // Save locally
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> localDiaries = [];
        final String? localDiariesString = prefs.getString('localDiaries');
        if (localDiariesString != null) {
          localDiaries = (jsonDecode(localDiariesString) as List<dynamic>)
              .cast<Map<String, dynamic>>();
        }
        if (id != null) {
          localDiaries.removeWhere((diary) => diary['id'] == id);
        }
        localDiaries.add(diary);
        await prefs.setString('localDiaries', jsonEncode(localDiaries));
      } else {
        // Save to Firebase
        if (id == null) {
          await FirebaseHelper.createDiary(selectedEmotion, descriptionController.text);
        } else {
          await FirebaseHelper.updateDiary(id!, selectedEmotion, descriptionController.text);
        }
      }

      refreshDiaries();
      Navigator.pop(context);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for dragging
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.bookmark_border, color: Colors.white),
                Text(
                  existingDiary == null
                      ? "New Entry"
                      : "Edit Entry",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _saveDiary,
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Emotion Selector
            const Text(
              "How are you feeling?",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _feelings.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final feeling = _feelings[index]['feeling']!;
                final isSelected = selectedEmotion == feeling;
                return GestureDetector(
                  onTap: () {
                    selectedEmotion = feeling;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.transparent,
                        width: 2,
                      ),
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      _feelings[index]['gif']!,
                      width: 50,
                      height: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Input Field
            const Text(
              "Write About It",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: descriptionController,
                maxLines: null,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: "Start writing...",
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.brush, color: Colors.white),
                  onPressed: () {}, // Add brush functionality here
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.white),
                  onPressed: () {}, // Add image functionality here
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {}, // Add camera functionality here
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () {}, // Add mic functionality here
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const List<Map<String, String>> _feelings = [
  {'feeling': 'Happy', 'gif': 'assets/happy.gif'},
  {'feeling': 'Loved', 'gif': 'assets/loved.gif'},
  {'feeling': 'Excited', 'gif': 'assets/excited.gif'},
  {'feeling': 'Sad', 'gif': 'assets/sad.gif'},
  {'feeling': 'Tired', 'gif': 'assets/tired.gif'},
  {'feeling': 'Angry', 'gif': 'assets/angry.gif'},
  {'feeling': 'Annoyed', 'gif': 'assets/annoyed.gif'},
  {'feeling': 'Other', 'gif': 'assets/unknown.gif'},
];
