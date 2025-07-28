import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Main widget for displaying conversation history
// This is a StatefulWidget because it needs to manage dynamic data like conversations list
class HistoryScreen extends StatefulWidget {
  // Callback functions to communicate with parent widget (navigation)
  final Function(String, {String? mode})?
  onContactSelected; // Called when user selects a contact to chat with
  final Function(String)?
  onConversationDetailRequested; // Called when user wants to view conversation details

  const HistoryScreen({
    super.key,
    this.onContactSelected,
    this.onConversationDetailRequested,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// State class that handles all the logic and UI for the history screen
class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  // Keeps the widget alive even when switching tabs (performance optimization)
  @override
  bool get wantKeepAlive => true;

  // STATE VARIABLES - Store the app's data
  List<Map<String, dynamic>> _conversations =
      []; // All conversations loaded from storage
  List<Map<String, dynamic>> _filteredConversations =
      []; // Filtered conversations based on search
  bool _isLoading = true; // Loading state indicator

  // Controller for the search input field
  final TextEditingController _searchController = TextEditingController();

  // COLOR SCHEME - Defines the app's visual theme
  static const Color primaryDark = Color(0xFF0A1628); // Dark blue background
  static const Color primaryMedium = Color(0xFF1E3A5F); // Medium blue for cards
  static const Color primaryLight = Color(
    0xFF2D5A87,
  ); // Light blue for gradients
  static const Color accentColor = Color(0xFF00D4FF); // Cyan for highlights
  static const Color accentSecondary = Color(
    0xFF7C3AED,
  ); // Purple for secondary elements
  static const Color successColor = Color(
    0xFF10B981,
  ); // Green for success messages
  static const Color warningColor = Color(0xFFF59E0B); // Orange for warnings
  static const Color errorColor = Color(0xFFEF4444); // Red for errors

  // INITIALIZATION - Called when widget is first created
  @override
  void initState() {
    super.initState();
    _loadConversations(); // Load saved conversations from device storage
    _searchController.addListener(
      _onSearchChanged,
    ); // Listen for search input changes
  }

  // CLEANUP - Called when widget is destroyed
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // SEARCH FUNCTIONALITY - Filters conversations based on user input
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (mounted) {
      // Check if widget is still active
      setState(() {
        if (query.isEmpty) {
          // Show all conversations if search is empty
          _filteredConversations = List.from(_conversations);
        } else {
          // Filter conversations by name or message preview
          _filteredConversations = _conversations.where((conversation) {
            final name = conversation['name'].toString().toLowerCase();
            final preview = conversation['preview'].toString().toLowerCase();
            return name.contains(query) || preview.contains(query);
          }).toList();
        }
      });
    }
  }

  // DATA LOADING - Retrieves conversations from device storage
  Future<void> _loadConversations() async {
    if (!mounted) return; // Exit if widget is no longer active

    try {
      // Access device's local storage
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('conversations_list');

      List<Map<String, dynamic>> loadedConversations = [];

      if (conversationsJson != null) {
        // Parse saved conversations from JSON
        final List<dynamic> conversationsList = json.decode(conversationsJson);

        // Enhance each conversation with message statistics
        for (var item in conversationsList) {
          Map<String, dynamic> conversation = Map<String, dynamic>.from(item);
          String contactName = conversation['name'];

          // Get detailed message information for this contact
          Map<String, dynamic> messageInfo = await _getLastMessageInfo(
            contactName,
          );

          // Add message statistics to conversation data
          conversation.addAll({
            'messageCount': messageInfo['count'], // Total number of messages
            'lastMessageType':
                messageInfo['type'], // Type of last message (text/voice/fsl)
            'hasVoiceMessages':
                messageInfo['hasVoice'], // Whether conversation has voice messages
            'hasFSLMessages':
                messageInfo['hasFSL'], // Whether conversation has FSL messages
            'lastMessageTime':
                messageInfo['lastTime'], // Timestamp of last message
          });

          loadedConversations.add(conversation);
        }
      } else {
        // First time app launch - create default contacts
        loadedConversations = [
          _createDefaultConversation('Klenol Cayabyab'),
          _createDefaultConversation('Gello Gadaingan'),
          _createDefaultConversation('Lance Alog'),
          _createDefaultConversation('Renz Atienza'),
          _createDefaultConversation('Gian'),
          _createDefaultConversation('Vhon'),
        ];
        await _saveConversations(loadedConversations); // Save to storage
      }

      // Sort conversations by most recent activity
      loadedConversations.sort((a, b) {
        final aTime = a['lastMessageTime'] ?? 0;
        final bTime = b['lastMessageTime'] ?? 0;
        return bTime.compareTo(aTime); // Most recent first
      });

      // Update UI with loaded data
      if (mounted) {
        setState(() {
          _conversations = loadedConversations;
          _filteredConversations = List.from(loadedConversations);
          _isLoading = false; // Hide loading indicator
        });
      }
    } catch (e) {
      // Handle loading errors gracefully
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load conversations', errorColor);
      }
    }
  }

  // HELPER FUNCTION - Creates a default conversation structure
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

