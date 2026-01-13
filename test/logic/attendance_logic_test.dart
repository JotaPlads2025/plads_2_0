
import 'package:flutter_test/flutter_test.dart';
import 'package:plads_2_0/services/logic/attendance_logic.dart';
import 'package:plads_2_0/models/class_model.dart';
import 'package:plads_2_0/models/user_model.dart';

void main() {
  group('AttendanceLogic Tests', () {
    late AttendanceLogic logic;

    setUp(() {
      logic = AttendanceLogic();
    });

    test('should merge registered users and manual attendees correctly', () {
      // 1. Arrange
      final registeredUser = UserModel(
        id: 'u1', 
        email: 'test@test.com', 
        displayName: 'App User', 
        role: 'student', 
        createdAt: DateTime.now()
      );

      final manualAttendee = {'id': 'm1', 'name': 'Manual User'};
      
      final classModel = ClassModel(
        id: 'c1',
        instructorId: 'i1',
        title: 'Test Class',
        description: 'Desc',
        date: DateTime.now(),
        startTime: '10:00',
        endTime: '11:00',
        capacity: 10,
        price: 100,
        location: 'Room A',
        attendeeIds: ['u1'],
        manualAttendees: [manualAttendee],
        attendance: {}, // No one marked yet
      );

      // 2. Act
      logic.loadParticipants(classModel, [registeredUser]);

      // 3. Assert
      expect(logic.participants.length, 2);
      expect(logic.participants.any((u) => u.id == 'u1'), isTrue);
      expect(logic.participants.any((u) => u.id == 'm1'), isTrue);
      expect(logic.participants.firstWhere((u) => u.id == 'm1').displayName, 'Manual User');
    });

    test('should mark attendance correctly', () {
      // 1. Arrange (Simpler setup)
      logic.toggleAttendance('u1', true);

      // 2. Assert
      expect(logic.attendanceMap['u1'], isTrue);
      expect(logic.presentCount, 1);
      expect(logic.getPresentStudentIds(), contains('u1'));
    });

    test('should toggle attendance off', () {
      // 1. Arrange
      logic.toggleAttendance('u1', true);
      expect(logic.presentCount, 1);

      // 2. Act
      logic.toggleAttendance('u1', false);

      // 3. Assert
      expect(logic.attendanceMap['u1'], isFalse);
      expect(logic.presentCount, 0);
    });
    
    test('should initialize attendance from existing ClassModel data', () {
      // 1. Arrange
      final registeredUser = UserModel(id: 'u1', email: '', displayName: '', role: 's', createdAt: DateTime.now());
      final classModel = ClassModel(
        id: 'c1', instructorId: 'i1', title: '', description: '', date: DateTime.now(), startTime: '', endTime: '', capacity: 10, price: 0, location: '',
        attendeeIds: ['u1'],
        attendance: {'u1': 'some_timestamp'}, // u1 was already present
      );
      
      // 2. Act
      logic.loadParticipants(classModel, [registeredUser]);
      
      // 3. Assert
      expect(logic.attendanceMap['u1'], isTrue);
    });
  });
}
