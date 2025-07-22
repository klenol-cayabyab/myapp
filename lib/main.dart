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
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) =>
                ChatScreen(selectedContact: args?['contactName'] ?? 'Unknown'),
          );
        }
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              contactName: args?['contactName'] ?? 'Unknown',
            ),
          );
        }
        return null;
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
        index: _selectedIndex,
        children: [
          ChatScreen(selectedContact: 'Default Contact'),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
        backgroundColor: Color(0xFF062e5c),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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
