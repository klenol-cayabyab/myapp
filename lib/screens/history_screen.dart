import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> messages = [
    {
      'name': 'Maria Santos',
      'preview': 'Hello! Kumusta ka na?',
      'time': '10:30 AM',
    },
    {
      'name': 'Juan Dela Cruz',
      'preview': 'Sige po, salamat!',
      'time': 'Yesterday',
    },
    {
      'name': 'Mark Reyes',
      'preview': 'Can we talk tomorrow?',
      'time': 'Jul 15',
    },
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    double titleFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    double nameFontSize = (screenWidth * 0.045).clamp(16.0, 20.0);
    double previewFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    double emptyFontSize = (screenWidth * 0.045).clamp(16.0, 20.0);

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 🟦 Header Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Conversation History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 📜 Message List
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            'No conversations yet.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: emptyFontSize,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            return Dismissible(
                              key: Key(message['name']! + index.toString()),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Are you sure?'),
                                    content: Text(
                                      'Do you really want to delete this conversation?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                setState(() {
                                  messages.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Conversation deleted'),
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade800,
                                    child: Text(
                                      message['name']![0],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          message['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: nameFontSize,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        message['time'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      message['preview'] ?? '',
                                      style: TextStyle(
                                        fontSize: previewFontSize,
                                        color: Colors.grey.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                  onTap: () {
                                    // TODO: Navigate to conversation detail screen
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ➕ Floating Add Button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  // TODO: Add contact form
                },
                backgroundColor: Colors.yellow,
                child: Icon(Icons.add, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
