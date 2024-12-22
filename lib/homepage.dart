import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'custom_navigation_bar.dart';
import 'firebase_helper.dart'; // Adjust this import to match your file structure
import 'profile_page.dart';
import 'login.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
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
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _showLocalStorageNotification());
      _loadLocalDiaries();
    } else {
      _refreshDiaries();
    }
  }

  // Authentication Function
  Future<bool> _authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = false;

      // Check if biometric authentication is available
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to unlock this entry',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep auth session active
            biometricOnly: true, // Only allow biometric authentication
          ),
        );
      } else {
        // Show an error message if biometrics are not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Biometric authentication is not available on this device')),
        );
      }

      return isAuthenticated;
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
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
          diary['locked'] = diary['locked'] ?? true; // Default to true if null
          return diary;
        }).toList();

        _diaries.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        _filterDiaries('Today');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Convert base64 to File
  File? _base64ToImage(String? base64String) {
    if (base64String == null) return null;

    try {
      // Decode base64 string
      Uint8List bytes = base64Decode(base64String);

      // Create a temporary file
      File tempFile = File('${Directory.systemTemp.path}/temp_image.jpg');
      tempFile.writeAsBytesSync(bytes);

      return tempFile;
    } catch (e) {
      print('Error converting base64 to image: $e');
      return null;
    }
  }

  Future<void> _refreshDiaries() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final List<Map<String, dynamic>> firebaseDiaries = await FirebaseHelper.getDiaries();

      setState(() {
        _diaries = firebaseDiaries.map((diary) {
          diary['createdAt'] = DateTime.parse(diary['createdAt']);
          diary['locked'] = diary['locked'] ?? true; // Default to true if null
          if (diary.containsKey('imageBase64') && diary['imageBase64'] != null) {
            diary['imageBytes'] = base64Decode(diary['imageBase64']);
          }
          return diary;
        }).toList();

        _diaries.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        _filterDiaries(_filterOption);
        _isLoading = false;
      });
    } else {
      await _loadLocalDiaries();
    }
  }


  void _filterDiaries(String option) {
    setState(() {
      _filterOption = option;
      DateTime now = DateTime.now();

      if (option == 'Today') {
        _filteredDiaries = _diaries.where((diary) {
          final diaryDate = diary['createdAt'];
          return diaryDate.day == now.day &&
              diaryDate.month == now.month &&
              diaryDate.year == now.year;
        }).toList();
      } else if (option == 'This Week') {
        _filteredDiaries = _diaries.where((diary) {
          final diaryDate = diary['createdAt'];
          return diaryDate.isAfter(now.subtract(Duration(days: now.weekday))) &&
              diaryDate.isBefore(now.add(Duration(days: DateTime.daysPerWeek - now.weekday)));
        }).toList();
      } else if (option == 'Select Date' && _selectedDate != null) {
        _filteredDiaries = _diaries.where((diary) {
          final diaryDate = diary['createdAt'];
          return diaryDate.day == _selectedDate!.day &&
              diaryDate.month == _selectedDate!.month &&
              diaryDate.year == _selectedDate!.year;
        }).toList();
      } else {
        _filteredDiaries = List.from(_diaries);
      }

      // Sort filtered diaries by creation date in descending order
      _filteredDiaries.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    });
  }


  void _showLocalStorageNotification() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Notice'),
            content: const Text(
                'Without logging in, your logs will only be saved on this device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const LoginPage()));
                },
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveLocalDiaries(
      Map<String, dynamic>? existingDiary,
      String description,
      String? emotion,
      bool isLocked, // Use the selected locked state
      File? image) async {
    final now = DateTime.now();
    String? imagePath;

    // Save the image to local storage
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${now.millisecondsSinceEpoch}_diary_image.jpg';
      imagePath = '${appDir.path}/$fileName';
      await image.copy(imagePath);
    }

    // Create a diary entry
    final diary = {
      'id': existingDiary?['id'] ?? now.toString(),
      'feeling': emotion ?? '', // Default to an empty string if null
      'description': description,
      'createdAt': now.toIso8601String(),
      'locked': isLocked, // Use the provided locked state
      'imagePath': imagePath,
    };

    // Load existing local diaries
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> localDiaries = [];
    final String? localDiariesString = prefs.getString('localDiaries');
    if (localDiariesString != null) {
      localDiaries = (jsonDecode(localDiariesString) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }

    // Update or add the diary
    if (existingDiary != null) {
      localDiaries.removeWhere((d) => d['id'] == existingDiary['id']);
    }
    localDiaries.add(diary);

    // Save updated list back to local storage
    await prefs.setString('localDiaries', jsonEncode(localDiaries));
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


  Future<void> _saveDiary(
      Map<String, dynamic>? existingDiary,
      String description,
      String emotion,
      bool isLocked,
      File? image) async {
    final now = DateTime.now();
    String? imageBase64;

    if (image != null) {
      try {
        final compressedImage = await FlutterImageCompress.compressWithFile(
          image.absolute.path,
          quality: 50,
          minWidth: 800,
          minHeight: 800,
        );
        if (compressedImage != null) {
          imageBase64 = base64Encode(compressedImage);
        }
      } catch (e) {
        print('Error compressing image: $e');
      }
    }

    if (FirebaseAuth.instance.currentUser != null) {
      if (existingDiary == null) {
        await FirebaseHelper.createDiary(
          emotion,
          description,
          isLocked, // Use the selected locked state
          imageBase64,
        );
      } else {
        await FirebaseHelper.updateDiary(
          existingDiary['id'],
          emotion,
          description,
          isLocked, // Use the selected locked state
          imageBase64,
        );
      }
    } else {
      await _saveLocalDiaries(
        existingDiary,
        description,
        emotion,
        isLocked, // Use the selected locked state
        image,
      );
    }

    await _refreshDiaries();
    Navigator.pop(context);
  }


  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('EEE, dd MMM yy, HH:mm');
    return formatter.format(dateTime);
  }


  void _showAddEditModal({Map<String, dynamic>? existingDiary}) async {
    String selectedEmotion = existingDiary?['feeling'] ?? '';
    TextEditingController descriptionController = TextEditingController(
      text: existingDiary?['description'] ?? "",
    );
    bool isLocked = existingDiary?['locked'] ?? false;
    File? selectedImage = existingDiary?['image'];

    if (isLocked) {
      bool isAuthenticated = await _authenticateWithBiometrics();
      if (!isAuthenticated) {
        print("Authentication failed. Can't view or edit locked entry.");
        return;
      }
    }

    Future<void> pickImage(ImageSource source, StateSetter modalSetState) async {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        modalSetState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    void showImageSourceBottomSheet(StateSetter modalSetState) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera, modalSetState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery, modalSetState);
                },
              ),
              if (selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    modalSetState(() {
                      selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, ScrollController scrollController) {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                  Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lock Icon
                      GestureDetector(
                        onTap: () {
                          modalSetState(() {
                            isLocked = !isLocked;
                          });
                        },
                        child: Icon(
                          isLocked ? Icons.lock : Icons.lock_open,
                          color: isLocked ? Colors.deepPurple : Colors.white54,
                        ),
                      ),
                      // Title
                      Text(
                        existingDiary == null ? "New Entry" : "Edit Entry",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Save Button
                      GestureDetector(
                        onTap: () {
                          _saveDiary(
                            existingDiary,
                            descriptionController.text,
                            selectedEmotion,
                            isLocked,
                            selectedImage
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
                ),

                // Write About It Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Write About It",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        maxLines: null,
                        maxLength: 500,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onChanged: (text) {
                          modalSetState(() {});
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Start writing...",
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          counterText: "",
                        ),
                      ),
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

                // Emotion Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              modalSetState(() {
                                selectedEmotion = feeling;
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Add a Memory",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => showImageSourceBottomSheet(modalSetState),
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: selectedImage != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ]
              ),
              ),
              );
            },
          );
        },
      ),
    );
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
                  // Get the GIF path directly inline
                  final emotionGif = _feelings.firstWhere(
                        (item) => item['feeling'] == diary['feeling'],
                    orElse: () => {'gif': ''}, // Default to empty if no match
                  )['gif'] ?? '';

                  return Card(
                    color: const Color.fromRGBO(100, 110, 240, 1),
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Date, Emotion, Lock
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDateTime(diary['createdAt']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (emotionGif.isNotEmpty)
                                    Row(
                                      children: [
                                        Image.asset(
                                          emotionGif,
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          diary['feeling'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              GestureDetector(
                                onTap: diary['locked'] ? () => _unlockDiary(diary) : null,
                                child: Icon(
                                  diary['locked'] ? Icons.lock : Icons.lock_open,
                                  color: Colors.white.withOpacity(diary['locked'] ? 1.0 : 0.7), // 100% for locked, 70% for unlocked
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Image Section (Optional)
                          if (diary['imageBytes'] != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          diary['imageBytes'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  diary['imageBytes'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 150,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Description Section
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            firstChild: Text(
                              diary['locked'] ? 'This entry is locked.' : diary['description'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              diary['description'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            crossFadeState: diary['isExpanded'] ?? false
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          ),
                        ],
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
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
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


  void _unlockDiary(Map<String, dynamic> diary) async {
    bool canAuthenticate = await _canAuthenticate();

    if (canAuthenticate) {
      bool authenticated = await _authenticateWithBiometrics();

      if (authenticated) {
        setState(() {
          diary['locked'] = false; // Unlock locally for the session
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary unlocked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. Please try again.')),
        );
      }
    }
  }


  Future<bool> _canAuthenticate() async {
    final bool canAuthenticate = await auth.canCheckBiometrics;
    if (!canAuthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No biometric authentication available.')),
      );
    }
    return canAuthenticate;
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
