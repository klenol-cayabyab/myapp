import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _micText = '';

  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  String _fslText = 'Waiting for sign...';

  // Toggle: true = MIC Mode, false = FSL Mode
  bool _isMicMode = true;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _micText = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _speak(String text) async {
    setState(() {
      _fslText = text;
    });
    await _flutterTts.setLanguage("tl-PH");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Widget _buildMicMode() {
    return Column(
      children: [
        Text(
          _micText.isEmpty ? 'Start speaking...' : _micText,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 20),
        CircleAvatar(
          radius: 80,
          backgroundColor: Colors.yellow,
          child: Icon(
            _isListening ? Icons.mic_off : Icons.mic,
            size: 80,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isListening ? _stopListening : _startListening,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            _isListening ? 'STOP' : 'SPEECH TO TEXT',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildFslMode() {
    return Column(
      children: [
        Text(_fslText, style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 20),
        CircleAvatar(
          radius: 80,
          backgroundColor: Colors.yellow,
          child: Icon(Icons.back_hand, size: 80, color: Colors.white),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _speak("Maghanda para sa pagsasalin"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: Text(
            'START TRANSLATE FSL',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton(
              onPressed: () => _speak('Kumusta po'),
              child: Text('Gesture: Kumusta po'),
            ),
            ElevatedButton(
              onPressed: () => _speak('Salamat'),
              child: Text('Gesture: Salamat'),
            ),
            ElevatedButton(
              onPressed: () => _speak('Paalam'),
              child: Text('Gesture: Paalam'),
            ),
            ElevatedButton(
              onPressed: () => _speak('Mahal kita'),
              child: Text('Gesture: Mahal kita'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text('MIC Mode'),
                  selected: _isMicMode,
                  onSelected: (val) {
                    setState(() => _isMicMode = true);
                  },
                  selectedColor: Colors.yellow,
                ),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text('FSL Mode'),
                  selected: !_isMicMode,
                  onSelected: (val) {
                    setState(() => _isMicMode = false);
                  },
                  selectedColor: Colors.yellow,
                ),
              ],
            ),
            SizedBox(height: 30),

            // Dynamic content
            Expanded(
              child: SingleChildScrollView(
                child: _isMicMode ? _buildMicMode() : _buildFslMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
