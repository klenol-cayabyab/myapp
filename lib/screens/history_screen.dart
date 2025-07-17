import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> conversations = [
    {'name': 'Juan Dela Cruz', 'message': 'Kumusta po!'},
    {'name': 'Maria Santos', 'message': 'Salamat!'},
    {'name': 'Carlos Reyes', 'message': 'Paalam muna!'},
  ];

  void _deleteConversation(int index) {
    setState(() {
      conversations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Conversation History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final convo = conversations[index];
                  return Card(
                    color: Colors.white10,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.yellow,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(
                        convo['name'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        convo['message'] ?? '',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteConversation(index),
                      ),
                      onTap: () {
                        // Optional: Navigate to full conversation screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped ${convo['name']}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
