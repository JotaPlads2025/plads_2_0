import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/class_type_model.dart';
import '../models/student_model.dart';
import '../models/access_grant_model.dart';
import '../models/venue_model.dart';
import '../models/transaction_model.dart' as tm;
import 'notification_service.dart'; // Import Notification Service
import '../models/academy_model.dart';
import '../models/message_model.dart'; // New
import '../models/chat_model.dart'; // New
import '../models/broadcast_model.dart'; // New
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // --- USERS ---

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user fields: $e');
      rethrow;
    }
  }

  // --- STUDENTS (For Instructor) ---

  // Get All Students for an Instructor (assuming students are subcollection or filtered by instructorId if shared)
  // For now, let's assume students are global or we filter by something. 
  // If this is a single academy app, we might get all users with role 'student'.
  Stream<List<StudentModel>> getStudents() {
    return _db.collection('users')
        // .where('role', isEqualTo: 'student') // Removed to allow all users (incl. instructors)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Active Subscribers
  Stream<List<StudentModel>> getActiveSubscribers() {
    return _db.collection('users')
        .where('role', isEqualTo: 'student')
        .where('status', isEqualTo: 'activePlan')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Add a new Student (Manual Entry by Instructor)
  Future<void> addStudent(StudentModel student) async {
    try {
      // Create a reference to auto-generate ID
      DocumentReference ref = _db.collection('users').doc();
      
      // Merge student data with ID and Role
      Map<String, dynamic> data = student.toMap();
      data['id'] = ref.id;
      data['role'] = 'student'; // Critical for the query to find it
      data['createdAt'] = FieldValue.serverTimestamp(); // Good practice
      
      await ref.set(data);
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  // --- CLASSES ---

  // --- CLASSES ---

  // Get Single Class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc = await _db.collection('classes').doc(classId).get();
      if (doc.exists) {
        return ClassModel.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting class: $e');
      return null;
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      // Firestore 'where in' supports up to 10 items.
      // For production, we should chunk this. For MVP with < 30 students, getting all might be improved by chunking or looping.
      // Let's do a simple loop for now if list is small, or use 'where in' chunks.
      // Given the constraints and likely small class size (< 20), we can just fetch them uniquely or use 'whereIn'.
      
      // Better approach for small lists:
      List<UserModel> users = [];
      // Chunking to 10 just in case
      for (var i = 0; i < userIds.length; i += 10) {
        var end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        var chunk = userIds.sublist(i, end);
        
        final snapshot = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        users.addAll(snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)));
      }
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Create a new class
  Future<void> createClass(ClassModel classData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user logged in");
      
      // Fetch user profile to get the name
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['displayName'] ?? 'Instructor';

      final docRef = _db.collection('classes').doc();
      final newClass = ClassModel(
        id: docRef.id,
        instructorId: user.uid,
        instructorName: userName,
        title: classData.title,
        description: classData.description,
        date: classData.date,
        startTime: classData.startTime,
        endTime: classData.endTime,
        capacity: classData.capacity,
        price: classData.price,
        location: classData.location,
        attendeeIds: [],
        status: 'active', // Ensure status is set
        classTypeId: classData.classTypeId, 
        color: classData.color, 
        availablePlans: classData.availablePlans,
        category: classData.category, // Fix: Copy Category
        discipline: classData.discipline, // Fix: Copy Discipline
        targetAudience: classData.targetAudience, // Fix: Copy Audience
        region: classData.region, // Fix: Copy Region
        comuna: classData.comuna, // Fix: Copy Comuna
        latitude: classData.latitude, // Fix: Save Latitude
        longitude: classData.longitude, // Fix: Save Longitude
      );

      await docRef.set(newClass.toMap());
      print('DEBUG: Class created with ID ${docRef.id} and status ${newClass.status}');
    } catch (e) {
      print("Error creating class: $e");
      throw Exception("Failed to create class: $e");
    }
  }

  // Cancel a Class
  Future<void> cancelClass(String classId, String reason) async {
    try {
      final docRef = _db.collection('classes').doc(classId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception("Clase no encontrada");

      final classData = ClassModel.fromMap(doc.data()!);

      // 1. Update Status
      await docRef.update({
        'status': 'cancelled',
        'cancellationReason': reason // Opcional: Guardar motivo
      });

      // 2. Notify Students
      final notifService = NotificationService();
      for (final studentId in classData.attendeeIds) {
         await notifService.sendNotification(
           recipientId: studentId,
           title: 'Clase Cancelada ⚠️',
           body: 'La clase de ${classData.title} ha sido suspendida. Motivo: $reason',
           type: 'cancellation',
           relatedId: classId
         );
      }
      
      // TODO: Log Finance "Refund Needed" here if critical for MVP

    } catch (e) {
      throw Exception("Error al cancelar clase: $e");
    }
  }

  // Get classes created by a specific instructor
  Stream<List<ClassModel>> getInstructorClasses(String instructorId) {
    return _db.collection('classes')
      .where('instructorId', isEqualTo: instructorId)
      // .where('status', isNotEqualTo: 'cancelled') // Optional: Hide cancelled? Better to show them.
      .orderBy('date')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // Get ALL classes for Search (with basic filtering capability)
  Stream<List<ClassModel>> getAllClasses() {
     // Relaxed date filter for debugging/visibility: Show classes from yesterday onwards
     final now = DateTime.now();
     final startOfDay = DateTime(now.year, now.month, now.day);
     return _db.collection('classes')
      .where('date', isGreaterThanOrEqualTo: startOfDay) 
      .where('status', isEqualTo: 'active') // Only show active classes in search
      .orderBy('date') 
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // Enroll in Class
  // Enroll in Class
  Future<void> enrollInClass(String classId, String studentId) async {
    try {
      final docRef = _db.collection('classes').doc(classId);
      final classDoc = await docRef.get();
      if (!classDoc.exists) throw Exception("Clase no encontrada");
      final classData = ClassModel.fromMap(classDoc.data()!);

      if (classData.status == 'cancelled') throw Exception("Esta clase ha sido cancelada.");

      // Check if already enrolled to prevent duplicates/double-notifications
      if (classData.attendeeIds.contains(studentId)) {
        print("WARN: User $studentId already enrolled in class $classId. Skipping.");
        return;
      }

    print('DEBUG: Enrolling student $studentId in class ${classData.id} (${classData.title})'); // DEBUG LOG

    final studentDoc = await _db.collection('users').doc(studentId).get();
      final studentName = studentDoc.data()?['displayName'] ?? 'Un Alumno';
      
      // Transaction to update attendees
      await docRef.update({
        'attendeeIds': FieldValue.arrayUnion([studentId])
      });

      // Update student's lastAttendance
      await _db.collection('users').doc(studentId).update({
        'lastAttendance': DateTime.now().toIso8601String(),
        'status': 'dropIn', 
      });

      // --- NOTIFICATIONS ---
      final notifService = NotificationService();
      
      // 1. Notify Instructor
      await notifService.sendNotification(
        recipientId: classData.instructorId,
        title: 'Nueva Inscripción 📝',
        body: '$studentName se ha inscrito en tu clase de ${classData.title}.',
        type: 'booking',
        relatedId: classId,
      );

      // 2. Notify Student
      await notifService.sendNotification(
         recipientId: studentId,
         title: '¡Inscripción Confirmada! ✅',
         body: 'Te esperamos en la clase de ${classData.title}.',
         type: 'booking',
         relatedId: classId
      );

      // 3. Schedule Local Reminder (1 Hour Before)
      // Parse Start Time
      try {
        final parts = classData.startTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final classDateTime = DateTime(
          classData.date.year, classData.date.month, classData.date.day,
          hour, minute
        );

        // Use classId hash as unique ID for notification
        await notifService.scheduleClassReminder(
          id: classId.hashCode,
          title: '¡Tu clase comienza en 1 hora! ⏳',
          body: 'Prepárate para bailar ${classData.title}.',
          classTime: classDateTime,
        );
      } catch (e) {
        print("Error scheduling reminder: $e");
      }

      // --- FINANCE: Record Transaction ---
      final transaction = tm.Transaction(
        date: DateTime.now(),
        studentId: studentId,
        studentName: studentName,
        item: classData.title, // Or 'Clase: ${classData.title}'
        amount: classData.price,
        method: tm.PaymentMethod.app, // Enrolled via App
        commission: classData.price * 0.029, // Example calc
      );
      
      await _db.collection('users').doc(classData.instructorId).collection('transactions').add(transaction.toMap());

    } catch (e) {
      throw Exception("Failed to enroll: $e");
    }
  }

  // Purchase Plan and Enroll
  Future<void> purchasePlanAndEnroll(String classId, String studentId, Map<String, dynamic> plan) async {
    try {
      final docRef = _db.collection('classes').doc(classId);
      final classDoc = await docRef.get();
      if (!classDoc.exists) throw Exception("Clase no encontrada");
      final classData = ClassModel.fromMap(classDoc.data()!);

      // Check Enrollment
      if (classData.attendeeIds.contains(studentId)) {
        throw Exception("Ya estás inscrito en esta clase.");
      }

      final studentDocRef = _db.collection('users').doc(studentId);
      final studentDoc = await studentDocRef.get();
      final studentName = studentDoc.data()?['displayName'] ?? 'Alumno';
      
      // Execute Purchase + Enrollment
      // 1. Record Transaction
      final transaction = tm.Transaction(
        date: DateTime.now(),
        studentId: studentId,
        studentName: studentName,
        item: plan['title'] ?? 'Plan', // e.g. "Pack 4 Clases"
        amount: (plan['price'] as num).toDouble(),
        method: tm.PaymentMethod.app, 
        commission: (plan['price'] as num).toDouble() * 0.029, 
      );
      
      await _db.collection('users').doc(classData.instructorId).collection('transactions').add(transaction.toMap());

      // 2. Add AccessGrant to Student
      // Infer Grant Type
      // If 'credits' > 0 -> Pack. If duration -> Subscription.
      // We rely on plan map having specific keys or default to Pack.
      final int credits = plan['credits'] as int? ?? 1;
      final bool isMonthly = plan['type'] == 'subscription' || plan['isMonthly'] == true; // Flexible check

      final newGrant = AccessGrant(
        id: 'grant_${DateTime.now().millisecondsSinceEpoch}',
        name: plan['title'] ?? 'Plan Nuevo',
        type: isMonthly ? AccessGrantType.subscription : AccessGrantType.pack,
        instructorId: classData.instructorId, // Strict Instructor Scope
        discipline: plan['discipline'] ?? classData.discipline, // Prefer plan metadata, fallback to Class context
        level: plan['level'] ?? 'All',
        category: plan['category'] ?? classData.category, // Prefer plan metadata, fallback to Class context
        initialClasses: isMonthly ? null : credits,
        remainingClasses: isMonthly ? null : (credits - 1), // Deduct immediately for the current class!
        expiryDate: DateTime.now().add(const Duration(days: 30)), // Default 30 days
      );

      // We need to append this to the existing list.
      // Firestore 'arrayUnion' works for primitives, for maps/objects we need to read-modify-write usually 
      // or ensure we pass the exact map. 'activeSubscriptions' is a list of maps in Firestore.
      
      // Note: If it's a PACK, we deduct 1 immediately because the user is enrolling NOW.
      // If it's a Subscription, we just check date (valid).

      await studentDocRef.update({
        'activeSubscriptions': FieldValue.arrayUnion([newGrant.toMap()]),
        'lastAttendance': DateTime.now().toIso8601String(),
        'status': 'activePlan', 
      });

      // 3. Enroll in Class
      await docRef.update({
        'attendeeIds': FieldValue.arrayUnion([studentId])
      });

      // 4. Notifications
       final notifService = NotificationService();
       await notifService.sendNotification(
          recipientId: classData.instructorId,
          title: 'Compra de Plan + Inscripción 💰',
          body: '$studentName compró "${plan['title']}" y se inscribió a ${classData.title}.',
          type: 'booking',
          relatedId: classId,
       );

    } catch (e) {
      throw Exception("Error comprando plan: $e");
    }
  }

  // Consume Subscription and Enroll (Renamed from useCreditAndEnroll)
  Future<void> useSubscriptionAndEnroll(String classId, String studentId) async {
    try {
      final docRef = _db.collection('classes').doc(classId);
      // Run transaction to ensure atomicity when decrementing credits
      await _db.runTransaction((transaction) async {
        final classDoc = await transaction.get(docRef);
        if (!classDoc.exists) throw Exception("Clase no encontrada");
        final classData = ClassModel.fromMap(classDoc.data()!);

        if (classData.attendeeIds.contains(studentId)) {
          throw Exception("Ya estás inscrito.");
        }

        if (classData.attendeeIds.length >= classData.capacity) {
           throw Exception("La clase está llena.");
        }

        final studentDocRef = _db.collection('users').doc(studentId);
        final studentDoc = await transaction.get(studentDocRef);
        final student = StudentModel.fromMap(studentDoc.data()!);

        // 2. Find BEST active grant
        // Priority: 
        // 1. Subscription (Unlimited)
        // 2. Pack with classes remaining (Expiry closest?)
        
        AccessGrant? bestGrant;
        int bestIndex = -1; // Keep track of the index for updating
        
        for (int i = 0; i < student.activeSubscriptions.length; i++) {
          final grant = student.activeSubscriptions[i];
          if (grant.isValidForClass(classData.instructorId, classData.discipline, classData.level, classData.category, DateTime.now())) {
             // Basic prioritization: Subscription over Pack
             if (bestGrant == null) {
               bestGrant = grant;
               bestIndex = i;
             } else if (grant.type == AccessGrantType.subscription && bestGrant.type == AccessGrantType.pack) {
               // Prefer Subscription
               bestGrant = grant;
               bestIndex = i;
             }
          }
        }

        if (bestGrant == null) {
           throw Exception("No tienes un plan o pack válido para esta clase (${classData.discipline}).");
        }

        // Apply Logic
        List<AccessGrant> updatedSubs = List.from(student.activeSubscriptions);
        
        if (bestGrant.type == AccessGrantType.pack) {
           final remaining = (bestGrant.remainingClasses ?? 0) - 1;
           if (remaining < 0) throw Exception("Pack sin clases disponibles.");
           
           // Create updated copy
           final updatedGrant = AccessGrant(
             id: bestGrant.id,
             name: bestGrant.name,
             type: bestGrant.type,
             instructorId: bestGrant.instructorId,
             discipline: bestGrant.discipline,
             level: bestGrant.level,
             category: bestGrant.category,
             initialClasses: bestGrant.initialClasses,
             remainingClasses: remaining,
             expiryDate: bestGrant.expiryDate,
             isActive: remaining > 0 // Deactivate if 0? Or keep relevant history? Better keep true for now.
           );
           
           updatedSubs[bestIndex] = updatedGrant;
        } 
        // If Subscription, no change needed unless we track usage stats.

        // Commit Updates
        transaction.update(studentDocRef, {
          'activeSubscriptions': updatedSubs.map((e) => e.toMap()).toList(),
          'lastAttendance': DateTime.now().toIso8601String(),
          'status': 'activePlan'
        });

        transaction.update(docRef, {
          'attendeeIds': FieldValue.arrayUnion([studentId])
        });
      });
      
      // Notify (Outside transaction)
       final notifService = NotificationService();
       // Fetch class data again or pass it? For MVP simple notification is fine.
       // We can't use classData from inside transaction easily without capturing it.
       // Let's just fire generic notification or fetch doc again if critical.
       
    } catch (e) {
      throw Exception("Error al usar plan: $e");
    }
  }

  // Mark Attendance (QR Scan)
  Future<void> markAttendance(String classId, String userId) async {
    try {
      final docRef = _db.collection('classes').doc(classId);
      final doc = await docRef.get();
      
      if (!doc.exists) throw Exception("Clase no encontrada");
      
      final classData = ClassModel.fromMap(doc.data()!);

      // Check if user is enrolled
      // Note: We might want to allow "walk-ins" but for now let's enforce enrollment or auto-enroll?
      // For strict MVP, user must have booked.
      if (!classData.attendeeIds.contains(userId)) {
        throw Exception("Debes inscribirte a la clase primero.");
      }

      // Check if already attended
      if (classData.attendance.containsKey(userId)) {
        throw Exception("Ya registraste tu asistencia.");
      }

      // Update Attendance Map
      await docRef.update({
        'attendance.$userId': {
          'timestamp': DateTime.now().toIso8601String(),
          'method': 'qr'
        }
      });
      
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  Future<void> markAttendanceBatch(String classId, List<String> presentStudentIds) async {
    try {
       final docRef = _db.collection('classes').doc(classId);
       
       // Create a map of updates
       final Map<String, dynamic> updates = {};
       final now = DateTime.now().toIso8601String();
       
       for (var studentId in presentStudentIds) {
         updates['attendance.$studentId'] = {
           'timestamp': now,
           'method': 'manual'
         };
       }
       
       if (updates.isNotEmpty) {
         await docRef.update(updates);
       }
    } catch (e) {
      print('Error marking batch attendance: $e');
      rethrow;
    }
  }
  // Dev / Maintenance: Clear Wallet
  Future<String> clearStudentWallet(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'activeSubscriptions': [],
        // We keep status as is or reset? Let's reset to activePlan to be safe, or just leave it.
        // If they have no subs, they are effectively "free" users.
      });
      return 'Billetera limpiada con éxito';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Get Classes for a Student (Where they are enrolled)
  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    // Simplify query to avoid complex composite index requirements causing "infinite loading"
    // We only filter by attendeeIds on server, and filter date/status on client.
    return _db.collection('classes')
      .where('attendeeIds', arrayContains: studentId)
      .snapshots()
      .map((snapshot) {
         final now = DateTime.now().subtract(const Duration(hours: 2));
         return snapshot.docs
             .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>))
             .where((c) => c.status == 'active' && c.date.isAfter(now))
             .toList()
             ..sort((a, b) => a.date.compareTo(b.date));
      });
  }



  Stream<List<ClassModel>> getStudentClassHistory(String studentId) {
    // Simplify query to avoid index issues: Filter date client-side
    return _db.collection('classes')
      .where('attendeeIds', arrayContains: studentId)
      .snapshots()
      .map((snapshot) {
         final now = DateTime.now().subtract(const Duration(hours: 2));
         return snapshot.docs
             .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>))
             .where((c) => c.date.isBefore(now)) // History = Past
             .toList()
             ..sort((a, b) => b.date.compareTo(a.date)); // Descending
      });
  }

  // Get Student History (All classes, sorted newest first)
  Stream<List<ClassModel>> getStudentHistory(String studentId) {
    return _db.collection('classes')
      .where('attendeeIds', arrayContains: studentId)
      // .where('status', isEqualTo: 'active') // Show everything in history including cancelled?
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }


  // Get Attendees for a Class
  Stream<List<UserModel>> getClassAttendees(List<String> attendeeIds) {
    if (attendeeIds.isEmpty) return Stream.value([]);
    
    // Firestore 'whereIn' is limited to 10 items.
    // For MVP, if > 10, we might need multiple queries or just fetch all users (inefficient).
    // Let's assume class size < 10 for detailed realtime profile Sync, 
    // OR just fetch all users and filter client side if list is huge (simpler for MVP).
    // Better approach for MVP: Fetch all users and filter.
    // Optimization: create a "class_roster" subcollection if scaling is needed.
    
    // Using whereIn for list <= 10
    if (attendeeIds.length <= 10) {
      return _db.collection('users')
        .where(FieldPath.documentId, whereIn: attendeeIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
    } else {
        // Fallback for larger classes: Fetch all and filter (Not ideal for prod but works for MVP)
        return _db.collection('users')
        .snapshots() // This reads all users!
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((u) => attendeeIds.contains(u.id))
            .toList());
    }
  }



  // --- MANUAL ATTENDEES & FINANCE ---

  // Add Manual Attendee and Record Transaction
  Future<void> addManualAttendee(String classId, Map<String, dynamic> studentData, double amount, String paymentMethod) async {
    try {
       final user = _auth.currentUser;
       if (user == null) throw Exception("No authenticated user");

       final classRef = _db.collection('classes').doc(classId);
       
       // 1. Update Class
       await classRef.update({
         'manualAttendees': FieldValue.arrayUnion([studentData])
       });

       // 2. Record Transaction
       final transaction = tm.Transaction(
         date: DateTime.now(),
         studentId: 'manual_${DateTime.now().millisecondsSinceEpoch}', // Dummy ID
         studentName: studentData['name'],
         item: 'Clase (Manual)', // We could fetch class title if needed, but for speed we hardcode or pass it
         amount: amount,
         method: paymentMethod == 'cash' ? tm.PaymentMethod.cash : tm.PaymentMethod.transfer,
         commission: 0.0, // Manual payments have 0 commission
       );

       await _db.collection('users').doc(user.uid).collection('transactions').add(transaction.toMap());

    } catch (e) {
      print('Error adding manual attendee: $e');
      rethrow;
    }
  }

  // Get Transactions for Instructor
  Stream<List<tm.Transaction>> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db.collection('users').doc(user.uid).collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => tm.Transaction.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // --- VENUES (Independent) ---

  Stream<List<VenueModel>> getUserVenues(String userId) {
    return _db.collection('users').doc(userId).collection('venues')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VenueModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // --- CLASS TYPES ---

  Stream<List<ClassType>> getClassTypes(String instructorId) {
    return _db.collection('users').doc(instructorId).collection('class_types')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ClassType.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addClassType(String instructorId, ClassType type) async {
    try {
      await _db.collection('users').doc(instructorId).collection('class_types').doc(type.id).set(type.toMap());
    } catch (e) {
      throw Exception('Error adding class type: $e');
    }
  }

  // --- COMMUNITY & CHAT ---

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db.collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> sendMessage(String chatId, String senderId, String content) async {
    try {
      final msgId = const Uuid().v4();
      final message = MessageModel(
        id: msgId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
      );

      final chatRef = _db.collection('chats').doc(chatId);
      
      await _db.runTransaction((transaction) async {
        // Add message
        transaction.set(chatRef.collection('messages').doc(msgId), message.toMap());
        
        // Update Chat metadata
        transaction.update(chatRef, {
          'lastMessage': content,
          'lastMessageTime': DateTime.now().toIso8601String(), // Or Timestamp
           // Increment unread count logic would go here ideally based on receiver
           // Simple version: just set last message
        });
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Create or Get Chat
  Future<String> getOrCreateChatInTransaction(String user1, String user2, String user1Name, String user2Name) async {
      // Basic implementation: Check if chat exists with these 2 participants
      // Firestore doesn't support "array equals ignoring order" easily in one query without a specific generated ID.
      // We will generate ID as composite "lesserId_greaterId" to ensure uniqueness.
      final id1 = user1.compareTo(user2) < 0 ? user1 : user2;
      final id2 = user1.compareTo(user2) < 0 ? user2 : user1;
      final chatId = '${id1}_$id2';

      final doc = await _db.collection('chats').doc(chatId).get();
      if (!doc.exists) {
        final chat = ChatModel(
          id: chatId,
          participants: [user1, user2],
          participantNames: {user1: user1Name, user2: user2Name},
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          lastSenderId: '',
        );
        await _db.collection('chats').doc(chatId).set(chat.toMap());
      }
      return chatId;
  }

  Future<void> sendBroadcast(BroadcastModel broadcast) async {
    try {
      // Calculate Reach (Approx)
      int reach = 0;
      if (broadcast.audienceType == 'followers') {
        final q = await _db.collection('users').where('favorites', arrayContains: broadcast.instructorId).count().get();
        reach = q.count ?? 0;
      } else if (broadcast.audienceType == 'interests' && (broadcast.targetInterests?.isNotEmpty ?? false)) {
        final q = await _db.collection('users').where('interests', arrayContainsAny: broadcast.targetInterests).count().get();
        reach = q.count ?? 0;
      } else {
        // Active students (approx via wallet or just null)
         final q = await _db.collection('users').where('wallet.${broadcast.instructorId}', isNull: false).count().get();
         reach = q.count ?? 0;
      }

      final b = BroadcastModel(
        id: broadcast.id,
        instructorId: broadcast.instructorId,
        title: broadcast.title,
        message: broadcast.message,
        audienceType: broadcast.audienceType,
        targetInterests: broadcast.targetInterests,
        timestamp: DateTime.now(),
        reachCount: reach
      );

      await _db.collection('broadcasts').doc(b.id).set(b.toMap());
      
      // We do NOT simulate push notification creation here, assuming client or cloud function handles it.
    } catch (e) {
       print("Error sending broadcast: $e");
       rethrow;
    }
  }

  Future<void> toggleFollowInstructor(String userId, String instructorId) async {
    final docRef = _db.collection('users').doc(userId);
    final doc = await docRef.get();
    if (doc.exists) {
      final user = UserModel.fromMap(doc.data()!);
      final isFollowing = user.favorites.contains(instructorId);
      if (isFollowing) {
        await docRef.update({'favorites': FieldValue.arrayRemove([instructorId])});
      } else {
        await docRef.update({'favorites': FieldValue.arrayUnion([instructorId])});
      }
    }
  }

  // Create/Update Class Type
  Future<void> saveClassType(ClassType type) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No authenticated user");
      await _db.collection('users').doc(user.uid).collection('class_types').doc(type.id).set(type.toMap());
    } catch (e) {
      print('Error saving class type: $e');
      rethrow;
    }
  }

  // Delete Class Type
  Future<void> deleteClassType(String typeId) async {
    try {
       final user = _auth.currentUser;
       if (user == null) throw Exception("No authenticated user");
       await _db.collection('users').doc(user.uid).collection('class_types').doc(typeId).delete();
    } catch (e) {
       print('Error deleting class type: $e');
       rethrow;
    }
  }

  // --- DEBUG / RESET DATA ---
  
  // Wipe all Instructor Data (Classes, Transactions, Venues)
  // Returns a status message string for debugging
  Future<String> wipeUserTestData() async {
    final user = _auth.currentUser;
    if (user == null) return "No debug user found";
    
    int deletedCount = 0;
    
    try {
      final batch = _db.batch();
      
      // 1. Get Classes
      final classesSnapshot = await _db.collection('classes').where('instructorId', isEqualTo: user.uid).get();
      for (final doc in classesSnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }
      
      // 2. Get Transactions
      final transSnapshot = await _db.collection('users').doc(user.uid).collection('transactions').get();
      for (final doc in transSnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      // 3. Get Venues (Optional)
      final venueSnapshot = await _db.collection('users').doc(user.uid).collection('venues').get();
      for (final doc in venueSnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      // 4. Reset User Stats (Optional - e.g. credits balance if this was a student)
      // If the user is also a student, we might want to reset their credits.
      batch.update(_db.collection('users').doc(user.uid), {
        'credits': 0,
        'lastAttendance': FieldValue.delete(),
        'status': 'new',
      });

      await batch.commit();
      
      return "Éxito: Se eliminaron $deletedCount registros (Clases, Transacciones y Sedes).";
    } catch (e) {
      return "Error borrando datos: $e. Intenta de nuevo.";
    }
  }

  // Wipe All Student Data (For testing: Resets status/plans of all students)
  Future<String> wipeAllStudentsData() async {
    try {
      final batch = _db.batch();
      final snapshot = await _db.collection('users').where('role', isEqualTo: 'student').get();
      
      if (snapshot.docs.isEmpty) return "No hay alumnos para borrar.";

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'activeSubscriptions': [],
          'status': 'new',
          'lastAttendance': FieldValue.delete(),
          'wallet': {}, 
          'favorites': [], // Optional: clear followers too
        });
      }

      await batch.commit();
      return "Éxito: Se reiniciaron ${snapshot.docs.length} alumnos a estado 'Nuevo'.";
    } catch (e) {
      print("Error wiping students: $e");
      return "Error al borrar alumnos: $e";
    }
  }

  Future<void> addUserVenue(String userId, VenueModel venue) async {
    try {
      await _db.collection('users').doc(userId).collection('venues').doc(venue.id).set(venue.toMap());
    } catch (e) {
      print('Error adding venue: $e');
      rethrow;
    }
  }

  Future<void> deleteUserVenue(String userId, String venueId) async {
    try {
      await _db.collection('users').doc(userId).collection('venues').doc(venueId).delete();
    } catch (e) {
      print('Error deleting venue: $e');
      rethrow;
    }
  }

  // --- ACADEMY ---
  
  Future<AcademyModel?> getInstructorAcademy(String instructorId) async {
    try {
      // Assuming 1 Academy per Instructor for now
      final snapshot = await _db.collection('academies')
          .where('instructorId', isEqualTo: instructorId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AcademyModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting academy: $e');
      return null;
    }
  }
}
