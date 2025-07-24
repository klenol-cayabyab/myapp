import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool isBluetoothConnected = false;
  String selectedLanguage = 'Tagalog';
  bool isNotificationsEnabled = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleBluetoothConnection() {
    setState(() {
      isBluetoothConnected = !isBluetoothConnected;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isBluetoothConnected ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isBluetoothConnected
                    ? 'Successfully connected to Tinig-Kamay Glove!'
                    : 'Disconnected from glove',
              ),
            ],
          ),
          backgroundColor: isBluetoothConnected ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A1A2E).withOpacity(0.9),
                  const Color(0xFF16213E).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...['Tagalog', 'English'].map(
                  (language) => ListTile(
                    leading: Icon(
                      Icons.language,
                      color: selectedLanguage == language
                          ? Colors.yellow.shade300
                          : Colors.white54,
                    ),
                    title: Text(
                      language,
                      style: TextStyle(
                        color: selectedLanguage == language
                            ? Colors.yellow.shade300
                            : Colors.white,
                        fontWeight: selectedLanguage == language
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: selectedLanguage == language
                        ? Icon(Icons.check, color: Colors.yellow.shade300)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLanguage = language;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void navigateToManageContacts() {
    // Navigate to history screen (which shows contacts/conversations)
    Navigator.pushNamed(context, '/history');

    // Show confirmation snackbar
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.contacts, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Opening contact history...'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1A2E).withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.yellow.shade300),
            const SizedBox(width: 10),
            const Text('Logout', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              // Navigate to login and clear all previous routes
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Ensure proper navigation back
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A1A2E).withOpacity(0.9),
                const Color(0xFF0A1A2E).withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Bluetooth Connection Card
                          _buildSettingsCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.yellow.shade300.withOpacity(
                                              0.3,
                                            ),
                                            Colors.yellow.shade300.withOpacity(
                                              0.1,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.yellow.shade300
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.bluetooth,
                                        color: Colors.yellow.shade300,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tinig-Kamay Glove',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            isBluetoothConnected
                                                ? 'Connected'
                                                : 'Not Connected',
                                            style: TextStyle(
                                              color: isBluetoothConnected
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: toggleBluetoothConnection,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                (isBluetoothConnected
                                                        ? Colors.green
                                                        : Colors
                                                              .yellow
                                                              .shade300)
                                                    .withOpacity(0.2),
                                                (isBluetoothConnected
                                                        ? Colors.green
                                                        : Colors
                                                              .yellow
                                                              .shade300)
                                                    .withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (isBluetoothConnected
                                                          ? Colors.green
                                                          : Colors
                                                                .yellow
                                                                .shade300)
                                                      .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isBluetoothConnected
                                                    ? Icons.check
                                                    : Icons.bluetooth_searching,
                                                size: 18,
                                                color: isBluetoothConnected
                                                    ? Colors.green
                                                    : Colors.yellow.shade300,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isBluetoothConnected
                                                    ? 'Connected'
                                                    : 'Connect',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isBluetoothConnected
                                                      ? Colors.green
                                                      : Colors.yellow.shade300,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // App Settings Card
                          _buildSettingsCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'App Settings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.3),
                                          Colors.blue.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: Colors.blue.shade300,
                                    ),
                                  ),
                                  title: const Text(
                                    'Language',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    selectedLanguage,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: showLanguageSelector,
                                ),
                                const Divider(color: Colors.white24),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.withOpacity(0.3),
                                          Colors.orange.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.notifications,
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  title: const Text(
                                    'Notifications',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    'Receive alerts and updates',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: Switch(
                                    value: isNotificationsEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        isNotificationsEnabled = value;
                                      });
                                    },
                                    activeColor: Colors.yellow.shade300,
                                    activeTrackColor: Colors.yellow.shade300
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quick Actions Card
                          _buildSettingsCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.withOpacity(0.3),
                                          Colors.green.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.contacts,
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  title: const Text(
                                    'Manage Contacts',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    'View conversation history and contacts',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: navigateToManageContacts,
                                ),
                                const Divider(color: Colors.white24),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.3),
                                          Colors.red.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    'Sign out of your account',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: logout,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
