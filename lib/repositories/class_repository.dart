
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';

class ClassRepository {
  final FirebaseFirestore _db;

  ClassRepository({FirebaseFirestore? firestore}) 
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Fetches a single class by its ID.
  Future<ClassModel?> getClassById(String classId) async {
    try {
      DocumentSnapshot doc = await _db.collection('classes').doc(classId).get();
      if (doc.exists) {
        return ClassModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching class: $e');
    }
  }

  /// Fetches a list of UserModels given a list of IDs.
  /// (This could also be in a UserRepository, but keeping it here for cohesion with Class logic for now)
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    // Firestore 'whereIn' is limited to 10 items. We must batch if > 10.
    // For MVP/Small classes, direct calls are often okay, but 'whereIn' is better.
    // For simplicity of this refactor step, we'll do batches of 10.
    
    List<UserModel> users = [];
    for (var i = 0; i < userIds.length; i += 10) {
      var end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      var batchIds = userIds.sublist(i, end);
      
      QuerySnapshot snapshot = await _db.collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
          
      users.addAll(snapshot.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>)));
    }
    
    return users;
  }

  /// Saves the attendance list for a class.
  /// This updates the 'attendance' map in the class document.
  /// Note: The logic for "manual attendees" persistence is that they are already stored in 'manualAttendees' field.
  /// This method only records WHO showed up (Timestamp or boolean).
  Future<void> saveAttendance(String classId, List<String> presentStudentIds) async {
    try {
      // We store a map of ID -> Timestamp (of check-in)
      // For simplicity, we just use server timestamp for "now".
      Map<String, dynamic> attendanceMap = {};
      for (var id in presentStudentIds) {
        attendanceMap[id] = Timestamp.now();
      }

      await _db.collection('classes').doc(classId).update({
        'attendance': attendanceMap,
        'status': 'completed' // Auto-close class often implies 'completed', verify if this is desired logic
      });
    } catch (e) {
      throw Exception('Error saving attendance: $e');
    }
  }

  /// Fetches classes for a specific instructor, ordered by date.
  Future<List<ClassModel>> getInstructorClasses(String instructorId) async {
    try {
      final snapshot = await _db.collection('classes')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error fetching instructor classes: $e');
    }
  }
}
