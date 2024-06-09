import 'package:flutter/material.dart';
import 'firebase_helper.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:animated_text_kit/animated_text_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
  }

  void _refreshDiaries() async {
    final data = await FirebaseHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _showForm(String? id) async {
    if (id != null) {
      final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
    } else {
      _feelingController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Create New Entry' : 'Update Entry'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _feelingController,
                decoration: const InputDecoration(hintText: 'Feeling'),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  if (_isListening)
                    Positioned(
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            WavyAnimatedText('Listening...',
                                textStyle: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                )),
                          ],
                          isRepeatingAnimation: true,
                          repeatForever: true,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _listen,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (id == null) {
                await _addDiary();
              } else {
                await _updateDiary(id);
              }
              Navigator.of(context).pop();
            },
            child: Text(id == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDiary() async {
    await FirebaseHelper.createDiary(
      _feelingController.text, 
      _descriptionController.text,
    );
    _refreshDiaries();
  }

  Future<void> _updateDiary(String id) async {
    await FirebaseHelper.updateDiary(
      id, 
      _feelingController.text, 
      _descriptionController.text,
    );
    _refreshDiaries();
  }

  void _deleteDiary(String id) async {
    await FirebaseHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a diary!'),
    ));
    _refreshDiaries();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Tracker'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDiaries();
        },
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
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
                      onPressed: () => _showForm(diary['id']),
                    ),
                    onLongPress: () => _showForm(diary['id']),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
