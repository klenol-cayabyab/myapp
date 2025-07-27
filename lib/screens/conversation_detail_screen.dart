import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class ConversationDetailScreen extends StatefulWidget {
  final String contactName;
  final Function(String, String?)? onBackToChat;

  const ConversationDetailScreen({
    super.key,
    required this.contactName,
    this.onBackToChat,
  });

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Controllers - Made non-nullable for better memory management
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;

  // State variables
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;
  late final String _messagesKey;

  // Enhanced color scheme
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryMedium = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2D5A87);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color accentSecondary = Color(0xFF7C3AED);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    _messagesKey = 'messages_${widget.contactName}';
    _loadMessages();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_hasUnsavedChanges) {
      _saveMessagesSync();
    }
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveMessagesSync();
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_messagesKey);

      List<Map<String, dynamic>> loadedMessages = [];

      if (messagesJson != null && messagesJson.isNotEmpty) {
        try {
          final List<dynamic> messagesList = json.decode(messagesJson);
          loadedMessages = messagesList
              .cast<Map<String, dynamic>>()
              .where(
                (msg) =>
                    msg['text'] != null &&
                    msg['text'].toString().trim().isNotEmpty,
              )
              .toList();
        } catch (e) {
          debugPrint('Error parsing messages JSON: $e');
          loadedMessages = [];
        }
      }

      if (mounted) {
        setState(() {
          _messages = loadedMessages;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    }
  }

  void _debouncedSave() {
    _hasUnsavedChanges = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) _saveMessagesAsync();
    });
  }

  Future<void> _saveMessagesAsync() async {
    if (!mounted || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = json.encode(_messages);
      await prefs.setString(_messagesKey, messagesJson);
      _hasUnsavedChanges = false;
      debugPrint(
        'Messages saved for ${widget.contactName}: ${_messages.length} messages',
      );
    } catch (e) {
      debugPrint('Error saving messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _saveMessagesSync() {
    if (!_hasUnsavedChanges) return;

    SharedPreferences.getInstance().then((prefs) {
      try {
        final messagesJson = json.encode(_messages);
        prefs.setString(_messagesKey, messagesJson);
        _hasUnsavedChanges = false;
        debugPrint('Sync save completed for ${widget.contactName}');
      } catch (e) {
        debugPrint('Error in sync save: $e');
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final newMessage = {
      'text': messageText,
      'isUser': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'id': '${DateTime.now().millisecondsSinceEpoch}_${_messages.length}',
      'type': 'text',
    };

    setState(() => _messages.add(newMessage));
    _messageController.clear();
    _debouncedSave();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });

    _showMessageSent();
  }

  void _showMessageSent() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Message sent'),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      await _saveMessagesAsync();
    }
    return true;
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryMedium, primaryDark],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuOption(
              icon: Icons.clear_all_rounded,
              title: 'Clear Chat',
              subtitle: 'Remove all messages',
              iconColor: warningColor,
              onTap: () {
                Navigator.pop(context);
                _showClearDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Conversation',
              subtitle: 'Cannot be undone',
              iconColor: errorColor,
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.info_outline_rounded,
              title: 'Message Count',
              subtitle: '${_messages.length} messages',
              iconColor: accentColor,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: warningColor),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Clear Chat',
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Clear all messages with ${widget.contactName}? This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _messages.clear());
              await _saveMessagesAsync();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Chat cleared', warningColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: warningColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: errorColor,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Delete Conversation',
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete entire conversation with ${widget.contactName}? This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_messagesKey);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                _showSnackBar('Conversation deleted', errorColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              color == successColor
                  ? Icons.check_circle
                  : color == errorColor
                  ? Icons.error
                  : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime date;

    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // Enhanced navigation methods
  Future<void> _handleMicPress() async {
    HapticFeedback.lightImpact();

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync();
    }

    if (!mounted) return;

    // Use callback to return to chat with specific mode
    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'mic');
      Navigator.pop(context);
    }
  }

  Future<void> _handleFSLPress() async {
    HapticFeedback.lightImpact();

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync();
    }

    if (!mounted) return;

    // Use callback to return to chat with specific mode
    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'fsl');
      Navigator.pop(context);
    }
  }

  Future<void> _handleTextPress() async {
    HapticFeedback.lightImpact();

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync();
    }

    if (!mounted) return;

    // Use callback to return to chat with text mode
    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'text');
      Navigator.pop(context);
    }
  }

  Widget _buildMessageTypeIcon(String type) {
    switch (type) {
      case 'voice':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.mic_rounded, size: 16, color: Colors.white),
        );
      case 'fsl':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.sign_language_rounded,
            size: 16,
            color: Colors.yellow.shade300,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.contactName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isUser = message['isUser'] ?? false;
    final timestamp =
        message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final messageType = message['type'] ?? 'text';
    final text = message['text']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? (messageType == 'voice'
                              ? LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                )
                              : messageType == 'fsl'
                              ? LinearGradient(
                                  colors: [
                                    Colors.yellow.shade300,
                                    Colors.yellow.shade400,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [accentColor, accentSecondary],
                                ))
                        : null,
                    color: isUser ? null : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(6),
                      bottomRight: isUser
                          ? const Radius.circular(6)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? (messageType == 'voice'
                                  ? Colors.white.withOpacity(0.3)
                                  : messageType == 'fsl'
                                  ? Colors.yellow.withOpacity(0.3)
                                  : accentColor.withOpacity(0.3))
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (messageType != 'text')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildMessageTypeIcon(messageType),
                        ),
                      Text(
                        text,
                        style: TextStyle(
                          color: isUser
                              ? (messageType == 'voice'
                                    ? Colors.black87
                                    : messageType == 'fsl'
                                    ? Colors.black87
                                    : Colors.white)
                              : Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryMedium, primaryLight],
              ),
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () async {
              if (_hasUnsavedChanges) {
                await _saveMessagesAsync();
              }
              if (mounted) Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentSecondary],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 212, 255, 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 22,
                  child: Text(
                    widget.contactName.isNotEmpty
                        ? widget.contactName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.contactName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_messages.isNotEmpty)
                      Text(
                        '${_messages.length} messages',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (_isSaving)
              Container(
                padding: const EdgeInsets.all(14),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _showOptionsMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index], index);
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryMedium.withOpacity(0.8), primaryMedium],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Text Chat button
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentSecondary],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 212, 255, 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _handleTextPress,
                        icon: const Icon(
                          Icons.keyboard_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Text chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Mic button
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.9),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(255, 255, 255, 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _handleMicPress,
                        icon: const Icon(
                          Icons.mic_rounded,
                          color: Colors.black87,
                        ),
                        tooltip: 'Voice chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FSL button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.yellow.shade300,
                            Colors.yellow.shade400,
                          ],
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _handleFSLPress,
                        icon: const Icon(
                          Icons.sign_language_rounded,
                          color: Colors.black87,
                        ),
                        tooltip: 'FSL chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentSecondary],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 212, 255, 0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
