import 'dart:ui';
import 'package:flutter/material.dart';
import 'firebase_helper.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];
  bool _isLoading = true;
  String _filterOption = 'Today';
  DateTime? _selectedDate;
  List<DateTime> _availableDates = [];
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLocalStorageNotification());
    }
    _refreshDiaries();
  }
  
  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('EEE | dd MMM yy | HH:mm');
    return formatter.format(dateTime);
  }

  void _refreshDiaries() async {
    final data = await FirebaseHelper.getDiaries();
    setState(() {
      _diaries = data.where((diary) => diary['userId'] == user?.uid).map((diary) {
        if (diary['createdAt'] is String) {
          return {
            ...diary,
            'createdAt': DateTime.parse(diary['createdAt']),
          };
        } else {
          return diary;
        }
      }).toList();

      // Sort diaries by time and date created
      _diaries.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      // Get available dates
      _availableDates = _diaries.map((diary) => diary['createdAt'] as DateTime).toSet().toList();
      _filterDiaries('Today'); // Filter by today's date by default
      _isLoading = false;
    });
  }

  void _showLocalStorageNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notice'),
        content: Text('Without logging in, your logs will only be saved on this device and not across devices.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAddEditPage({String? id}) {
    if (id != null) {
      final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditPage(
            id: id,
            existingDiary: existingDiary,
            refreshDiaries: _refreshDiaries,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditPage(
            refreshDiaries: _refreshDiaries,
          ),
        ),
      );
    }
  }

  void _deleteDiary(String id) async {
    await FirebaseHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a diary!'),
    ));
    _refreshDiaries();
  }

  Widget getImageForFeeling(String feeling) {
    switch (feeling) {
      case 'Happy':
        return Image.asset('assets/happy.gif', width: 24, height: 24);
      case 'Loved':
        return Image.asset('assets/loved.gif', width: 24, height: 24);
      case 'Excited':
        return Image.asset('assets/excited.gif', width: 24, height: 24);
      case 'Sad':
        return Image.asset('assets/sad.gif', width: 24, height: 24);
      case 'Tired':
        return Image.asset('assets/tired.gif', width: 24, height: 24);
      case 'Angry':
        return Image.asset('assets/angry.gif', width: 24, height: 24);
      case 'Annoyed':
        return Image.asset('assets/annoyed.gif', width: 24, height: 24);
      case 'Other':
      default:
        return Image.asset('assets/unknown.gif', width: 24, height: 24);
    }
  }

  Color getColorForFeeling(String feeling) {
    switch (feeling) {
      case 'Happy':
        return Colors.yellow[100]!;
      case 'Loved':
        return Colors.pink[100]!;
      case 'Excited':
        return Colors.orange[100]!;
      case 'Sad':
        return Colors.blue[100]!;
      case 'Tired':
        return Colors.grey[100]!;
      case 'Angry':
        return Colors.red[100]!;
      case 'Annoyed':
        return Colors.brown[100]!;
      case 'Other':
      default:
        return Colors.green[100]!;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      appBar: AppBar(
        title: Image.asset("assets/memolia_name.png", height: 300, width: 300,),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _refreshDiaries();
            },
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: EdgeInsets.only(bottom: 80),
                    children: [
                      SizedBox(height: 20,),
                      Text(
                        'Welcome, ${user?.displayName ?? "User"}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "How are you feeling today?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromRGBO(243, 167, 18, 1)),
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilterChip(
                                label: Text('Today'),
                                selected: _filterOption == 'Today',
                                onSelected: (bool selected) {
                                  _filterDiaries('Today');
                                },
                              ),
                              SizedBox(width: 10),
                              FilterChip(
                                label: Text('This Week'),
                                selected: _filterOption == 'This Week',
                                onSelected: (bool selected) {
                                  _filterDiaries('This Week');
                                },
                              ),
                              SizedBox(width: 10),
                              FilterChip(
                                label: Text('This Month'),
                                selected: _filterOption == 'This Month',
                                onSelected: (bool selected) {
                                  _filterDiaries('This Month');
                                },
                              ),
                              SizedBox(width: 10),
                              FilterChip(
                                label: Text('Select Date'),
                                selected: _filterOption == 'Select Date',
                                onSelected: (bool selected) {
                                  _selectDate();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),
                      if (_filteredDiaries.isEmpty) 
                        Center(
                          child: Text(
                            'No logs today',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ..._filteredDiaries.map((diary) {
                        return Dismissible(
                          key: Key(diary['id']),
                          background: Container(
                            color: Colors.blue,
                            child: Icon(Icons.edit, color: Colors.white),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 20),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            child: Icon(Icons.delete, color: Colors.white),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _navigateToAddEditPage(id: diary['id']);
                              return false;
                            } else if (direction == DismissDirection.endToStart) {
                              final bool res = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Confirm"),
                                    content: Text("Are you sure you wish to delete this item?"),
                                    actions: <Widget>[
                                      ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text("DELETE")
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text("CANCEL"),
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
                              _deleteDiary(diary['id']);
                            }
                          },
                          child: Card(
                            color: getColorForFeeling(diary['feeling']),
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      getImageForFeeling(diary['feeling']),
                                      Text(
                                        formatDateTime(diary['createdAt']),
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    diary['feeling'],
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    diary['description'].length > 50
                                        ? '${diary['description'].substring(0, 50)}...'
                                        : diary['description'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
          Positioned(
            left: 30,
            right: 30,
            bottom: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  height: 60, // Adjust the height here
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.8),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.home),
                          color: const Color.fromRGBO(14, 14, 37, 1),
                          onPressed: () {
                            // Handle Home button press
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded),
                          iconSize: 28,
                          color: const Color.fromRGBO(14, 14, 37, 1),
                          onPressed: () {
                            _navigateToAddEditPage();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.people_alt_rounded),
                          color: const Color.fromRGBO(14, 14, 37, 1),
                          onPressed: () {
                            if (user == null) {
                              _showLoginRequiredNotification();
                            } else {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfilePage()),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.settings),
                          color: const Color.fromRGBO(14, 14, 37, 1),
                          onPressed: () {
                            // Handle Settings button press
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text('You need to log in to view this page.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
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

  Future<void> _addDiary() async {
    await FirebaseHelper.createDiary(
      _selectedFeeling, 
      _descriptionController.text,
    );
    widget.refreshDiaries();
  }

  Future<void> _updateDiary(String id) async {
    await FirebaseHelper.updateDiary(
      id, 
      _selectedFeeling, 
      _descriptionController.text,
    );
    widget.refreshDiaries();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _descriptionController.text = val.recognizedWords;
            _isListening = false;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
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
                      Positioned(
                        right: 0,
                        top: 5,
                        child: IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                          onPressed: _listen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 190),
              ElevatedButton(
                onPressed: () async {
                  if (widget.id == null) {
                    await _addDiary();
                  } else {
                    await _updateDiary(widget.id!);
                  }
                  Navigator.of(context).pop();
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
