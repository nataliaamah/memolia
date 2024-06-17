import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_page.dart';
import 'addeditpage.dart';
import 'login.dart';
import 'package:intl/intl.dart';
import 'custom_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_helper.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('EEE | dd MMM yy | HH:mm');
    return formatter.format(dateTime);
  }

  void _refreshDiaries() async {
    final data = await FirebaseHelper.getDiaries();
    if (mounted) {
      setState(() {
        _diaries = data.map((diary) {
          if (diary['createdAt'] is String) {
            return {
              ...diary,
              'createdAt': DateTime.parse(diary['createdAt']),
            };
          } else {
            return diary;
          }
        }).toList();

        _diaries.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

        _availableDates = _diaries.map((diary) => diary['createdAt'] as DateTime).toSet().toList();
        _filterDiaries('Today');
        _isLoading = false;
      });
    }
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
        title: Image.asset("assets/memolia_name.png", height: 200),
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
                      SizedBox(height: 20),
                      Text(
                        'Welcome, ${user?.displayName ?? "User"}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "How are you feeling today?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromRGBO(243, 167, 18, 1)),
                      ),
                      SizedBox(height: 20),
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
                      SizedBox(height: 20),
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
            child: CustomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Handle Home button press
                    break;
                  case 1:
                    _navigateToAddEditPage();
                    break;
                  case 2:
                    if (user == null) {
                      _showLoginRequiredNotification();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    }
                    break;
                }
              },
              onAddLog: () {
                _navigateToAddEditPage();
              },
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
