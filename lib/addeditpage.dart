import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditPage extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existingDiary;
  final VoidCallback refreshDiaries;

  AddEditPage({this.id, this.existingDiary, required this.refreshDiaries});

  @override
  _AddEditPageState createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedFeeling = '';
  bool _isMoodSelected = false;
  List<bool> _moodSelections = List.filled(_feelings.length, false);

  @override
  void initState() {
    super.initState();
    if (widget.existingDiary != null) {
      _selectedFeeling = widget.existingDiary!['feeling'];
      _descriptionController.text = widget.existingDiary!['description'];
      _isMoodSelected = true;
      _moodSelections[_feelings.indexWhere((element) => element['feeling'] == _selectedFeeling)] = true;
    }
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
    // Save locally if user is not logged in
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> localDiaries = [];
    final String? localDiariesString = prefs.getString('localDiaries');
    if (localDiariesString != null) {
      final List<dynamic> decodedDiaries = jsonDecode(localDiariesString);
      localDiaries = decodedDiaries.cast<Map<String, dynamic>>().map((diary) {
        // Ensure 'createdAt' is parsed into DateTime
        return {
          ...diary,
          'createdAt': diary['createdAt'], // Keep it as String
        };
      }).toList();
    }
    if (widget.id != null) {
      localDiaries.removeWhere((diary) => diary['id'] == widget.id);
    }
    localDiaries.add(newDiary);
    final String encodedDiaries = jsonEncode(localDiaries);
    await prefs.setString('localDiaries', encodedDiaries);
  } else {
    // Save to Firebase if user is logged in
    if (widget.id == null) {
      await FirebaseHelper.createDiary(_selectedFeeling, _descriptionController.text);
    } else {
      await FirebaseHelper.updateDiary(widget.id!, _selectedFeeling, _descriptionController.text);
    }
  }

  widget.refreshDiaries();
  Navigator.pop(context);
}


  void _showFeelingIcons() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Select a Feeling'),
        content: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _feelings.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFeeling = _feelings[index]['feeling']!;
                  _isMoodSelected = true;
                  _moodSelections = List.filled(_feelings.length, false);
                  _moodSelections[index] = true;
                });
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  ColorFiltered(
                    colorFilter: _moodSelections[index]
                        ? ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : ColorFilter.mode(Colors.grey, BlendMode.saturation),
                    child: Image.asset(
                      _feelings[index]['gif']!,
                      width: 50,
                      height: 50,
                    ),
                  ),
                  Text(_feelings[index]['feeling']!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      appBar: AppBar(
        title: Text(
          widget.id == null ? 'New Entry' : 'Edit Entry',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30,),
              Text(
                "How Are You Feeling?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(height: 20),
              Container(
                height: 100, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _feelings.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding between items
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFeeling = _feelings[index]['feeling']!;
                            _isMoodSelected = true;
                            _moodSelections = List.filled(_feelings.length, false);
                            _moodSelections[index] = true;
                          });
                        },
                        child: Column(
                          children: [
                            Opacity(
                              opacity: _moodSelections[index] ? 1.0 : 0.5, // Adjust opacity here
                              child: Image.asset(
                                _feelings[index]['gif']!,
                                width: 50,
                                height: 50,
                              ),
                            ),
                            Text(
                              _feelings[index]['feeling']!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Let's Vent About It",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isMoodSelected ? null : () {},
                child: AbsorbPointer(
                  absorbing: !_isMoodSelected,
                  child: Stack(
                    children: [
                      TextField(
                        controller: _descriptionController,
                        enabled: _isMoodSelected,
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        minLines: 5, // Minimum number of lines for the text field
                        maxLines: 20, // Maximum number of lines for the text field
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 190),
              ElevatedButton(
                onPressed: () async {
                  await _saveDiary();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(125, 40, 253, 1), // Button background color
                ),
                child: Text(
                  widget.id == null ? 'Add Mood Log' : 'Update Mood Log',
                  style: TextStyle(color: Colors.white, fontSize: 15), // Button text color
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
  {'feeling': 'Other', 'gif': 'assets/unknown.gif'}
];
