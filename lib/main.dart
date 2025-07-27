import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/conversation_detail_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(TinigKamayApp());
}

class TinigKamayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinig-Kamay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF083D77),
        fontFamily: 'Arial',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HomeScreen(initialIndex: 1),
        '/settings': (context) => const HomeScreen(initialIndex: 2),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final String? selectedContact;
  final String? chatMode;

  const HomeScreen({
    Key? key,
    this.initialIndex = 0,
    this.selectedContact,
    this.chatMode,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String _currentContact = 'Default Contact';
  String? _currentChatMode;

  //color scheme
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryMedium = Color(0xFF1E3A5F);
  static const Color accentColor = Color(0xFF00D4FF);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (widget.selectedContact != null) {
      _currentContact = widget.selectedContact!;
    }
    if (widget.chatMode != null) {
      _currentChatMode = widget.chatMode;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Clear chat mode when switching tabs
      _currentChatMode = null;
    });
  }

  // Method to handle contact selection from history
  void _onContactSelected(String contactName, {String? mode}) {
    setState(() {
      _selectedIndex = 0;
      _currentContact = contactName;
      _currentChatMode = mode;
    });
  }

  //Method to handle conversation detail navigation
  void _navigateToConversationDetail(String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailScreen(
          contactName: contactName,
          onBackToChat: (contact, mode) {
            _onContactSelected(contact, mode: mode);
          },
        ),
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return ChatScreen(
          selectedContact: _currentContact,
          initialMode: _currentChatMode,
          onContactChange: (contact) {
            setState(() {
              _currentContact = contact;
            });
          },
        );
      case 1:
        return HistoryScreen(
          onContactSelected: _onContactSelected,
          onConversationDetailRequested: _navigateToConversationDetail,
        );
      case 2:
        return SettingsScreen();
      default:
        return ChatScreen(
          selectedContact: _currentContact,
          initialMode: _currentChatMode,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryMedium, primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 15,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: accentColor,
          unselectedItemColor: Color.fromRGBO(255, 255, 255, 0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 0
                    ? BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: const Icon(Icons.mic_rounded),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 1
                    ? BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: const Icon(Icons.history_rounded),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _selectedIndex == 2
                    ? BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: const Icon(Icons.settings_rounded),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