  // MESSAGE ANALYSIS - Analyzes stored messages to get conversation statistics
  Future<Map<String, dynamic>> _getLastMessageInfo(String contactName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString('messages_$contactName');

      if (messagesJson != null && messagesJson.isNotEmpty) {
        // Parse messages from JSON
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
          // Analyze message types in the conversation
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

    // Return default values if no messages found
    return {
      'count': 0,
      'type': 'text',
      'hasVoice': false,
      'hasFSL': false,
      'lastTime': 0,
    };
  }

  // DATA PERSISTENCE - Saves conversations to device storage
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

  // ADD NEW CONTACT - Shows dialog to create new conversation
  Future<void> _addNewConversation() async {
    HapticFeedback.lightImpact(); // Provide tactile feedback
    final TextEditingController nameController = TextEditingController();

    // Show dialog for entering contact name
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // User must tap button to close
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
                // Check for duplicate contact names
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

    // Add the new contact if dialog was completed
    if (result != null && mounted) {
      setState(() {
        _conversations.insert(0, result); // Add to top of list
        _filteredConversations = List.from(_conversations);
      });
      await _saveConversations(_conversations);
      _showSnackBar('New contact added', successColor);
    }
  }

  // TIME FORMATTING - Converts timestamp to human-readable format
  String _formatTime(int timestamp) {
    if (timestamp == 0) return 'New';

    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    // Format based on time elapsed
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

  // DELETE CONVERSATION - Removes conversation and its messages
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

      // Also delete the actual messages for this contact
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$contactName');

      _showSnackBar('Conversation deleted', errorColor);
    }
  }

  // NOTIFICATION SYSTEM - Shows temporary messages to user
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              // Choose icon based on message type
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

  // NAVIGATION HANDLER - Switches to chat screen with selected contact
  void _navigateToChat(String contactName, {String? mode}) async {
    HapticFeedback.selectionClick(); // Provide tactile feedback

    try {
      // Use callback to communicate with parent widget (main app)
      // This tells the main app to switch to chat tab with this contact
      if (widget.onContactSelected != null) {
        widget.onContactSelected!(contactName, mode: mode);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showSnackBar('Could not open conversation', errorColor);
    }
  }

  // CHAT OPTIONS MODAL - Shows different ways to interact with contact
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal handle bar
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Modal title
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
              // Different interaction options
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

  // UI COMPONENT - Builds individual option buttons in modal
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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

  // COLOR GENERATION - Creates consistent avatar colors based on name
  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFF8B5CF6), // Purple
      Color(0xFF10B981), // Green
      Color(0xFFF59E0B), // Orange
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[name.hashCode %
        colors.length]; // Use name hash for consistent color
  }

  // UI COMPONENT - Shows message when conversation list is empty
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state icon
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
          // Dynamic title based on search state
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
          // Dynamic subtitle with helpful guidance
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

  // UI COMPONENT - Search input field with dynamic clear button
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
          // Show clear button only when there's text
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

  // UI COMPONENT - Shows message type indicators (Voice/FSL badges)
  Widget _buildMessageTypeIndicators(Map<String, dynamic> conversation) {
    List<Widget> indicators = [];

    // Add Voice indicator if conversation has voice messages
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

    // Add FSL indicator if conversation has FSL messages
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

  // UI COMPONENT - Individual conversation card with swipe-to-delete
  Widget _buildConversationCard(Map<String, dynamic> conversation, int index) {
    return Dismissible(
      key: Key('${conversation['name']}_$index'),
      direction:
          DismissDirection.endToStart, // Only allow swiping from right to left
      confirmDismiss: (direction) =>
          _showDeleteConfirmation(conversation['name']),
      onDismissed: (direction) => _deleteConversation(index),
      background: _buildDismissBackground(), // Red background when swiping
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
            onTap: () => _navigateToChat(conversation['name']), // Quick chat
            onLongPress: () =>
                _showNavigationOptions(conversation['name']), // Show options
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAvatar(conversation['name']), // Contact avatar
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contact name and timestamp row
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
                            // Time badge
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
                        // Message preview with type icon
                        Row(
                          children: [
                            // Show icon based on last message type
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
                        // Bottom row with indicators and actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMessageTypeIndicators(
                              conversation,
                            ), // Voice/FSL badges
                            Row(
                              children: [
                                // Message count badge
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
                                _buildChatButton(
                                  conversation['name'],
                                ), // Quick chat button
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

  // UI COMPONENT - Circular avatar with contact's initial
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
          name.isNotEmpty ? name[0].toUpperCase() : '?', // First letter of name
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  // UI COMPONENT - Small chat button with gradient background
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

  // UI COMPONENT - Red background shown when swiping to delete
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

  // CONFIRMATION DIALOG - Asks user to confirm deletion
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
            onPressed: () => Navigator.of(ctx).pop(false), // Cancel deletion
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact(); // Strong vibration for destructive action
              Navigator.of(ctx).pop(true); // Confirm deletion
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

  // MAIN BUILD METHOD - Constructs the entire screen UI
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show loading screen while data is being loaded
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

    // Main screen layout
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
          // Ensures content doesn't overlap with system UI
          child: Column(
            children: [
              // HEADER SECTION - App title and contact count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    // Main title with icon
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
                    // Contact counter badge
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

              // SEARCH BAR - Only shown when there are conversations
              if (_conversations.isNotEmpty) _buildSearchBar(),

              // MAIN CONTENT AREA
              Expanded(
                child: _filteredConversations.isEmpty
                    ? _buildEmptyState() // Show empty state message
                    : ListView.builder(
                        // Show conversation list
                        padding: const EdgeInsets.only(bottom: 20),
                        physics:
                            const BouncingScrollPhysics(), // iOS-style scrolling
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
      // FLOATING ACTION BUTTON - Add new conversation
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
