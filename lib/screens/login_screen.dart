import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Login Screen Widget for Tinig-Kamay Communication Platform
/// This is a StatefulWidget that provides user authentication interface
/// with animations, form validation, and user feedback
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State class for LoginScreen with TickerProviderStateMixin for animations
class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Controllers for managing text input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form key for validation management
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables for UI behavior
  bool _isPasswordVisible = false; // Controls password field visibility
  bool _isLoading = false; // Shows loading state during login
  bool _rememberMe = false; // Remember user credentials checkbox

  // Animation controllers and animations for UI effects
  late AnimationController _animationController; // Main fade-in animation
  late Animation<double> _fadeAnimation; // Fade effect for entire form
  late AnimationController _shakeController; // Shake animation for errors
  late Animation<double> _shakeAnimation; // Shake effect for form

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation for smooth screen entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize shake animation for error feedback
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Start the fade-in animation when screen loads
    _animationController.forward();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _animationController.dispose();
    _shakeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Triggers shake animation for form validation errors
  /// Provides visual feedback when login fails or validation errors occur
  void _shakeForm() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  /// Handles user login process with validation and feedback
  /// Includes haptic feedback and loading states for better UX
  Future<void> _login() async {
    // Validate form fields before proceeding
    if (!_formKey.currentState!.validate()) {
      _shakeForm(); // Show error animation
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Provide haptic feedback for button press
    HapticFeedback.lightImpact();

    // Simulate network delay (replace with actual API call)
    await Future.delayed(const Duration(seconds: 2));

    // Basic validation - replace with real authentication logic
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      // Success feedback
      HapticFeedback.mediumImpact();

      // Handle remember me functionality
      if (_rememberMe) {
        // TODO: Save credentials to SharedPreferences here
        _showSuccessSnackBar('Login successful! Credentials saved.');
      }

      // Navigate to home screen on successful login
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Error feedback for failed login
      HapticFeedback.heavyImpact();
      _shakeForm();
      _showErrorSnackBar('Invalid credentials. Please try again.');
    }

    // Hide loading state
    setState(() {
      _isLoading = false;
    });
  }

  /// Shows success message with green snackbar and check icon
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows error message with red snackbar and error icon
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows forgot password dialog with email input field
  /// Allows users to request password reset
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF083D77), // Match app theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a reset link.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            // Email input field for password reset
            TextField(
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          // Send reset link button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Reset link sent to your email!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
            ),
            child: const Text(
              'Send',
              style: TextStyle(color: Color(0xFF083D77)),
            ),
          ),
        ],
      ),
    );
  }

  /// Validates username input field
  /// Returns error message if validation fails, null if valid
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null; // Valid input
  }

  /// Validates password input field
  /// Returns error message if validation fails, null if valid
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null; // Valid input
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF083D77), // Primary blue color
      body: Container(
        // Gradient background for visual appeal
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF083D77), Color(0xFF0A4B8A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation, // Fade-in animation for entire form
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeAnimation.value,
                          0,
                        ), // Shake effect
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App logo with scale animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value, // Scale animation for logo
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.yellow[700]?.withOpacity(
                                          0.1,
                                        ),
                                        border: Border.all(
                                          color: Colors.yellow[700]!,
                                          width: 2,
                                        ),
                                      ),
                                      // Sign language icon representing the app's purpose
                                      child: Icon(
                                        Icons.sign_language,
                                        color: Colors.yellow[700],
                                        size: 60,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // App title with gradient text effect
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.yellow[700]!, Colors.white],
                                ).createShader(bounds),
                                child: const Text(
                                  'Tinig-Kamay',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              // App subtitle/description
                              const Text(
                                'Communication Platform for Deaf Community',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Username input field with validation
                              TextFormField(
                                controller: _usernameController,
                                validator: _validateUsername,
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  // Different border styles for different states
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.yellow[700]!,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),

                              const SizedBox(height: 16),

                              // Password input field with visibility toggle
                              TextFormField(
                                controller: _passwordController,
                                validator: _validatePassword,
                                obscureText:
                                    !_isPasswordVisible, // Hide/show password
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white54,
                                  ),
                                  // Toggle button for password visibility
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.yellow[700]!,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),

                              const SizedBox(height: 16),

                              // Row containing remember me checkbox and forgot password link
                              Row(
                                children: [
                                  // Remember me checkbox
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.yellow[700],
                                    checkColor: const Color(0xFF083D77),
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const Spacer(), // Push forgot password to the right
                                  // Forgot password link
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Colors.yellow[700],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Login button with loading state
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _login, // Disable when loading
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow[700],
                                    disabledBackgroundColor: Colors.yellow[700]
                                        ?.withOpacity(0.6),
                                    elevation: 8,
                                    shadowColor: Colors.yellow[700]
                                        ?.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? // Show loading spinner when processing
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF083D77),
                                                ),
                                          ),
                                        )
                                      : // Show "Sign In" text when not loading
                                        const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF083D77),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Sign up link for new users
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Navigate to sign up screen
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.yellow[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
