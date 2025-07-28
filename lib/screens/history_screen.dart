import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  final Function(String, {String? mode})? onContactSelected;
  final Function(String)? onConversationDetailRequested;

  const HistoryScreen({
    super.key,
    this.onContactSelected,
    this.onConversationDetailRequested,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  //color scheme
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
    _loadConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredConversations = List.from(_conversations);
        } else {
          _filteredConversations = _conversations.where((conversation) {
            final name = conversation['name'].toString().toLowerCase();
            final preview = conversation['preview'].toString().toLowerCase();
            return name.contains(query) || preview.contains(query);
          }).toList();
        }
      });
    }
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('conversations_list');

      List<Map<String, dynamic>> loadedConversations = [];

      if (conversationsJson != null) {
        final List<dynamic> conversationsList = json.decode(conversationsJson);

        for (var item in conversationsList) {
          Map<String, dynamic> conversation = Map<String, dynamic>.from(item);
          String contactName = conversation['name'];
          Map<String, dynamic> messageInfo = await _getLastMessageInfo(
            contactName,
          );

          conversation.addAll({
            'messageCount': messageInfo['count'],
            'lastMessageType': messageInfo['type'],
            'hasVoiceMessages': messageInfo['hasVoice'],
            'hasFSLMessages': messageInfo['hasFSL'],
            'lastMessageTime': messageInfo['lastTime'],
          });

          loadedConversations.add(conversation);
        }
      } else {
        // Initialize with default contacts
        loadedConversations = [
          _createDefaultConversation('Klenol Cayabyab'),
          _createDefaultConversation('Gello Gadaingan'),
          _createDefaultConversation('Lance Alog'),
          _createDefaultConversation('Renz Atienza'),
          _createDefaultConversation('Gian'),
          _createDefaultConversation('Vhon'),
        ];
        await _saveConversations(loadedConversations);
      }

      // Sort by last message time
      loadedConversations.sort((a, b) {
        final aTime = a['lastMessageTime'] ?? 0;
        final bTime = b['lastMessageTime'] ?? 0;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _conversations = loadedConversations;
          _filteredConversations = List.from(loadedConversations);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load conversations', errorColor);
      }
    }
  }

  Map<String, dynamic> _createDefaultConversation(String name) {
    return {
      'name': name,
      'preview': 'No messages yet',
      'time': 'New',
      'messageCount': 0,
      'lastMessageType': 'text',
      'hasVoiceMessages': false,
      'hasFSLMessages': false,
      'lastMessageTime': 0,
    };
  }

  Future<Map<String, dynamic>> _getLastMessageInfo(String contactName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString('messages_$contactName');

      if (messagesJson != null && messagesJson.isNotEmpty) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        List<Map<String, dynamic>> messages = messagesList
            .cast<Map<String, dynamic>>()
            .where(
              (msg) =>
                  msg['text'] != null &&
                  msg['text'].toString().trim().isNotEmpty,
            )
            .toList();

        if (messages.isNotEmpty) {
          bool hasVoice = messages.any((msg) => msg['type'] == 'voice');
          bool hasFSL = messages.any((msg) => msg['type'] == 'fsl');
          String lastType = messages.last['type'] ?? 'text';
          int lastTime = messages.last['timestamp'] ?? 0;

          return {
            'count': messages.length,
            'type': lastType,
            'hasVoice': hasVoice,
            'hasFSL': hasFSL,
            'lastTime': lastTime,
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting message info: $e');
    }

    return {
      'count': 0,
      'type': 'text',
      'hasVoice': false,
      'hasFSL': false,
      'lastTime': 0,
    };
  }

  Future<void> _saveConversations(
    List<Map<String, dynamic>> conversations,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationsJson = json.encode(conversations);
      await prefs.setString('conversations_list', conversationsJson);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  Future<void> _addNewConversation() async {
    HapticFeedback.lightImpact();
    final TextEditingController nameController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_comment_rounded, color: accentColor, size: 24),
            SizedBox(width: 16),
            Text(
              'New Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Contact Name',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: accentColor,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                bool isDuplicate = _conversations.any(
                  (conv) =>
                      conv['name'].toString().toLowerCase() ==
                      name.toLowerCase(),
                );

                if (isDuplicate) {
                  _showSnackBar('Contact already exists', warningColor);
                  return;
                }

                HapticFeedback.heavyImpact();
                Navigator.of(ctx).pop(_createDefaultConversation(name));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _conversations.insert(0, result);
        _filteredConversations = List.from(_conversations);
      });
      await _saveConversations(_conversations);
      _showSnackBar('New contact added', successColor);
    }
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return 'New';

    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deleteConversation(int index) async {
    final contactName = _filteredConversations[index]['name'];
    final originalIndex = _conversations.indexWhere(
      (conv) => conv['name'] == contactName,
    );

    if (originalIndex != -1 && mounted) {
      setState(() {
        _conversations.removeAt(originalIndex);
        _filteredConversations.removeAt(index);
      });

      await _saveConversations(_conversations);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$contactName');

      _showSnackBar('Conversation deleted', errorColor);
    }
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

  //navigation method that uses the callback system
  void _navigateToChat(String contactName, {String? mode}) async {
    HapticFeedback.selectionClick();

    try {
      // Use callback to switch to chat tab with selected contact
      if (widget.onContactSelected != null) {
        widget.onContactSelected!(contactName, mode: mode);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showSnackBar('Could not open conversation', errorColor);
    }
  }

  //Method to show navigation options
  void _showNavigationOptions(String contactName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width,
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
        child: SingleChildScrollView(
          // Added scroll view to prevent overflow
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
              // Wrapped text in Flexible to prevent overflow
              Flexible(
                child: Text(
                  'Chat with $contactName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationOption(
                icon: Icons.chat_rounded,
                title: 'View Messages',
                subtitle: 'See conversation history',
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onConversationDetailRequested != null) {
                    widget.onConversationDetailRequested!(contactName);
                  }
                },
              ),
              _buildNavigationOption(
                icon: Icons.keyboard_rounded,
                title: 'Text Chat',
                subtitle: 'Start typing messages',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChat(contactName, mode: 'text');
                },
              ),
              _buildNavigationOption(
                icon: Icons.mic_rounded,
                title: 'Voice Chat',
                subtitle: 'Start voice conversation',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChat(contactName, mode: 'mic');
                },
              ),
              _buildNavigationOption(
                icon: Icons.sign_language_rounded,
                title: 'FSL Chat',
                subtitle: 'Use Filipino Sign Language',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChat(contactName, mode: 'fsl');
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis, // Added overflow handling
          maxLines: 1, // Limit to single line
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _filteredConversations.isEmpty && _searchController.text.isNotEmpty
                ? 'No matches found'
                : 'No conversations yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _filteredConversations.isEmpty && _searchController.text.isNotEmpty
                ? 'Try searching with different keywords'
                : 'Tap the "New Chat" button to start\nyour first conversation',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.7),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTypeIndicators(Map<String, dynamic> conversation) {
    List<Widget> indicators = [];

    if (conversation['hasVoiceMessages'] == true) {
      indicators.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_rounded, size: 12, color: accentColor),
              SizedBox(width: 2),
              Text('Voice', style: TextStyle(fontSize: 10, color: accentColor)),
            ],
          ),
        ),
      );
    }

    if (conversation['hasFSLMessages'] == true) {
      indicators.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentSecondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentSecondary.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sign_language_rounded,
                size: 12,
                color: accentSecondary,
              ),
              SizedBox(width: 2),
              Text(
                'FSL',
                style: TextStyle(fontSize: 10, color: accentSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (indicators.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 4, children: indicators);
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation, int index) {
    return Dismissible(
      key: Key('${conversation['name']}_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) =>
          _showDeleteConfirmation(conversation['name']),
      onDismissed: (direction) => _deleteConversation(index),
      background: _buildDismissBackground(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryMedium.withOpacity(0.8),
              primaryLight.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToChat(conversation['name']),
            onLongPress: () => _showNavigationOptions(conversation['name']),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAvatar(conversation['name']),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                conversation['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.2),
                                    accentSecondary.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _formatTime(
                                  conversation['lastMessageTime'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (conversation['lastMessageType'] == 'voice')
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.mic_rounded,
                                  size: 14,
                                  color: accentColor,
                                ),
                              )
                            else if (conversation['lastMessageType'] == 'fsl')
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.sign_language_rounded,
                                  size: 14,
                                  color: accentSecondary,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                conversation['preview'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMessageTypeIndicators(conversation),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${conversation['messageCount'] ?? 0} msgs',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildChatButton(conversation['name']),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildAvatar(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getAvatarColor(name),
            _getAvatarColor(name).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildChatButton(String contactName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [accentColor, accentSecondary]),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToChat(contactName),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.chat_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [errorColor.withOpacity(0.8), errorColor],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
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
        backgroundColor: primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: errorColor.withOpacity(0.3), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: errorColor, size: 24),
            SizedBox(width: 16),
            Text(
              'Delete Conversation?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
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
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(ctx).pop(true);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: primaryDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryMedium, primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
                SizedBox(height: 24),
                Text(
                  'Loading conversations...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryDark, primaryMedium, primaryLight],
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
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Tinig-Kamay History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.2),
                            accentSecondary.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_conversations.length} contact${_conversations.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              if (_conversations.isNotEmpty) _buildSearchBar(),

              // Content
              Expanded(
                child: _filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          return _buildConversationCard(
                            _filteredConversations[index],
                            index,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [accentColor, accentSecondary]),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _addNewConversation,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_comment_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'New Chat',
                    style: TextStyle(
                      color: Colors.white,
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
