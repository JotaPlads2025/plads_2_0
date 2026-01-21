import 'access_grant_model.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'student', 'instructor', 'admin'
  final DateTime createdAt;
  final bool acceptedTerms;
  final String? pushToken;
  final List<String> interests;
  final String? bio; 
  final Map<String, dynamic> notificationSettings; 
  final Map<String, String> socialLinks;
  final Map<String, dynamic> wallet; // Map<instructorId, {balance: int, instructorName: String}>
  final List<AccessGrant> activeSubscriptions; // New field for multi-plan support
  final List<String> favorites; // New: List of instructor IDs the user follows
  final String planType; // 'commission', 'basic', 'pro'

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.acceptedTerms = false,
    this.pushToken,
    this.interests = const [],
    this.bio,
    this.socialLinks = const {},
    this.notificationSettings = const {},
    this.wallet = const {},
    this.activeSubscriptions = const [],
    this.favorites = const [],
    this.planType = 'commission',
  });

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'acceptedTerms': acceptedTerms,
      'pushToken': pushToken,
      'interests': interests,
      'bio': bio,
      'socialLinks': socialLinks,
      'notificationSettings': notificationSettings,
      'wallet': wallet,
      'activeSubscriptions': activeSubscriptions.map((x) => x.toMap()).toList(),
      'favorites': favorites,
      'planType': planType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'student',
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt']) 
          : (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      acceptedTerms: map['acceptedTerms'] ?? false,
      pushToken: map['pushToken'],
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      notificationSettings: Map<String, dynamic>.from(map['notificationSettings'] ?? {}),
      wallet: Map<String, dynamic>.from(map['wallet'] ?? {}),
      activeSubscriptions: map['activeSubscriptions'] != null 
          ? List<AccessGrant>.from((map['activeSubscriptions'] as List).map((x) => AccessGrant.fromMap(x)))
          : [],
      favorites: List<String>.from(map['favorites'] ?? []),
      planType: map['planType'] ?? 'commission',
    );
  }
}
