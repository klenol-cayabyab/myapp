// Import statements - Required packages for detailed conversation view
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:flutter/services.dart'; // For haptic feedback and system services
import 'package:shared_preferences/shared_preferences.dart'; // Local data storage
import 'dart:convert'; // For JSON encoding/decoding (message persistence)
import 'dart:async'; // For Timer functionality (auto-save feature)

// ConversationDetailScreen - Full conversation view with message history
// This screen shows all messages between user and a specific contact
class ConversationDetailScreen extends StatefulWidget {
  final String contactName; // Name of the contact being chatted with
  final Function(String, String?)?
  onBackToChat; // Callback to return to chat with specific mode

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
  // =============== LIFECYCLE MANAGEMENT ===============

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching screens

  // =============== CONTROLLERS AND VARIABLES ===============

  // Controllers - Made non-nullable for better memory management
  late final TextEditingController
  _messageController; // Controls message input field
  late final ScrollController
  _scrollController; // Controls message list scrolling

  // State variables for message management
  List<Map<String, dynamic>> _messages = []; // All messages in conversation
  bool _isLoading = true; // Loading state when fetching messages
  bool _isSaving = false; // Saving state indicator
  Timer? _saveTimer; // Timer for debounced auto-save
  bool _hasUnsavedChanges = false; // Track if there are unsaved changes
  late final String _messagesKey; // Unique storage key for this contact

  // =============== UI COLOR SCHEME ===============
  // Enhanced color scheme for modern UI design

  static const Color primaryDark = Color(0xFF0A1628); // Dark blue background
  static const Color primaryMedium = Color(
    0xFF1E3A5F,
  ); // Medium blue for surfaces
  static const Color primaryLight = Color(
    0xFF2D5A87,
  ); // Light blue for highlights
  static const Color accentColor = Color(0xFF00D4FF); // Cyan accent for buttons
  static const Color accentSecondary = Color(
    0xFF7C3AED,
  ); // Purple secondary accent
  static const Color successColor = Color(
    0xFF10B981,
  ); // Green for success messages
  static const Color warningColor = Color(0xFFF59E0B); // Orange for warnings
  static const Color errorColor = Color(
    0xFFEF4444,
  ); // Red for errors/delete actions

  // =============== INITIALIZATION AND CLEANUP ===============

  @override
  void initState() {
    super.initState();
    _messageController =
        TextEditingController(); // Initialize text input controller
    _scrollController = ScrollController(); // Initialize scroll controller
    WidgetsBinding.instance.addObserver(
      this,
    ); // Listen for app lifecycle changes
    _messagesKey =
        'messages_${widget.contactName}'; // Create unique storage key
    _loadMessages(); // Load existing messages from storage
  }

  @override
  void dispose() {
    _saveTimer?.cancel(); // Cancel any pending save operations
    if (_hasUnsavedChanges) {
      _saveMessagesSync(); // Save any unsaved changes before disposal
    }
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _messageController.dispose(); // Clean up text controller
    _scrollController.dispose(); // Clean up scroll controller
    super.dispose();
  }

