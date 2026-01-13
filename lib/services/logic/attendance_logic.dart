
import '../../../models/class_model.dart';
import '../../../models/user_model.dart';

/// Pure logic class for managing attendance state.
/// This class handles the merging of "App Users" and "Manual Users" 
/// and provides methods to calculate totals and toggle states.
class AttendanceLogic {
  List<UserModel> _allParticipants = [];
  final Map<String, bool> _attendanceMap = {};

  List<UserModel> get participants => _allParticipants;
  Map<String, bool> get attendanceMap => _attendanceMap;

  /// Loads participants by merging registered users with manual attendees from the class.
  void loadParticipants(ClassModel classData, List<UserModel> registeredUsers) {
    // 1. Convert Manual Attendees (Maps) to UserModels (Uniform Interface)
    final List<UserModel> manualUsers = classData.manualAttendees.map<UserModel>((m) {
      return UserModel(
        id: m['id'] ?? 'manual_${DateTime.now().millisecondsSinceEpoch}', // Fallback safely
        email: '',
        displayName: m['name'] ?? 'Alumno sin nombre',
        photoUrl: '',
        role: 'student',
        createdAt: DateTime.now(),
        // Manual users are distinguished by ID formatting or handled by UI indicator
      );
    }).toList();

    // 2. Merge Lists
    _allParticipants = [...registeredUsers, ...manualUsers];

    // 3. Initialize Attendance Map
    // If the user is already in the class 'attendance' map, use that value.
    // Otherwise, default to false.
    for (var user in _allParticipants) {
      _attendanceMap[user.id] = classData.attendance.containsKey(user.id);
    }
  }

  /// Toggles the attendance status for a specific user.
  void toggleAttendance(String userId, bool isPresent) {
    _attendanceMap[userId] = isPresent;
  }

  /// Returns a list of IDs for all students marked as present.
  List<String> getPresentStudentIds() {
    return _attendanceMap.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns the total number of students currently marked present.
  int get presentCount => _attendanceMap.values.where((v) => v).length;
  
  /// Helper to check if a user is manual (visual logic helper)
  bool isManualUser(String userId) {
    return userId.startsWith('manual_');
  }
}
