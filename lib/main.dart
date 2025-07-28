import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/conversation_detail_screen.dart';
import 'screens/login_screen.dart';

/// Entry point of the Tinig-Kamay Flutter application
/// Initializes and runs the main app widget
void main() {
  runApp(TinigKamayApp());
}

/// Root application widget for Tinig-Kamay Communication Platform
/// Configures app-wide settings including theme, routing, and initial screen
class TinigKamayApp extends StatelessWidget {
  const TinigKamayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinig-Kamay', // App name displayed in task switcher
      theme: ThemeData(
        primarySwatch: Colors.blue, // Primary color palette
        scaffoldBackgroundColor: Color(0xFF083D77), // Default background color
        fontFamily: 'Arial', // App-wide font family
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner in debug mode
      initialRoute: '/login', // App starts with login screen
      // Route definitions for navigation throughout the app
      routes: {
        '/login': (context) => const LoginScreen(), // Authentication screen
        '/': (context) => const HomeScreen(), // Default home route
        '/home': (context) => const HomeScreen(), // Explicit home route
        '/history': (context) =>
            const HomeScreen(initialIndex: 1), // Direct to history tab
        '/settings': (context) =>
            const HomeScreen(initialIndex: 2), // Direct to settings tab
      },
    );
  }
}

/// Main home screen widget with bottom navigation
/// Manages the three main sections: Chat, History, and Settings
/// Handles state management for contact selection and navigation between screens
class HomeScreen extends StatefulWidget {
  final int
  initialIndex; // Which tab to show initially (0=Chat, 1=History, 2=Settings)
  final String? selectedContact; // Pre-selected contact for chat screen
  final String? chatMode; // Initial chat mode (text/voice/gesture)

  const HomeScreen({
    super.key,
    this.initialIndex = 0, // Default to Chat tab
    this.selectedContact, // Optional contact selection
    this.chatMode, // Optional chat mode
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

/// State class for HomeScreen managing navigation and contact selection
class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex; // Currently active bottom navigation tab
  String _currentContact =
      'Default Contact'; // Currently selected contact for chat
  String? _currentChatMode; // Current communication mode (text/voice/gesture)

  // Color scheme constants for consistent theming
  static const Color primaryDark = Color(
    0xFF0A1628,
  ); // Dark blue for backgrounds
  static const Color primaryMedium = Color(
    0xFF1E3A5F,
  ); // Medium blue for gradients
  static const Color accentColor = Color(
    0xFF00D4FF,
  ); // Cyan accent for highlights

  @override
  void initState() {
    super.initState();

    // Initialize screen state from widget parameters
    _selectedIndex = widget.initialIndex;

    // Set initial contact if provided
    if (widget.selectedContact != null) {
      _currentContact = widget.selectedContact!;
    }

    // Set initial chat mode if provided
    if (widget.chatMode != null) {
      _currentChatMode = widget.chatMode;
    }
  }

  /// Handles bottom navigation bar tap events
  /// Updates the selected tab and resets chat mode when switching tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Clear chat mode when switching tabs to prevent mode conflicts
      _currentChatMode = null;
    });
  }

  /// Handles contact selection from history screen
  /// Switches to chat tab and sets the selected contact and mode
  /// Parameters:
  /// - contactName: Name of the contact to chat with
  /// - mode: Optional communication mode (text/voice/gesture)
  void _onContactSelected(String contactName, {String? mode}) {
    setState(() {
      _selectedIndex = 0; // Switch to Chat tab
      _currentContact = contactName; // Set selected contact
      _currentChatMode = mode; // Set chat mode if provided
    });
  }

  /// Navigates to conversation detail screen
  /// Shows detailed conversation history for a specific contact
  /// Parameters:
  /// - contactName: Name of the contact whose conversation to view
  void _navigateToConversationDetail(String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailScreen(
          contactName: contactName,
          // Callback to return to chat with selected contact and mode
          onBackToChat: (contact, mode) {
            _onContactSelected(contact, mode: mode);
          },
        ),
      ),
    );
  }

  /// Returns the appropriate screen widget based on selected tab index
  /// Manages screen switching and passes required parameters to each screen
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0: // Chat Screen
        return ChatScreen(
          selectedContact: _currentContact, // Pass current contact
          initialMode: _currentChatMode, // Pass current chat mode
          // Callback to update contact when changed within chat screen
          onContactChange: (contact) {
            setState(() {
              _currentContact = contact;
            });
          },
        );

      case 1: // History Screen
        return HistoryScreen(
          onContactSelected: _onContactSelected, // Contact selection callback
          onConversationDetailRequested:
              _navigateToConversationDetail, // Detail navigation callback
        );

      case 2: // Settings Screen
        return SettingsScreen();

      default: // Fallback to Chat Screen
        return ChatScreen(
          selectedContact: _currentContact,
          initialMode: _currentChatMode,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(), // Display current screen based on selected tab
      // Custom bottom navigation bar with gradient background and styling
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          // Gradient background from medium to dark blue
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryMedium, primaryDark],
          ),
          // Shadow effect for depth
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 15,
              offset: Offset(0, -5), // Shadow above the navigation bar
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, // Currently selected tab
          selectedItemColor: accentColor, // Cyan color for selected items
          unselectedItemColor: Color.fromRGBO(
            255,
            255,
            255,
            0.6,
          ), // Semi-transparent white for unselected
          backgroundColor: Colors.transparent, // Transparent to show gradient
          elevation: 0, // No additional shadow
          onTap: _onItemTapped, // Handle tab selection
          type: BottomNavigationBarType
              .fixed, // Fixed layout for consistent spacing
          // Text styling for navigation labels
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, // Bold text for selected tab
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400, // Normal weight for unselected tabs
            fontSize: 11,
          ),

          // Navigation bar items with custom styling
          items: [
            // Chat Tab
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 0
                    ? BoxDecoration(
                        // Highlight background for selected tab
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null, // No decoration for unselected tabs
                child: const Icon(
                  Icons.mic_rounded,
                ), // Microphone icon for chat
              ),
              label: 'Chat',
            ),

            // History Tab
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 1
                    ? BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: const Icon(Icons.history_rounded), // History icon
              ),
              label: 'History',
            ),

            // Settings Tab
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 2
                    ? BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: const Icon(Icons.settings_rounded), // Settings gear icon
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
