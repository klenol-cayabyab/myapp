class ConversationData {
  static List<Map<String, String>> _conversations = [];

  static void addMessage(String name, String message) {
    _conversations.insert(0, {'name': name, 'message': message});
  }

  static void deleteMessage(int index) {
    _conversations.removeAt(index);
  }

  static List<Map<String, String>> getAll() {
    return _conversations;
  }
}
