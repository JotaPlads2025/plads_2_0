
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? firestore}) 
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Fetches a user by their ID.
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // In a real app, we might log this error to Crashlytics
      print('Error fetching user: $e');
      return null; // Or rethrow based on app policy
    }
  }

  /// Creates or Overwrites a user document.
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  /// Updates specific fields for a user.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }
}
