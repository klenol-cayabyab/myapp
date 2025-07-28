import 'dart:ui';
import 'package:flutter/material.dart';

/// Settings Screen Widget for Tinig-Kamay Communication Platform
/// This screen provides user configuration options including Bluetooth connectivity,
/// language selection, notifications, and account management
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State class for SettingsScreen with TickerProviderStateMixin for animations
class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // State variables for user preferences and settings
  bool isBluetoothConnected =
      false; // Tracks Tinig-Kamay glove connection status
  String selectedLanguage = 'Tagalog'; // Currently selected app language
  bool isNotificationsEnabled = true; // Toggle for app notifications

  // Animation controllers for smooth UI transitions
  late AnimationController _animationController; // Controls fade-in animation
  late Animation<double> _fadeAnimation; // Fade animation for screen entrance

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation for smooth screen entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start the fade-in animation when screen loads
    _animationController.forward();
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  /// Toggles Bluetooth connection to Tinig-Kamay glove
  /// Simulates connecting/disconnecting from the hardware device
  /// Shows feedback snackbar to inform user of connection status
  void toggleBluetoothConnection() {
    setState(() {
      isBluetoothConnected = !isBluetoothConnected;
    });

    // Show feedback snackbar with connection status
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

  /// Shows modal bottom sheet for language selection
  /// Displays available languages (Tagalog, English) with glassmorphism design
  /// Updates selectedLanguage state when user makes a choice
  void showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // Glassmorphism effect
          child: Container(
            decoration: BoxDecoration(
              // Gradient background with transparency for glassmorphism
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
                // Handle bar for modal sheet
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                // Modal title
                const Text(
                  'Select Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Language options list
                ...['Tagalog', 'English'].map(
                  (language) => ListTile(
                    leading: Icon(
                      Icons.language,
                      color: selectedLanguage == language
                          ? Colors
                                .yellow
                                .shade300 // Highlight selected language
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
                      // Update selected language and close modal
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

  /// Navigates to contact management screen (history screen)
  /// Shows confirmation feedback to user about the navigation
  void navigateToManageContacts() {
    // Navigate to history screen (which shows contacts/conversations)
    Navigator.pushNamed(context, '/history');

    // Show confirmation snackbar with delay for better UX
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

  /// Shows logout confirmation dialog and handles user logout
  /// Clears navigation stack and redirects to login screen
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
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          // Confirm logout button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              // Navigate to login and clear all previous routes
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false, // Remove all previous routes
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

  /// Builds a glassmorphism-style card container for settings sections
  /// Provides consistent styling across all settings cards
  /// Parameters:
  /// - child: Widget to be displayed inside the card
  /// - padding: Optional custom padding (defaults to 16px all around)
  Widget _buildSettingsCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // Glassmorphism blur effect
          child: Container(
            decoration: BoxDecoration(
              // Semi-transparent gradient for glassmorphism effect
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
      backgroundColor: const Color(0xFF0A1A2E), // Dark blue background
      extendBodyBehindAppBar: true, // Allow content behind transparent app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Custom back button with proper navigation logic
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Ensure proper navigation back to home or previous screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        // Gradient overlay for app bar
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
        // Main background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation, // Fade-in animation for entire content
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics:
                          const BouncingScrollPhysics(), // iOS-style bounce scroll
                      child: Column(
                        children: [
                          // Bluetooth Connection Card
                          // Manages connection to Tinig-Kamay glove device
                          _buildSettingsCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Bluetooth icon with gradient background
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
                                    // Device name and connection status
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
                                    // Connect/Disconnect button
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
                          // Contains language and notification preferences
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
                                // Language selection option
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
                                    selectedLanguage, // Shows current language
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap:
                                      showLanguageSelector, // Opens language selector
                                ),
                                const Divider(color: Colors.white24),
                                // Notification toggle option
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
                          // Contains frequently used actions like contacts and logout
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
                                // Manage contacts option
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
                                  onTap:
                                      navigateToManageContacts, // Navigate to contacts
                                ),
                                const Divider(color: Colors.white24),
                                // Logout option
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
                                  onTap: logout, // Show logout confirmation
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