  // Handle app lifecycle changes (minimize, close, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save messages when app is paused or closed
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveMessagesSync(); // Immediate save on app background/close
    }
  }

  // =============== MESSAGE LOADING AND PERSISTENCE ===============

  // Load messages from local storage for the current contact
  Future<void> _loadMessages() async {
    if (!mounted) return; // Prevent operations on disposed widget

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_messagesKey);

      List<Map<String, dynamic>> loadedMessages = [];

      // Parse stored messages if they exist
      if (messagesJson != null && messagesJson.isNotEmpty) {
        try {
          final List<dynamic> messagesList = json.decode(messagesJson);
          loadedMessages = messagesList
              .cast<Map<String, dynamic>>()
              .where(
                // Filter out empty messages
                (msg) =>
                    msg['text'] != null &&
                    msg['text'].toString().trim().isNotEmpty,
              )
              .toList();
        } catch (e) {
          debugPrint('Error parsing messages JSON: $e');
          loadedMessages = []; // Reset to empty if parsing fails
        }
      }

      // Update UI with loaded messages
      if (mounted) {
        setState(() {
          _messages = loadedMessages;
          _isLoading = false;
        });

        // Auto-scroll to bottom after messages load
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

  // =============== AUTO-SAVE FUNCTIONALITY ===============

  // Debounced save - waits 800ms after last change before saving
  void _debouncedSave() {
    _hasUnsavedChanges = true;
    _saveTimer?.cancel(); // Cancel previous timer
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _saveMessagesAsync(); // Save after delay
    });
  }

  // Asynchronous save operation with loading state
  Future<void> _saveMessagesAsync() async {
    if (!mounted || _isSaving) return; // Prevent multiple simultaneous saves

    setState(() => _isSaving = true); // Show saving indicator

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = json.encode(_messages); // Convert messages to JSON
      await prefs.setString(
        _messagesKey,
        messagesJson,
      ); // Store in local storage
      _hasUnsavedChanges = false; // Mark as saved
    } catch (e) {
      debugPrint('Error saving messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // Hide saving indicator
      }
    }
  }

  // Synchronous save for immediate operations (app close, navigation)
  void _saveMessagesSync() {
    if (!_hasUnsavedChanges) return;

    SharedPreferences.getInstance().then((prefs) {
      try {
        final messagesJson = json.encode(_messages);
        prefs.setString(_messagesKey, messagesJson);
        _hasUnsavedChanges = false;
      } catch (e) {
        debugPrint('Error in sync save: $e');
      }
    });
  }

  // =============== UI INTERACTION METHODS ===============

  // Smooth scroll to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // Scroll to end
        duration: const Duration(milliseconds: 300), // Smooth animation
        curve: Curves.easeOut, // Easing curve for natural feel
      );
    }
  }

  // Send a new text message
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return; // Don't send empty messages

    // Create new message object
    final newMessage = {
      'text': messageText,
      'isUser': true, // Always from user in this screen
      'timestamp': DateTime.now().millisecondsSinceEpoch, // Current timestamp
      'id':
          '${DateTime.now().millisecondsSinceEpoch}_${_messages.length}', // Unique ID
      'type': 'text', // Message type (text/voice/fsl)
    };

    setState(() => _messages.add(newMessage)); // Add to messages list
    _messageController.clear(); // Clear input field
    _debouncedSave(); // Save with debounce

    // Auto-scroll to show new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });

    _showMessageSent(); // Show confirmation feedback
  }

  // Show success feedback when message is sent
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
        duration: const Duration(milliseconds: 1000),
        backgroundColor: successColor, // Green confirmation
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Handle back button press - save before leaving
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      await _saveMessagesAsync(); // Save before navigating away
    }
    return true; // Allow navigation
  }

  // =============== OPTIONS MENU AND DIALOGS ===============

  // Show bottom sheet with conversation options
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.35, // Max 35% of screen
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryMedium, primaryDark], // Gradient background
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar at top of bottom sheet
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Menu options
            _buildMenuOption(
              icon: Icons.clear_all_rounded,
              title: 'Clear Chat',
              subtitle: 'Remove all messages',
              iconColor: warningColor, // Orange for warning action
              onTap: () {
                Navigator.pop(context);
                _showClearDialog(); // Show confirmation dialog
              },
            ),
            _buildMenuOption(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Conversation',
              subtitle: 'Cannot be undone',
              iconColor: errorColor, // Red for destructive action
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(); // Show confirmation dialog
              },
            ),
            _buildMenuOption(
              icon: Icons.info_outline_rounded,
              title: 'Message Count',
              subtitle: '${_messages.length} messages',
              iconColor: accentColor, // Info color
              onTap: () => Navigator.pop(context), // Just close menu
            ),
          ],
        ),
      ),
    );
  }

  // Build individual menu option with icon and description
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
        color: Colors.white.withOpacity(0.1), // Semi-transparent background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2), // Colored background for icon
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

  // Show confirmation dialog for clearing all messages
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
            onPressed: () => Navigator.pop(context), // Cancel action
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _messages.clear()); // Clear all messages
              await _saveMessagesAsync(); // Save empty list
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar(
                  'Chat cleared',
                  warningColor,
                ); // Show confirmation
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

  // Show confirmation dialog for deleting entire conversation
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
            onPressed: () => Navigator.pop(context), // Cancel action
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(
                _messagesKey,
              ); // Delete from storage completely
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
                _showSnackBar(
                  'Conversation deleted',
                  errorColor,
                ); // Show confirmation
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

  // Generic snackbar for showing status messages
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              // Choose icon based on color/context
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
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // =============== UTILITY METHODS ===============

  // Format timestamp for display (shows time or date based on age)
  String _formatTimestamp(dynamic timestamp) {
    DateTime date;

    // Handle different timestamp formats
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        date = DateTime.now(); // Fallback to now
      }
    } else {
      date = DateTime.now(); // Fallback to now
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    // Show only time if message is from today, otherwise show date + time
    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // =============== NAVIGATION METHODS ===============
  // These methods handle returning to chat screen with specific modes

  // Return to chat screen in microphone/voice mode
  Future<void> _handleMicPress() async {
    HapticFeedback.lightImpact(); // Tactile feedback

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync(); // Save before navigation
    }

    if (!mounted) return;

    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'mic'); // Switch to mic mode
      Navigator.pop(context); // Return to chat screen
    }
  }

  // Return to chat screen in FSL (Filipino Sign Language) mode
  Future<void> _handleFSLPress() async {
    HapticFeedback.lightImpact(); // Tactile feedback

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync(); // Save before navigation
    }

    if (!mounted) return;

    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'fsl'); // Switch to FSL mode
      Navigator.pop(context); // Return to chat screen
    }
  }

  // Return to chat screen in text mode
  Future<void> _handleTextPress() async {
    HapticFeedback.lightImpact(); // Tactile feedback

    if (_hasUnsavedChanges) {
      await _saveMessagesAsync(); // Save before navigation
    }

    if (!mounted) return;

    if (widget.onBackToChat != null) {
      widget.onBackToChat!(widget.contactName, 'text'); // Switch to text mode
      Navigator.pop(context); // Return to chat screen
    }
  }

  // =============== UI BUILDING METHODS ===============

  // Build icon indicator for different message types
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
        return const SizedBox.shrink(); // No icon for text messages
    }
  }

  // Build loading state UI while messages are being loaded
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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

  // Build empty state UI when no messages exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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

  // Build individual message bubble with proper styling based on type
  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isUser = message['isUser'] ?? false; // Whether message is from user
    final timestamp =
        message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final messageType =
        message['type'] ?? 'text'; // Message type (text/voice/fsl)
    final text = message['text']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment
                  .end // User messages align right
            : CrossAxisAlignment.start, // System messages align left
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width *
                        0.75, // Max 75% width
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    // Different gradients based on message type and sender
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
                                  colors: [
                                    accentColor,
                                    accentSecondary,
                                  ], // Default user gradient
                                ))
                        : null,
                    color: isUser
                        ? null
                        : Colors.white.withOpacity(
                            0.95,
                          ), // System message color
                    // Asymmetric border radius for chat bubble effect
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(
                              6,
                            ), // Sharp corner on sender side
                      bottomRight: isUser
                          ? const Radius.circular(
                              6,
                            ) // Sharp corner on sender side
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        // Shadow color matches message type
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
                      // Show message type icon for non-text messages
                      if (messageType != 'text')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildMessageTypeIcon(messageType),
                        ),
                      // Message text with appropriate styling
                      Text(
                        text,
                        style: TextStyle(
                          color: isUser
                              ? (messageType == 'voice'
                                    ? Colors.black87
                                    : messageType == 'fsl'
                                    ? Colors.black87
                                    : Colors
                                          .white) // White text on colored background
                              : Colors
                                    .grey
                                    .shade800, // Dark text on light background
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
          // Timestamp below message
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

  // =============== MAIN BUILD METHOD ===============

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        backgroundColor: primaryDark, // Dark theme background
        // Custom app bar with contact info and actions
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryMedium, primaryLight], // Gradient header
              ),
            ),
          ),
          // Custom back button with styling
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
                await _saveMessagesAsync(); // Save before going back
              }
              if (mounted) Navigator.pop(context);
            },
          ),
          // App bar title with contact avatar and info
          title: Row(
            children: [
              // Contact avatar with gradient background
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
                        ? widget.contactName[0]
                              .toUpperCase() // First letter of name
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
              // Contact name and message count
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
                    // Show message count if messages exist
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
          // App bar actions
          actions: [
            // Saving indicator (shows when auto-saving)
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
            // Options menu button
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
              onPressed: _showOptionsMenu, // Show options bottom sheet
            ),
          ],
        ),
        // Main body with messages and input
        body: Column(
          children: [
            // Messages display area
            Expanded(
              child: _isLoading
                  ? _buildLoadingState() // Show loading spinner
                  : _messages.isEmpty
                  ? _buildEmptyState() // Show empty state message
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      physics:
                          const BouncingScrollPhysics(), // iOS-style scrolling
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index], index);
                      },
                    ),
            ),
            // Bottom input area with mode switching buttons and text input
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
                    offset: const Offset(0, -2), // Shadow above the container
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Text Chat Mode Button - Returns to chat screen in text mode
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentSecondary],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: IconButton(
                        onPressed: _handleTextPress, // Switch to text mode
                        icon: const Icon(
                          Icons.keyboard_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Text chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Microphone Mode Button - Returns to chat screen in voice mode
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.9),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: IconButton(
                        onPressed: _handleMicPress, // Switch to mic mode
                        icon: const Icon(
                          Icons.mic_rounded,
                          color: Colors.black87,
                        ),
                        tooltip: 'Voice chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FSL Mode Button - Returns to chat screen in FSL mode
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
                      ),
                      child: IconButton(
                        onPressed: _handleFSLPress, // Switch to FSL mode
                        icon: const Icon(
                          Icons.sign_language_rounded,
                          color: Colors.black87,
                        ),
                        tooltip: 'FSL chat mode',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text input field - For typing new messages
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
                            hintText: 'Type a message...', // Placeholder text
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
                          onSubmitted: (_) =>
                              _sendMessage(), // Send on Enter key
                          maxLines: 1, // Single line to prevent layout issues
                          textCapitalization: TextCapitalization
                              .sentences, // Auto-capitalize sentences
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button - Sends the typed message
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
                        onPressed: _sendMessage, // Send message function
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
