import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'custom_navigation_bar.dart';
import 'firebase_helper.dart'; // Adjust this import to match your file structure
import 'profile_page.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];
  bool _isLoading = true;
  String _filterOption = 'Today';
  DateTime? _selectedDate;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLocalStorageNotification());
      _loadLocalDiaries();
    } else {
      _refreshDiaries();
    }
  }

  Future<void> _loadLocalDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localDiaries = prefs.getString('localDiaries');
    if (localDiaries != null) {
      final List<dynamic> decodedDiaries = jsonDecode(localDiaries);
      setState(() {
        _diaries = decodedDiaries.cast<Map<String, dynamic>>().map((diary) {
          diary['createdAt'] = DateTime.parse(diary['createdAt']);
          return diary;
        }).toList();
        _filterDiaries('Today');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDiaries() async {
    if (user == null) {
      _loadLocalDiaries();
      return;
    }
    final data = await FirebaseHelper.getDiaries();
    setState(() {
      _diaries = data.map((diary) {
        diary['createdAt'] = DateTime.parse(diary['createdAt']);
        return diary;
      }).toList();
      _filterDiaries('Today');
      _isLoading = false;
    });
  }

  void _filterDiaries(String option) {
    setState(() {
      _filterOption = option;
      DateTime now = DateTime.now();
      if (option == 'Today') {
        _filteredDiaries = _diaries.where((diary) {
          return diary['createdAt'].day == now.day &&
              diary['createdAt'].month == now.month &&
              diary['createdAt'].year == now.year;
        }).toList();
      } else if (option == 'This Week') {
        _filteredDiaries = _diaries.where((diary) {
          return diary['createdAt'].isAfter(now.subtract(Duration(days: now.weekday))) &&
              diary['createdAt'].isBefore(now.add(Duration(days: DateTime.daysPerWeek - now.weekday)));
        }).toList();
      } else if (option == 'Select Date' && _selectedDate != null) {
        _filteredDiaries = _diaries.where((diary) {
          return diary['createdAt'].day == _selectedDate!.day &&
              diary['createdAt'].month == _selectedDate!.month &&
              diary['createdAt'].year == _selectedDate!.year;
        }).toList();
      } else {
        _filteredDiaries = _diaries;
      }
    });
  }

  void _showLocalStorageNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notice'),
        content: const Text('Without logging in, your logs will only be saved on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showAddEditModal({Map<String, dynamic>? existingDiary}) {
  String selectedEmotion = existingDiary?['feeling'] ?? '';
  TextEditingController descriptionController = TextEditingController(
    text: existingDiary?['description'] ?? "",
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter modalSetState) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.bookmark_border, color: Colors.white),
                        Text(
                          existingDiary == null ? "New Entry" : "Edit Entry",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _saveDiary(
                              existingDiary,
                              descriptionController.text,
                              selectedEmotion,
                            );
                          },
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
                    const Text(
                      "How are you feeling?",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    modalSetState(() {
                                      selectedEmotion = feeling;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.deepPurple
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? Colors.deepPurple
                                          : Colors.transparent,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.deepPurple
                                                    .withOpacity(0.5),
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
                            const Text(
                              "Write About It",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: descriptionController,
                              maxLines: null,
                              maxLength: 500,
                              onChanged: (text) {
                                modalSetState(() {});
                              },
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
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "${descriptionController.text.length}/500",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}



  Future<void> _saveDiary(Map<String, dynamic>? existingDiary, String description, String emotion) async {
    final now = DateTime.now();
    final diary = {
      'id': existingDiary?['id'] ?? now.toString(),
      'feeling': emotion,
      'description': description,
      'createdAt': now.toIso8601String(),
    };

    if (FirebaseAuth.instance.currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> localDiaries = [];
      final String? localDiariesString = prefs.getString('localDiaries');
      if (localDiariesString != null) {
        localDiaries = (jsonDecode(localDiariesString) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      if (existingDiary != null) {
        localDiaries.removeWhere((diary) => diary['id'] == existingDiary['id']);
      }
      localDiaries.add(diary);
      await prefs.setString('localDiaries', jsonEncode(localDiaries));
    } else {
      if (existingDiary == null) {
        await FirebaseHelper.createDiary(emotion, description);
      } else {
        await FirebaseHelper.updateDiary(existingDiary['id'], emotion, description);
      }
    }

    _refreshDiaries();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      appBar: AppBar(
        title: Image.asset("assets/memolia_name.png", height: 200),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDiaries,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Welcome, ${user?.displayName?.split(' ')[0] ?? "User"}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "How are you feeling today?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(243, 167, 18, 1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilterChip(
                                label: const Text('Today'),
                                selected: _filterOption == 'Today',
                                onSelected: (bool selected) {
                                  _filterDiaries('Today');
                                },
                              ),
                              const SizedBox(width: 10),
                              FilterChip(
                                label: const Text('This Week'),
                                selected: _filterOption == 'This Week',
                                onSelected: (bool selected) {
                                  _filterDiaries('This Week');
                                },
                              ),
                              const SizedBox(width: 10),
                              FilterChip(
                                label: const Text('Select Date'),
                                selected: _filterOption == 'Select Date',
                                onSelected: (bool selected) {
                                  _selectDate();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_filteredDiaries.isEmpty)
                        const Center(
                          child: Text(
                            'No logs found.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ..._filteredDiaries.map((diary) {
                        return Dismissible(
                          key: Key(diary['id']),
                          background: Container(
                            color: Colors.blue,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _showAddEditModal(existingDiary: diary);
                              return false;
                            } else if (direction == DismissDirection.endToStart) {
                              final bool res = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm"),
                                    content: const Text("Are you sure you wish to delete this entry?"),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text("DELETE"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text("CANCEL"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return res;
                            }
                            return false;
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _diaries.removeWhere((d) => d['id'] == diary['id']);
                              if (user == null) {
                                _saveLocalDiaries();
                              }
                              _refreshDiaries();
                            }
                          },
                          child: Card(
                            color: const Color.fromRGBO(100, 110, 240, 1),
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        diary['feeling'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        formatDateTime(diary['createdAt']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    diary['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          Positioned(
            left: 30,
            right: 30,
            bottom: 10,
            child: CustomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on Home, do nothing
                    break;
                  case 1:
                    _showAddEditModal(); // Show the modal for adding a new diary entry
                    break;
                  case 2:
                    if (user == null) {
                      _showLocalStorageNotification();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    }
                    break;
                }
              },
              onAddLog: () {
                _showAddEditModal();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocalDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> diariesJson = _diaries.map((diary) {
      return {
        'id': diary['id'],
        'feeling': diary['feeling'],
        'description': diary['description'],
        'createdAt': diary['createdAt'].toIso8601String(),
      };
    }).toList();

    final String encodedDiaries = jsonEncode(diariesJson);
    await prefs.setString('localDiaries', encodedDiaries);
  }

  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('EEE, dd MMM yy, HH:mm');
    return formatter.format(dateTime);
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _filterDiaries('Select Date');
      });
    }
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

