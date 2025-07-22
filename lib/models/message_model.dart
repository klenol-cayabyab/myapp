class Message {
  final String text;
  final bool isUser;
  final DateTime? timestamp;

  Message({required this.text, required this.isUser, this.timestamp});

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp?.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'])
        : null,
  );
}
