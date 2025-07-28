Tinig-Kamay 🤟📱
A Flutter-based communication platform that bridges the gap between hearing and deaf communities through innovative technology integration.
📋 Overview
Tinig-Kamay is a mobile application designed to facilitate seamless communication between hearing and deaf individuals. The app combines voice recognition, text-to-speech, and Filipino Sign Language (FSL) support to create an inclusive communication experience.
✨ Features
🎙️ Voice Communication

Real-time speech-to-text conversion
Voice level visualization with animated waveforms
Support for multiple languages (Tagalog, English)

📝 Text Messaging

Standard text chat functionality
Message history and persistence
Contact management system

🤟 Filipino Sign Language (FSL) Support

Pre-defined FSL phrase categories:

Greetings
Gratitude expressions
Emotional expressions
Common questions


Text-to-speech for FSL phrases

🔗 Hardware Integration

Bluetooth connectivity for Tinig-Kamay glove device
Real-time device status monitoring

💬 Chat Management

Multiple conversation history
Message type indicators (Voice/Text/FSL)
Contact search and filtering
Conversation deletion and management

📱 App Structure
Main Screens

Chat Screen (chat_screen.dart)

Three communication modes: Text, Voice, FSL
Real-time message display
Contact selection
Voice recording with visual feedback


History Screen (history_screen.dart)

Conversation list with search functionality
Message statistics and type indicators
Quick access to different chat modes
Swipe-to-delete conversations


Conversation Detail Screen (conversation_detail_screen.dart)

Full message history view
Message type icons and timestamps
Auto-save functionality
Navigation back to specific chat modes


Settings Screen (settings_screen.dart)

Bluetooth device management
Language selection (Tagalog/English)
Notification preferences
Account management



🛠️ Technical Stack

Framework: Flutter
Storage: SharedPreferences for local data persistence
Speech Recognition: speech_to_text package
Text-to-Speech: flutter_tts package
UI: Custom glassmorphism design with gradient backgrounds
Animations: Flutter's built-in animation controllers

🎨 Design Features

Modern UI: Glassmorphism effects with blur backgrounds
Dark Theme: Professional dark blue color scheme
Gradient Elements: Smooth color transitions throughout the app
Smooth Animations: Fade-in effects and smooth transitions
Responsive Design: Optimized for various screen sizes

📦 Key Dependencies
yamldependencies:
  flutter_tts: ^3.6.3          # Text-to-speech functionality
  speech_to_text: ^6.3.0       # Speech recognition
  shared_preferences: ^2.2.0   # Local data storage
🚀 Getting Started

Clone the repository
bashgit clone https://github.com/yourusername/tinig-kamay.git
cd tinig-kamay

Install dependencies
bashflutter pub get

Run the app
bashflutter run


📊 App Flow
Login Screen → Bottom Navigation → [Chat | History | Settings]
     ↓
Chat Screen ←→ Conversation Detail Screen
     ↓
Three Modes: Text | Voice | FSL
🎯 Target Users

Hearing individuals communicating with deaf friends/family
Deaf individuals who want to communicate using FSL
Educators teaching sign language
Healthcare workers serving deaf patients
Anyone interested in inclusive communication

🔧 Hardware Requirements

Tinig-Kamay Glove (Bluetooth-enabled device)
Android/iOS device with microphone and speaker
Bluetooth connectivity for glove integration

📝 Data Management

Local Storage: All conversations stored locally using SharedPreferences
Message Types: Text, Voice, and FSL messages with timestamps
Contact System: Dynamic contact management with conversation history
Auto-save: Automatic saving of conversations and settings

🌟 Future Enhancements

Cloud synchronization for cross-device access
Video call integration with sign language interpretation
Extended FSL phrase library
Multi-user group conversations
Advanced gesture recognition

🤝 Contributing
We welcome contributions to improve Tinig-Kamay! Please feel free to submit issues and pull requests.
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
👥 Team
Developed with ❤️ for inclusive communication

Tinig-Kamay: Breaking barriers, building bridges through technology 🌉