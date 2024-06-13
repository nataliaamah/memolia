import 'package:flutter/material.dart';
import 'firebase_helper.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
  }

  void _refreshDiaries() async {
  final data = await FirebaseHelper.getDiaries();
  setState(() {
    _diaries = data;

    // Sort diaries by index in descending order
    _diaries.sort((a, b) => _diaries.indexOf(b).compareTo(_diaries.indexOf(a)));

    _isLoading = false;
  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      appBar: AppBar(
        title: Image.asset("assets/memolia_name.png", height: 300, width: 300,),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDiaries();
        },
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, User',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _diaries.length,
                itemBuilder: (context, index) {
                  final diary = _diaries[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Icon(Icons.book),
                      title: Text(diary['feeling']),
                      subtitle: Text(diary['description']),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _navigateToAddEditPage(id: diary['id']),
                      ),
                      onLongPress: () => _navigateToAddEditPage(id: diary['id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditPage(),
        child: Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 39, 60, 176),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 135, 180, 219),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(30)),
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
                  icon: Icon(Icons.calendar_today),
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: () {
                    // Handle Calendar button press
                  },
                ),
                SizedBox(width: 48), // The dummy child
                IconButton(
                  icon: Icon(Icons.people_alt_rounded),
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: () {
                    // Handle People button press
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
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add Mood Log' : 'Edit Mood Log'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("How Are You Feeling?"),
              SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _isMoodSelected ? null : (){},
                child: AbsorbPointer(
                  absorbing: !_isMoodSelected,
                  child: TextField(
                    controller: _descriptionController,
                    enabled: _isMoodSelected,
                    decoration: InputDecoration(
                      hintText: 'Description',
                      suffixIcon: IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        onPressed: _listen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  if (widget.id == null) {
                    await _addDiary();
                  } else {
                    await _updateDiary(widget.id!);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(widget.id == null ? 'Add Mood Log' : 'Update Mood Log'),
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
