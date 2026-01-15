import 'dart:async'; // Add async import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../repositories/user_repository.dart'; // Assuming this exists or will check
import '../utils/custom_exceptions.dart'; // For NewUserException

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUserModel; // Cache for current user model
  GoogleSignIn? _googleSignIn; // Lazy initialization
  final UserRepository _userRepo = UserRepository();
  final StreamController<UserModel?> _userStreamController = StreamController<UserModel?>.broadcast();

  
  AuthService() {
    _auth.setLanguageCode('es'); // Force emails to be in Spanish
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }
    
    // Listen to Firebase Auth changes to feed the stream
    _auth.authStateChanges().listen((User? firebaseUser) async {
       if (firebaseUser == null) {
         _currentUserModel = null;
         _userStreamController.add(null);
       } else {
         try {
           final userModel = await _userRepo.getUserById(firebaseUser.uid);
           // If userModel is null (new social user), we emit null so AuthWrapper stays on Login/Landing
           // The UI handles the specific 'NewUserException' flow separately.
           _currentUserModel = userModel;
           _userStreamController.add(userModel);
         } catch (e) {
           print('Error fetching user for stream: $e');
           _currentUserModel = null;
           _userStreamController.add(null);
         }
       }
    });
  }

  // ValueNotifier for loading state if needed, or Streams
  // Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser; // Synchronous access to Firebase User
  UserModel? get currentUserModel => _currentUserModel; // Synchronous access to User Model

  // Stream of UserModel (listens to Auth changes and fetches Firestore data)
  Stream<UserModel?> get user => _userStreamController.stream;
  Future<UserModel?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // --- WEB IMPLEMENTATION ---
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('email');
        
        // Use signInWithPopup for Web
        UserCredential result = await _auth.signInWithPopup(authProvider);
        return _handleSocialLoginResult(result);
        
      } else {
        // --- MOBILE IMPLEMENTATION ---
        // 1. Trigger Google Sign In flow
        // Ensure _googleSignIn is initialized (should be if !kIsWeb)
        _googleSignIn ??= GoogleSignIn(); 
        
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        
        if (googleUser == null) return null; // User cancelled
        
        // 2. Obtain details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // 3. Create Credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // 4. Sign in to Firebase
        UserCredential result = await _auth.signInWithCredential(credential);
        return _handleSocialLoginResult(result);
      }
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  // Common Handler for Social Logins (Create/Get User)
  Future<UserModel?> _handleSocialLoginResult(UserCredential result) async {
    final User? firebaseUser = result.user;
    if (firebaseUser == null) return null;

    // Check if user exists in Firestore
    UserModel? existingUser = await _userRepo.getUserById(firebaseUser.uid);
    
    if (existingUser != null) {
      // SYNC PHOTO: If Firestore lacks photo but Google has one, update it.
      if ((existingUser.photoUrl == null || existingUser.photoUrl!.isEmpty) && 
          firebaseUser.photoURL != null) {
          
          await _userRepo.updateUser(existingUser.id, {'photoUrl': firebaseUser.photoURL});
          
          // Refresh local model with new photo
          existingUser = UserModel(
            id: existingUser.id,
            email: existingUser.email,
            displayName: existingUser.displayName,
            photoUrl: firebaseUser.photoURL, // Updated
            role: existingUser.role,
            createdAt: existingUser.createdAt,
            acceptedTerms: existingUser.acceptedTerms,
            interests: existingUser.interests,
            bio: existingUser.bio,
            socialLinks: existingUser.socialLinks,
            notificationSettings: existingUser.notificationSettings,
            wallet: existingUser.wallet,
            activeSubscriptions: existingUser.activeSubscriptions,
            favorites: existingUser.favorites,
          );
      }

      _currentUserModel = existingUser;
      _userStreamController.add(existingUser);
      return existingUser;
    } else {
      // THROW EXCEPTION to handle new user flow in UI (Role Selection)
      throw NewUserException(firebaseUser);
    }
  }

  // Complete Registration for Social Login (After Role Selection)
  Future<UserModel?> registerFromSocial({
    required String uid,
    required String email,
    required String name,
    required String role,
    required List<String> interests,
  }) async {
    try {
      final newUser = UserModel(
        id: uid,
        email: email,
        displayName: name,
        photoUrl: _auth.currentUser?.photoURL, // SAVE PHOTO IMMEDIATELY
        role: role,
        createdAt: DateTime.now(),
        acceptedTerms: true,
        interests: interests,
      );

      await _userRepo.saveUser(newUser);

      if (role == 'student') {
        await _userRepo.updateUser(uid, {
          'status': 'dropIn',
          'creditsRemaining': 0,
          'creditsTotal': 0,
        });
      }

      // CRITICAL: Manually update the stream so AuthWrapper detects the new user
      _currentUserModel = newUser;
      _userStreamController.add(newUser);

      return newUser;
    } catch (e) {
      rethrow;
    }
  }




  // Sign in with Email & Password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      return await _userRepo.getUserById(result.user!.uid);
    } catch (e) {
      rethrow; // Pass error to UI
    }
  }

  // Register with Email & Password
  Future<UserModel?> register({
    required String email, 
    required String password, 
    required String name, 
    required String role, 
    required bool acceptedTerms,
    List<String> interests = const [],
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      final String uid = result.user!.uid;
      final DateTime now = DateTime.now();
      
      // Send Verification Email
      if (!result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }

      // Create base User Model
      UserModel newUser = UserModel(
        id: uid,
        email: email,
        displayName: name,
        role: role,
        createdAt: now,
        acceptedTerms: acceptedTerms,
        interests: interests,
      );
      
      await _userRepo.saveUser(newUser);

      if (role == 'student') {
         await _userRepo.updateUser(uid, {
           'status': 'dropIn',
           'creditsRemaining': 0,
           'creditsTotal': 0
         });
      }

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (kIsWeb) {
       await _auth.signOut();
    } else {
       await _googleSignIn?.signOut();
       await _auth.signOut();
    }
  }

  // Update User Profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl, // Added
    String? bio,
    Map<String, String>? socialLinks,
    List<String>? interests,
    Map<String, dynamic>? notificationSettings,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl; // Added
      if (bio != null) updates['bio'] = bio;
      if (socialLinks != null) updates['socialLinks'] = socialLinks;
      if (interests != null) updates['interests'] = interests;
      if (notificationSettings != null) updates['notificationSettings'] = notificationSettings;

      if (updates.isNotEmpty) {
        await _userRepo.updateUser(uid, updates);
      }
      
      // Also update Firebase Auth profile
      if (_auth.currentUser != null) {
         if (displayName != null) await _auth.currentUser!.updateDisplayName(displayName);
         if (photoUrl != null) await _auth.currentUser!.updatePhotoURL(photoUrl); // Added
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}
