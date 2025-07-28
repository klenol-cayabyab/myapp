import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'conversation_detail_screen.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String type;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type,
    'id': '${timestamp.millisecondsSinceEpoch}_${text.hashCode}',
  };

  static Message fromJson(Map<String, dynamic> json) => Message(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? true,
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    ),
    type: json['type'] ?? 'text',
  );
}

enum ChatMode { text, mic, fsl }

class ChatScreen extends StatefulWidget {
  final String selectedContact;
  final String? initialMode;
  final Function(String)? onContactChange;

  const ChatScreen({
    super.key,
    required this.selectedContact,
    this.initialMode,
    this.onContactChange,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // Controllers
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late TextEditingController _textController;

  // Animation controllers - only create when needed
  AnimationController? _waveController;
  AnimationController? _pulseController;
  late AnimationController _typewriterController;

  // State variables
  bool _isListening = false;
  ChatMode _currentMode = ChatMode.mic;
  String _outputText = '';
  List<Message> _sessionMessages = [];
  double _voiceLevel = 0.0;
  String _selectedContact = '';
  List<String> _availableContacts = [];
  bool _isContactsLoading = true;
  String? _expandedCategory;
  bool _isDisposed = false;

  // Color scheme
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryMedium = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2D5A87);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color accentSecondary = Color(0xFF7C3AED);

  // FSL Categories - made smaller for better performance
  final Map<String, List<String>> _fslCategories = {
    'Greetings': ['Kumusta po', 'Hello', 'Good morning'],
    'Gratitude': ['Salamat', 'Thank you', 'Maraming salamat'],
    'Emotions': ['Mahal kita', 'Miss kita', 'Masaya ako'],
    'Questions': ['Nasaan ka?', 'Kumain ka na?', 'Okay ka lang?'],
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeComponents();
    _setInitialMode();
    _loadData();
  }

  void _initializeControllers() {
    _textController = TextEditingController();
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _initializeComponents() {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _selectedContact = widget.selectedContact;
  }

  void _setInitialMode() {
    if (widget.initialMode == 'fsl') {
      _currentMode = ChatMode.fsl;
    } else if (widget.initialMode == 'mic') {
      _currentMode = ChatMode.mic;
    } else {
      _currentMode = ChatMode.text;
    }
  }

  // Lazy initialization with null safety
  void _ensureWaveController() {
    if (_waveController == null && !_isDisposed && mounted) {
      _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
    }
  }

  void _ensurePulseController() {
    if (_pulseController == null && !_isDisposed && mounted) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
    }
  }

  Future<void> _loadData() async {
    await _loadAvailableContacts();
    if (mounted) {
      await _loadContactMessages();
      await _initializeSpeech();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waveController?.dispose();
    _pulseController?.dispose();
    _typewriterController.dispose();
    _textController.dispose();
    _flutterTts.stop();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status == 'notListening' && _isListening) {
            setState(() => _isListening = false);
            _pulseController?.stop();
            _pulseController?.reset();
          }
        },
        onError: (error) {
          if (mounted && _isListening) {
            _stopListening();
          }
        },
      );
      if (!available) {
        debugPrint('Speech recognition not available');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Future<void> _loadAvailableContacts() async {
    if (!mounted) return;

    setState(() => _isContactsLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('conversations_list');

      List<String> contacts = [
        'Klenol Cayabyab',
        'Gello Gadaingan',
        'Lance Alog',
        'Renz Atienza',
        'Gian',
        'Vhon',
      ];

      if (conversationsJson != null) {
        final List<dynamic> conversationsList = json.decode(conversationsJson);
        List<String> savedContacts = conversationsList
            .map((conv) => conv['name'].toString())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        for (String savedContact in savedContacts) {
          if (!contacts.contains(savedContact)) {
            contacts.add(savedContact);
          }
        }
      }

      if (!contacts.contains(_selectedContact)) {
        contacts.insert(0, _selectedContact);
      }

      if (mounted) {
        setState(() {
          _availableContacts = contacts;
          _isContactsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _availableContacts = [_selectedContact];
          _isContactsLoading = false;
        });
      }
    }
  }

  Future<void> _loadContactMessages() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'messages_$_selectedContact';
      final String? messagesJson = prefs.getString(key);

      if (messagesJson != null && mounted) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        setState(() {
          _sessionMessages = messagesList
              .map((json) => Message.fromJson(json))
              .toList();
        });
      } else if (mounted) {
        setState(() => _sessionMessages = []);
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() => _sessionMessages = []);
      }
    }
  }

  Future<void> _saveContactMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'messages_$_selectedContact';
      final String messagesJson = json.encode(
        _sessionMessages.map((message) => message.toJson()).toList(),
      );
      await prefs.setString(key, messagesJson);
      await _updateConversationInHistory();
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  Future<void> _updateConversationInHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('conversations_list');

      List<dynamic> conversations = [];
      if (conversationsJson != null) {
        conversations = json.decode(conversationsJson);
      }

      int index = conversations.indexWhere(
        (conv) => conv['name'] == _selectedContact,
      );

      if (_sessionMessages.isNotEmpty) {
        final lastMessage = _sessionMessages.last;
        final conversationData = {
          'name': _selectedContact,
          'preview': lastMessage.text,
          'time': _getCurrentTime(),
          'messageCount': _sessionMessages.length,
          'lastMessageType': lastMessage.type,
        };

        if (index != -1) {
          conversations[index] = conversationData;
          final updatedConversation = conversations.removeAt(index);
          conversations.insert(0, updatedConversation);
        } else {
          conversations.insert(0, conversationData);
        }

        await prefs.setString('conversations_list', json.encode(conversations));
      }
    } catch (e) {
      debugPrint('Error updating conversation: $e');
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addMessage(String text, bool isUser, String messageType) async {
    if (text.trim().isEmpty || !mounted) return;

    final newMessage = Message(
      text: text.trim(),
      isUser: isUser,
      timestamp: DateTime.now(),
      type: messageType,
    );

    setState(() {
      _sessionMessages.add(newMessage);
    });

    await _saveContactMessages();
    if (mounted) {
      _showMessageSent(messageType);
    }
  }

  void _showMessageSent(String messageType) {
    if (!mounted) return;

    Color color;
    IconData icon;
    String label;

    switch (messageType) {
      case 'voice':
        color = accentColor;
        icon = Icons.mic_rounded;
        label = 'Voice';
        break;
      case 'fsl':
        color = accentSecondary;
        icon = Icons.sign_language_rounded;
        label = 'FSL';
        break;
      default:
        color = Colors.green;
        icon = Icons.message_rounded;
        label = 'Text';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$label message sent to $_selectedContact',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage(text, true, 'text');
      _textController.clear();
    }
  }

  Future<void> _startListening() async {
    if (!mounted || !_speech.isAvailable) return;

    if (!_speech.isListening) {
      setState(() => _isListening = true);

      if (_currentMode == ChatMode.mic) {
        _ensurePulseController();
        _pulseController?.repeat();
      }

      HapticFeedback.lightImpact();

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          if (result.recognizedWords.isNotEmpty) {
            setState(() => _outputText = result.recognizedWords);
            _typewriterController.forward();
          }

          if (result.finalResult) {
            _addMessage(result.recognizedWords, true, 'voice');
            _stopListening();

            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _outputText = '');
                _typewriterController.reset();
              }
            });
          }
        },
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 30),
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          if (mounted && _currentMode == ChatMode.mic) {
            setState(() => _voiceLevel = level.clamp(0.0, 1.0));
          }
        },
      );
    }
  }

  void _stopListening() {
    if (mounted) {
      setState(() => _isListening = false);
    }
    _speech.stop();
    _pulseController?.stop();
    _pulseController?.reset();
    HapticFeedback.lightImpact();
  }

  Future<void> _speak(String phrase) async {
    if (!mounted) return;

    HapticFeedback.selectionClick();
    setState(() => _outputText = phrase);
    _typewriterController.forward();

    await _addMessage(phrase, true, 'fsl');

    try {
      await _flutterTts.setLanguage("tl-PH");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(phrase);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _outputText = '');
        _typewriterController.reset();
      }
    });
  }

  void _toggleMode() {
    if (!mounted) return;

    setState(() {
      switch (_currentMode) {
        case ChatMode.text:
          _currentMode = ChatMode.mic;
          break;
        case ChatMode.mic:
          _currentMode = ChatMode.fsl;
          break;
        case ChatMode.fsl:
          _currentMode = ChatMode.text;
          break;
      }

      _outputText = '';
      _expandedCategory = null;
      if (_isListening) _stopListening();
    });

    HapticFeedback.mediumImpact();
  }

  Widget _buildContactSelector() {
    if (_isContactsLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading contacts...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _availableContacts.contains(_selectedContact)
              ? _selectedContact
              : null,
          dropdownColor: primaryMedium,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white.withOpacity(0.7),
          ),
          isExpanded: true,
          items: _availableContacts.map((contact) {
            return DropdownMenuItem<String>(
              value: contact,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentSecondary],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        contact.isNotEmpty ? contact[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contact,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newContact) {
            if (newContact != null &&
                newContact != _selectedContact &&
                mounted) {
              setState(() => _selectedContact = newContact);
              _loadContactMessages();
              if (widget.onContactChange != null) {
                widget.onContactChange!(newContact);
              }
              HapticFeedback.selectionClick();
            }
          },
        ),
      ),
    );
  }

  Widget _buildModernOutputBubble() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 120, // Fixed constraint to prevent unbounded height
      ),
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
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _outputText.isEmpty
              ? Text(
                  _getPlaceholderText(),
                  key: const ValueKey('placeholder'),
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
                          .round()
                          .clamp(0, _outputText.length),
                    );

                    return Text(
                      displayText,
                      key: const ValueKey('output'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _getPlaceholderText() {
    switch (_currentMode) {
      case ChatMode.text:
        return 'Type your message below...';
      case ChatMode.mic:
        return 'Tap the mic to start speaking...';
      case ChatMode.fsl:
        return 'Select a phrase to translate...';
    }
  }

  Widget _buildModernMicButton() {
    _ensurePulseController();

    return AnimatedBuilder(
      animation: _pulseController ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 20 + 10 * (_pulseController?.value ?? 0),
                      spreadRadius: 5 + 15 * (_pulseController?.value ?? 0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isListening ? _stopListening : _startListening,
              borderRadius: BorderRadius.circular(80),
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                      key: ValueKey(_isListening),
                      size: 56,
                      color: Colors.white,
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
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [accentSecondary, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.back_hand_rounded, size: 56, color: Colors.white),
    );
  }

  Widget _buildCategorizedPhrases() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
        children: _fslCategories.entries.map((entry) {
          final category = entry.key;
          final phrases = entry.value;
          final isExpanded = _expandedCategory == category;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _expandedCategory = isExpanded ? null : category;
                        });
                      }
                      HapticFeedback.selectionClick();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: accentSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentSecondary.withOpacity(0.2),
                accentSecondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            phrase,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaveAnimation() {
    _ensureWaveController();

    if (_waveController == null) {
      return const SizedBox(
        height: 40,
      ); // Fixed height to prevent layout issues
    }

    if (_isListening && _currentMode == ChatMode.mic) {
      _waveController!.repeat();
    } else {
      _waveController!.stop();
    }

    return Container(
      height: 40, // Fixed height constraint
      child: AnimatedBuilder(
        animation: _waveController!,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final delay = index * 0.2;
              final animValue = (_waveController!.value + delay) % 1.0;
              final height =
                  (20 +
                          20 *
                              _voiceLevel *
                              (0.5 + 0.5 * math.sin(animValue * 2 * math.pi)))
                      .clamp(10.0, 40.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_sessionMessages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 140, // Fixed height constraint
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Messages - $_selectedContact',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationDetailScreen(
                        contactName: _selectedContact,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.vertical,
              reverse: true,
              itemCount: _sessionMessages.length > 3
                  ? 3
                  : _sessionMessages.length,
              itemBuilder: (context, index) {
                final message =
                    _sessionMessages[_sessionMessages.length - 1 - index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildMessageTypeIcon(message.type),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
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

  Widget _buildMessageTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'voice':
        icon = Icons.mic_rounded;
        color = accentColor;
        break;
      case 'fsl':
        icon = Icons.sign_language_rounded;
        color = accentSecondary;
        break;
      default:
        icon = Icons.message_rounded;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 12, color: color),
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

  Widget _buildTextMode() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
          children: [
            _buildContactSelector(),
            _buildMessagesList(),
            _buildModernOutputBubble(),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (text) {
                      if (mounted) {
                        setState(() => _outputText = text);
                      }
                    },
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentSecondary],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _sendTextMessage,
                            borderRadius: BorderRadius.circular(25),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMicMode() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
          children: [
            _buildContactSelector(),
            _buildMessagesList(),
            _buildModernOutputBubble(),
            if (_isListening && _currentMode == ChatMode.mic) ...[
              const SizedBox(height: 20),
              _buildVoiceWaveAnimation(),
            ],
            const SizedBox(height: 30),
            _buildModernMicButton(),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isListening
                    ? 'Listening... Speak now'
                    : 'Tap the microphone to start recording',
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFslMode() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
          children: [
            _buildContactSelector(),
            _buildMessagesList(),
            _buildModernOutputBubble(),
            const SizedBox(height: 20),
            _buildModernFSLButton(),
            const SizedBox(height: 20),
            Text(
              'Choose a phrase to translate',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 30),
            _buildCategorizedPhrases(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernToggleButton() {
    String currentModeText;
    IconData currentIcon;

    switch (_currentMode) {
      case ChatMode.text:
        currentModeText = 'TEXT';
        currentIcon = Icons.keyboard_rounded;
        break;
      case ChatMode.mic:
        currentModeText = 'MIC';
        currentIcon = Icons.mic_rounded;
        break;
      case ChatMode.fsl:
        currentModeText = 'FSL';
        currentIcon = Icons.sign_language_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleMode,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.2),
                  accentSecondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    currentIcon,
                    key: ValueKey(currentModeText),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currentModeText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, primaryMedium, primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryDark.withOpacity(0.9),
                  primaryDark.withOpacity(0.7),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tinig-Kamay Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _selectedContact,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [_buildModernToggleButton()],
        ),
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fixed: prevent unbounded height
            children: [
              const SizedBox(height: 10),
              // Fixed switch statement with proper constraints
              switch (_currentMode) {
                ChatMode.text => _buildTextMode(),
                ChatMode.mic => _buildMicMode(),
                ChatMode.fsl => _buildFslMode(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
