import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../data/conversation_data.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isMicMode = true;
  String _outputText = '';
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _iconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _outputText = result.recognizedWords;
            });
          }

          if (result.finalResult) {
            addMessageToConversation(
              "Juan Dela Cruz",
              Message(text: result.recognizedWords, isUser: true),
            );

            Future.delayed(Duration(seconds: 2), () {
              if (mounted) setState(() => _outputText = '');
            });
          }
        },
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _speak(String phrase) async {
    setState(() => _outputText = phrase);
    addMessageToConversation(
      "Juan Dela Cruz",
      Message(text: phrase, isUser: true),
    );
    await _flutterTts.setLanguage("tl-PH");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(phrase);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) setState(() => _outputText = '');
    });
  }

  void _toggleMode() {
    setState(() {
      _isMicMode = !_isMicMode;
      _iconController.forward(from: 0);
      _outputText = '';
      if (_isListening) _stopListening();
    });
  }

  Widget _buildOutputBubble() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<String>(_outputText),
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 24),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _outputText.isEmpty
              ? (_isMicMode
                    ? 'Listening output appears here...'
                    : 'FSL translation output here...')
              : _outputText,
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMicIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _isListening ? 1.15 : 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _isListening ? _stopListening : _startListening,
        child: CircleAvatar(
          radius: 80,
          backgroundColor: Colors.yellow,
          child: Icon(
            _isListening ? Icons.mic_off : Icons.mic,
            size: 80,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFslIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: !_isMicMode ? 1.15 : 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: !_isMicMode
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
        );
      },
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.yellow,
        child: Icon(Icons.back_hand, size: 80, color: Colors.black),
      ),
    );
  }

  Widget _buildMicMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOutputBubble(),
        _buildMicIcon(),
        SizedBox(height: 20),
        Text(
          _isListening ? 'Listening... Speak now' : 'Tap to Start Speaking',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFslMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOutputBubble(),
        _buildFslIcon(),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _speak("Maghanda para sa pagsasalin"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          ),
          child: Text(
            "START TRANSLATE FSL",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _fslDemoButton('Kumusta po'),
            _fslDemoButton('Salamat'),
            _fslDemoButton('Paalam'),
            _fslDemoButton('Mahal kita'),
          ],
        ),
      ],
    );
  }

  Widget _fslDemoButton(String phrase) {
    return ElevatedButton(
      onPressed: () => _speak(phrase),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(phrase, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0, top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 36,
            onPressed: _toggleMode,
            tooltip: _isMicMode ? 'Switch to FSL Mode' : 'Switch to MIC Mode',
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(
                _isMicMode ? Icons.back_hand : Icons.mic,
                key: ValueKey<bool>(_isMicMode),
                color: Colors.yellow,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            _isMicMode ? 'Switch to FSL' : 'Switch to MIC',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF083D77),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Tinig-Kamay Chat',
            style: TextStyle(color: Colors.white),
          ),
          actions: [_buildToggleButton()],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: _isMicMode ? _buildMicMode() : _buildFslMode(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
