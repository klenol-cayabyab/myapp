import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isBluetoothConnected = false;
  String selectedLanguage = 'Tagalog';

  void toggleBluetoothConnection() {
    setState(() {
      isBluetoothConnected = !isBluetoothConnected;
    });
  }

  void toggleLanguage() {
    setState(() {
      selectedLanguage = selectedLanguage == 'Tagalog' ? 'English' : 'Tagalog';
    });
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('You have been logged out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tinig-Kamay Glove',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: toggleBluetoothConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                  ),
                  child: Text(
                    isBluetoothConnected ? 'Connected' : 'Connect',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white54, height: 40),
            ListTile(
              leading: Icon(Icons.contacts, color: Colors.white),
              title: Text(
                'Add / Manage Contacts',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening contact manager...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: Colors.white),
              title: Text(
                'Language: $selectedLanguage',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: selectedLanguage == 'Tagalog',
                onChanged: (_) => toggleLanguage(),
                activeColor: Colors.yellow,
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}
