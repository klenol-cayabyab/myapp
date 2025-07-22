import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String selectedContact;

  const ChatScreen({Key? key, required this.selectedContact}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isMicMode = true;
  String _outputText = '';
  List<Message> _sessionMessages = [];
  double _voiceLevel = 0.0;

  late AnimationController _iconController;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _typewriterController;

  // FSL Categories
  final Map<String, List<String>> _fslCategories = {
    'Greetings': ['Kumusta po', 'Hello', 'Good morning', 'Good afternoon'],
    'Gratitude': ['Salamat', 'Thank you', 'Salamat po', 'Maraming salamat'],
    'Emotions': ['Mahal kita', 'Miss kita', 'Masaya ako', 'Malungkot ako'],
    'Questions': [
      'Nasaan ka?',
      'Kumain ka na?',
      'Okay ka lang?',
      'Ano ginagawa mo?',
    ],
  };

  String? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeAnimations();
    _loadContactMessages();
  }

  void _initializeAnimations() {
    _iconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  // Load messages for the specific contact from SharedPreferences
  Future<void> _loadContactMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'messages_${widget.selectedContact}';
      final String? messagesJson = prefs.getString(key);

      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        setState(() {
          _sessionMessages = messagesList
              .map((json) => Message.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Save messages for the specific contact to SharedPreferences
  Future<void> _saveContactMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'messages_${widget.selectedContact}';
      final String messagesJson = json.encode(
        _sessionMessages.map((message) => message.toJson()).toList(),
      );
      await prefs.setString(key, messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  // Add a new message and save to SharedPreferences
  Future<void> _addMessage(String text, bool isUser) async {
    final newMessage = Message(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    setState(() {
      _sessionMessages.add(newMessage);
    });

    await _saveContactMessages();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available && !_speech.isListening) {
      setState(() => _isListening = true);
      _pulseController.repeat();

      // Haptic feedback
      HapticFeedback.lightImpact();

      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _outputText = result.recognizedWords;
            });
            _typewriterController.forward();
          }

          if (result.finalResult) {
            _addMessage(result.recognizedWords, true);
            _stopListening();

            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _outputText = '');
                _typewriterController.reset();
              }
            });
          }
        },
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        onSoundLevelChange: (level) {
          setState(() => _voiceLevel = level.clamp(0.0, 1.0));
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    HapticFeedback.lightImpact();
  }

  Future<void> _speak(String phrase) async {
    HapticFeedback.selectionClick();

    setState(() => _outputText = phrase);
    _typewriterController.forward();

    await _addMessage(phrase, true);

    await _flutterTts.setLanguage("tl-PH");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(phrase);

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _outputText = '');
        _typewriterController.reset();
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _isMicMode = !_isMicMode;
      _iconController.forward(from: 0);
      _outputText = '';
      _expandedCategory = null;
      if (_isListening) _stopListening();
    });
    HapticFeedback.mediumImpact();
  }

  Widget _buildVoiceWaveAnimation() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final delay = index * 0.2;
            final animValue = (_waveController.value + delay) % 1.0;
            final height =
                (20 +
                        30 *
                            _voiceLevel *
                            (0.5 + 0.5 * math.sin(animValue * 2 * math.pi)))
                    .clamp(10.0, 50.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.yellow.shade300,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMessagesList() {
    if (_sessionMessages.isEmpty) return SizedBox.shrink();

    return Container(
      height: 140,
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Recent Messages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Text(
                  '${_sessionMessages.length} messages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.vertical,
              reverse: true,
              itemCount: _sessionMessages.length > 3
                  ? 3
                  : _sessionMessages.length,
              itemBuilder: (context, index) {
                final message =
                    _sessionMessages[_sessionMessages.length - 1 - index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (message.timestamp != null) ...[
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message.timestamp!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildModernOutputBubble() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: EdgeInsets.all(20),
      constraints: BoxConstraints(minHeight: 80, maxHeight: 120),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _outputText.isEmpty
              ? Text(
                  _isMicMode
                      ? 'Tap the mic to start speaking...'
                      : 'Select a phrase to translate...',
                  key: ValueKey('placeholder'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              : AnimatedBuilder(
                  animation: _typewriterController,
                  builder: (context, child) {
                    final displayText = _outputText.substring(
                      0,
                      (_outputText.length * _typewriterController.value)
                          .round(),
                    );
                    return Text(
                      displayText,
                      key: ValueKey('output'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildModernMicButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.4),
                      blurRadius: 20 + 10 * _pulseController.value,
                      spreadRadius: 5 + 15 * _pulseController.value,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isListening ? _stopListening : _startListening,
              borderRadius: BorderRadius.circular(80),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow.shade300, Colors.yellow.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                      key: ValueKey(_isListening),
                      size: 64,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernFSLButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade300, Colors.yellow.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        ),
        child: Icon(Icons.back_hand_rounded, size: 64, color: Colors.black87),
      ),
    );
  }

  Widget _buildCategorizedPhrases() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _fslCategories.entries.map((entry) {
          final category = entry.key;
          final phrases = entry.value;
          final isExpanded = _expandedCategory == category;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCategory = isExpanded ? null : category;
                      });
                      HapticFeedback.selectionClick();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: Colors.yellow.shade300,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: phrases.map((phrase) {
                              return _buildModernPhraseButton(phrase);
                            }).toList(),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Greetings':
        return Icons.waving_hand_rounded;
      case 'Gratitude':
        return Icons.favorite_rounded;
      case 'Emotions':
        return Icons.sentiment_satisfied_rounded;
      case 'Questions':
        return Icons.help_outline_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Widget _buildModernPhraseButton(String phrase) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _speak(phrase),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow.withOpacity(0.2),
                Colors.yellow.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 1),
          ),
          child: Text(
            phrase,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicMode() {
    return Expanded(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildMessagesList(),
            _buildModernOutputBubble(),

            if (_isListening) ...[
              SizedBox(height: 20),
              _buildVoiceWaveAnimation(),
            ],

            SizedBox(height: 30),
            _buildModernMicButton(),
            SizedBox(height: 20),

            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Text(
                _isListening
                    ? 'Listening... Speak now'
                    : 'Tap the microphone to start',
                key: ValueKey(_isListening),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFslMode() {
    return Expanded(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildMessagesList(),
            _buildModernOutputBubble(),
            SizedBox(height: 20),
            _buildModernFSLButton(),
            SizedBox(height: 20),

            Text(
              'Choose a phrase to translate',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 30),
            _buildCategorizedPhrases(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernToggleButton() {
    return Container(
      margin: EdgeInsets.only(right: 16, top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleMode,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.yellow.withOpacity(0.2),
                  Colors.yellow.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.yellow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    _isMicMode ? Icons.back_hand_rounded : Icons.mic_rounded,
                    key: ValueKey(_isMicMode),
                    color: Colors.yellow.shade300,
                    size: 20,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _isMicMode ? 'FSL' : 'MIC',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A1A2E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A1A2E).withOpacity(0.9),
                Color(0xFF0A1A2E).withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tinig-Kamay Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.selectedContact,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [_buildModernToggleButton()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),
              _isMicMode ? _buildMicMode() : _buildFslMode(),
            ],
          ),
        ),
      ),
    );
  }
}
