import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // [userId1, userId2]
  final Map<String, String> participantNames; // {userId: Name} for easy UI
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String lastSenderId; 

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.lastSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'lastSenderId': lastSenderId,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: map['unreadCount'] ?? 0,
      lastSenderId: map['lastSenderId'] ?? '',
    );
  }
}
