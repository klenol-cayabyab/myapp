import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'conversation_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  List<Map<String, String>> conversations = [];
  bool isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('conversations_list');

      if (conversationsJson != null) {
        final List<dynamic> conversationsList = json.decode(conversationsJson);
        setState(() {
          conversations = conversationsList
              .map((item) => Map<String, String>.from(item))
              .toList();
        });
      } else {
        setState(() {
          conversations = [
            {
              'name': 'Klenol Cayabyab',
              'preview': 'Kumusta ka na? Miss kita!',
              'time': '2:15 PM',
            },
            {
              'name': 'Gello Gadaingan',
              'preview': 'Ang pogi ko',
              'time': '11:30 AM',
            },
            {
              'name': 'Lance Alog',
              'preview': 'Pre Crush ko si alyssa',
              'time': 'Yesterday',
            },
            {
              'name': 'Renz Atienza',
              'preview': 'Tol, tara bilyar',
              'time': 'Yesterday',
            },
            {
              'name': 'Gian',
              'preview': 'Perfect Score nyo sa Presentation',
              'time': 'Jul 20',
            },
            {
              'name': 'Vhon',
              'preview': 'Pasado kayo sa final Project sabi ni Sir',
              'time': 'Jul 19',
            },
          ];
        });
        _saveConversations();
        await _initializeDefaultConversations();
      }

      setState(() {
        isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeDefaultConversations() async {
    final prefs = await SharedPreferences.getInstance();

    // Define more realistic conversation threads
    final Map<String, List<Map<String, dynamic>>> defaultConversationThreads = {
      'Klenol Cayabyab': [
        {
          'text': 'Hello!',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(minutes: 30))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Kumusta ka na? Miss kita!',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(minutes: 15))
              .millisecondsSinceEpoch,
        },
      ],
      'Gello Gadaingan': [
        {
          'text': 'Pano ba yan?',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(hours: 1))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Ang pogi ko',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(minutes: 45))
              .millisecondsSinceEpoch,
        },
      ],
      'Lance Alog': [
        {
          'text': 'Pre may balita ako',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 1, hours: 2))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Pre Crush ko si alyssa',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 1, hours: 1))
              .millisecondsSinceEpoch,
        },
      ],
      'Renz Atienza': [
        {
          'text': 'Libre ka ba mamaya?',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 1, hours: 3))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Tol, tara bilyar',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 1, hours: 2))
              .millisecondsSinceEpoch,
        },
      ],
      'Gian': [
        {
          'text': 'Kumusta presentation namin?',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 2, hours: 1))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Perfect Score nyo sa Presentation',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 2))
              .millisecondsSinceEpoch,
        },
      ],
      'Vhon': [
        {
          'text': 'Sir ano na results ng final project?',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 3, hours: 2))
              .millisecondsSinceEpoch,
        },
        {
          'text': 'Pasado kayo sa final Project sabi ni Sir',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(Duration(days: 3, hours: 1))
              .millisecondsSinceEpoch,
        },
      ],
    };

    for (var conversation in conversations) {
      final contactName = conversation['name']!;
      final messagesKey = 'messages_$contactName';

      if (!prefs.containsKey(messagesKey)) {
        final defaultMessages =
            defaultConversationThreads[contactName] ??
            [
              {
                'text': conversation['preview']!,
                'isUser': false,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            ];
        await prefs.setString(messagesKey, json.encode(defaultMessages));
      }
    }
  }

  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationsJson = json.encode(conversations);
      await prefs.setString('conversations_list', conversationsJson);
    } catch (e) {
      print('Error saving conversations: $e');
    }
  }

  Future<void> _addNewConversation() async {
    HapticFeedback.lightImpact();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.yellow.withOpacity(0.2), width: 1),
        ),
        title: Text(
          'New Conversation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: nameController,
              label: 'Contact Name',
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 16),
            _buildDialogTextField(
              controller: messageController,
              label: 'Initial Message (optional)',
              icon: Icons.message_outlined,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade300, Colors.yellow.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (nameController.text.trim().isNotEmpty) {
                    HapticFeedback.selectionClick();
                    Navigator.of(ctx).pop({
                      'name': nameController.text.trim(),
                      'preview': messageController.text.trim().isEmpty
                          ? 'No messages yet'
                          : messageController.text.trim(),
                      'time': _getCurrentTime(),
                    });
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        conversations.insert(0, result);
      });
      await _saveConversations();
      await _initializeNewContactThread(result['name']!, result['preview']!);
      _showSnackBar('New conversation added', Colors.green);
    }
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.yellow.shade300),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.yellow.shade300, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Future<void> _initializeNewContactThread(
    String contactName,
    String initialMessage,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesKey = 'messages_$contactName';

    List<Map<String, dynamic>> initialMessages = [];
    if (initialMessage != 'No messages yet') {
      initialMessages.add({
        'text': initialMessage,
        'isUser': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    await prefs.setString(messagesKey, json.encode(initialMessages));
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> updateConversationPreview(
    String contactName,
    String lastMessage,
    String time,
  ) async {
    final conversationIndex = conversations.indexWhere(
      (conv) => conv['name'] == contactName,
    );
    if (conversationIndex != -1) {
      setState(() {
        conversations[conversationIndex]['preview'] = lastMessage;
        conversations[conversationIndex]['time'] = time;

        // Move conversation to top
        final updatedConversation = conversations.removeAt(conversationIndex);
        conversations.insert(0, updatedConversation);
      });
      await _saveConversations();
    }
  }

  Future<void> _deleteConversation(int index) async {
    final contactName = conversations[index]['name']!;

    setState(() {
      conversations.removeAt(index);
    });
    await _saveConversations();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('messages_$contactName');

    _showSnackBar('Conversation deleted', Colors.red);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(milliseconds: 2000),
      ),
    );
  }

  void _navigateToChat(String contactName) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'contactName': contactName},
    );

    // Check if we got updated conversation data back
    if (result != null && result is Map<String, String>) {
      await updateConversationPreview(
        contactName,
        result['lastMessage'] ?? '',
        result['time'] ?? _getCurrentTime(),
      );
    }

    _showSnackBar('Opening chat with $contactName', Colors.green);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildConversationCard(Map<String, String> conversation, int index) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        final slideOffset =
            Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutBack,
                ),
              ),
            );

        return SlideTransition(
          position: slideOffset,
          child: Dismissible(
            key: Key(conversation['name']! + index.toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) =>
                _showDeleteConfirmation(conversation['name']!),
            onDismissed: (direction) => _deleteConversation(index),
            background: _buildDismissBackground(),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ConversationDetailScreen(
                              contactName: conversation['name']!,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                      ),
                    );

                    if (result != null && result is Map<String, String>) {
                      await updateConversationPreview(
                        conversation['name']!,
                        result['lastMessage'] ?? '',
                        result['time'] ?? _getCurrentTime(),
                      );
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildAvatar(conversation['name']!),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['name']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.yellow.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      conversation['time']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.yellow.shade300,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['preview']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  _buildChatButton(conversation['name']!),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ],
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

  Widget _buildAvatar(String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getAvatarColor(name),
            _getAvatarColor(name).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getAvatarColor(name).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildChatButton(String contactName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade300, Colors.yellow.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToChat(contactName),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.mic_rounded, color: Colors.black87, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(String contactName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        title: Text(
          'Delete Conversation?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this conversation with $contactName? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(ctx).pop(true);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the "New Chat" button to start\nyour first conversation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.yellow.shade300,
                ),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading conversations...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0A1A2E),
      extendBodyBehindAppBar: true,
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
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      Text(
                        'Tinig-Kamay History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.yellow.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${conversations.length} conversation${conversations.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.yellow.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeController,
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 100),
                          physics: BouncingScrollPhysics(),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            return _buildConversationCard(
                              conversations[index],
                              index,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16, right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade300, Colors.yellow.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
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
            borderRadius: BorderRadius.circular(20),
            onTap: _addNewConversation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_comment_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'New Chat',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
