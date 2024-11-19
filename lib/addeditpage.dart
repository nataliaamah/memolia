import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditPage extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existingDiary;
  final VoidCallback refreshDiaries;

  const AddEditPage({super.key, this.id, this.existingDiary, required this.refreshDiaries});

  @override
  _AddEditPageState createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedFeeling = '';
  bool _isMoodSelected = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingDiary != null) {
      _selectedFeeling = widget.existingDiary!['feeling'];
      _descriptionController.text = widget.existingDiary!['description'];
      _charCount = _descriptionController.text.length;
      _isMoodSelected = true;
    }
    _descriptionController.addListener(() {
      setState(() {
        _charCount = _descriptionController.text.length;
      });
    });
  }

  Future<void> _saveDiary() async {
    final DateTime now = DateTime.now();
    final String createdAt = now.toIso8601String();

    final newDiary = {
      'id': widget.id ?? now.toString(),
      'feeling': _selectedFeeling,
      'description': _descriptionController.text,
      'createdAt': createdAt,
    };

    if (FirebaseAuth.instance.currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> localDiaries = [];
      final String? localDiariesString = prefs.getString('localDiaries');
      if (localDiariesString != null) {
        final List<dynamic> decodedDiaries = jsonDecode(localDiariesString);
        localDiaries = decodedDiaries.cast<Map<String, dynamic>>();
      }
      if (widget.id != null) {
        localDiaries.removeWhere((diary) => diary['id'] == widget.id);
      }
      localDiaries.add(newDiary);
      final String encodedDiaries = jsonEncode(localDiaries);
      await prefs.setString('localDiaries', encodedDiaries);
    } else {
      if (widget.id == null) {
        // Creating a new diary
        await FirebaseHelper.createDiary(_selectedFeeling, _descriptionController.text);
      } else {
        // Updating an existing diary
        await FirebaseHelper.updateDiary(
          widget.id!,                 // Diary ID
          _selectedFeeling,           // Feeling
          _descriptionController.text // Description
        );
      }
    }

    widget.refreshDiaries();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.id == null ? 'New Entry' : 'Edit Entry'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How Are You Feeling?",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                  final isSelected = _selectedFeeling == feeling;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFeeling = feeling;
                        _isMoodSelected = true;
                      });
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
              const SizedBox(height: 30),
              const Text(
                "Write About It",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                // Removed maxLength to avoid built-in word counter
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Describe your mood...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$_charCount/500", // Single custom word counter
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isMoodSelected ? _saveDiary : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text(widget.id == null ? "Add Mood Log" : "Update Mood Log"),
                ),
              ),
            ],
          ),
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
