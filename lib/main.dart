import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/conversation_detail_screen.dart';

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
        scaffoldBackgroundColor: Color(0xFF083D77), // dark blue
        fontFamily: 'Arial', // or use custom font
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      // Define named routes
      routes: {
        '/home': (context) => HomeScreen(),
        '/chat': (context) => HomeScreen(initialIndex: 0), // Go to Chat tab
        '/history': (context) =>
            HomeScreen(initialIndex: 1), // Go to History tab
        '/settings': (context) =>
            HomeScreen(initialIndex: 2), // Go to Settings tab
      },
      // Handle route generation for complex navigation
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/conversation':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ConversationDetailScreen(
                contactName: args?['contactName'] ?? 'Unknown',
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  static List<Widget> _widgetOptions = <Widget>[
    ChatScreen(), // ✅ Replaces SpeechToText + FSL screens
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handle navigation from other screens
  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to maintain state
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
        backgroundColor: Color(0xFF062e5c),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensure all tabs are visible
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
