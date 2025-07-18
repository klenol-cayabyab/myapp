import '../models/message_model.dart';

Map<String, List<Message>> conversations = {
  "Juan Dela Cruz": [
    Message(text: "Hi Ana!", isUser: true),
    Message(text: "Kamusta ka na?", isUser: true),
    Message(text: "Okay lang ako, ikaw?", isUser: false),
  ],
  "Ana Santos": [
    Message(text: "Hello Ben!", isUser: true),
    Message(text: "Hi! Anong kailangan mo?", isUser: false),
  ],
};

void addMessageToConversation(String contactName, Message message) {
  if (!conversations.containsKey(contactName)) {
    conversations[contactName] = [];
  }
  conversations[contactName]!.add(message);
}
