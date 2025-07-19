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
  String _selectedContact = 'Juan Dela Cruz'; // Default contact
  List<Message> _sessionMessages = []; // Local session messages

  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _iconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _loadSessionMessages();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  // Load messages for current session
  void _loadSessionMessages() {
    setState(() {
      _sessionMessages = conversations[_selectedContact] ?? [];
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available && !_speech.isListening) {
      // Added isListening check
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _outputText = result.recognizedWords;
            });
          }

          if (result.finalResult) {
            final newMessage = Message(
              text: result.recognizedWords,
              isUser: true,
            );

            // Add to session messages
            setState(() {
              _sessionMessages.add(newMessage);
            });

            // Save to global conversations
            addMessageToConversation(_selectedContact, newMessage);

            // Clear output after 2 seconds but keep in messages list
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

    final newMessage = Message(text: phrase, isUser: true);

    // Add to session messages
    setState(() {
      _sessionMessages.add(newMessage);
    });

    // Save to global conversations
    addMessageToConversation(_selectedContact, newMessage);

    await _flutterTts.setLanguage("tl-PH");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(phrase);

    // Clear output after speaking but keep in messages list
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

  Widget _buildMessagesList() {
    if (_sessionMessages.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 100, // Reduced height to prevent overflow
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added this
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              'Recent Messages:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            // Changed from Expanded to Flexible
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true, // Added this
              itemCount: _sessionMessages.length > 3
                  ? 3
                  : _sessionMessages.length,
              itemBuilder: (context, index) {
                final actualIndex = _sessionMessages.length - 3 + index;
                if (actualIndex < 0) return SizedBox.shrink();

                final message = _sessionMessages[actualIndex];
                return Container(
                  margin: EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputBubble() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: EdgeInsets.all(16),
      constraints: BoxConstraints(maxHeight: 80), // Added height constraint
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        // Added scrolling for long text
        child: Text(
          _outputText.isEmpty
              ? (_isMicMode
                    ? 'Listening output appears here...'
                    : 'FSL translation output here...')
              : _outputText,
          style: TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMicIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _isListening ? 1.1 : 1.0),
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
                        blurRadius: 20,
                        spreadRadius: 3,
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
          radius: 60, // Reduced size
          backgroundColor: Colors.yellow,
          child: Icon(
            _isListening ? Icons.mic_off : Icons.mic,
            size: 60, // Reduced size
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFslIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: !_isMicMode ? 1.1 : 1.0),
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
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
        );
      },
      child: CircleAvatar(
        radius: 60, // Reduced size
        backgroundColor: Colors.yellow,
        child: Icon(Icons.back_hand, size: 60, color: Colors.black),
      ),
    );
  }

  Widget _buildMicMode() {
    return Flexible(
      // Changed from Expanded to Flexible
      child: SingleChildScrollView(
        // Added scroll capability
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Added this
          children: [
            SizedBox(height: 20),

            // Messages list
            _buildMessagesList(),

            // Output bubble
            _buildOutputBubble(),

            SizedBox(height: 20),

            // Mic icon
            _buildMicIcon(),

            SizedBox(height: 16),

            // Status text
            Text(
              _isListening ? 'Listening... Speak now' : 'Tap to Start Speaking',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildFslMode() {
    return Flexible(
      // Changed from Expanded to Flexible
      child: SingleChildScrollView(
        // Added scroll capability
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Added this
          children: [
            SizedBox(height: 20),

            // Messages list
            _buildMessagesList(),

            // Output bubble
            _buildOutputBubble(),

            SizedBox(height: 20),

            // FSL icon
            _buildFslIcon(),

            SizedBox(height: 16),

            // Start translate button
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

            SizedBox(height: 16),

            // Demo buttons - wrapped in flexible container
            Container(
              constraints: BoxConstraints(maxHeight: 120), // Constrain height
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _fslDemoButton('Kumusta po'),
                    _fslDemoButton('Salamat'),
                    _fslDemoButton('Paalam'),
                    _fslDemoButton('Mahal kita'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _fslDemoButton(String phrase) {
    return ElevatedButton(
      onPressed: () => _speak(phrase),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(phrase, style: TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0, top: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 32, // Reduced size
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
          Text(
            _isMicMode ? 'FSL' : 'MIC',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF083D77),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: Text('Tinig-Kamay Chat', style: TextStyle(color: Colors.white)),
        actions: [_buildToggleButton()],
      ),
      body: Column(children: [_isMicMode ? _buildMicMode() : _buildFslMode()]),
    );
  }
}
