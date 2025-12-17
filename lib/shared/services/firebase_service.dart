import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase service singleton for app-wide access
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Current user
  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.uid;
  bool get isAuthenticated => currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Collections references
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get categoriesCollection =>
      firestore.collection('categories');

  CollectionReference<Map<String, dynamic>> get featuredBannersCollection =>
      firestore.collection('featuredBanners');

  CollectionReference<Map<String, dynamic>> get lettersCollection =>
      firestore.collection('letters');

  CollectionReference<Map<String, dynamic>> get lessonsCollection =>
      firestore.collection('lessons');

  CollectionReference<Map<String, dynamic>> get quizzesCollection =>
      firestore.collection('quizzes');

  CollectionReference<Map<String, dynamic>> get stickersCollection =>
      firestore.collection('stickers');

  CollectionReference<Map<String, dynamic>> get appStringsCollection =>
      firestore.collection('appStrings');

  // User progress subcollection
  CollectionReference<Map<String, dynamic>> userProgressCollection(String userId) =>
      usersCollection.doc(userId).collection('progress');

  // Storage references
  Reference get imagesRef => storage.ref('images');
  Reference get audioRef => storage.ref('audio');

  Reference categoryIconsRef(String filename) =>
      imagesRef.child('categories/$filename');

  Reference bannerImagesRef(String filename) =>
      imagesRef.child('banners/$filename');

  Reference letterImagesRef(String filename) =>
      imagesRef.child('letters/$filename');

  Reference stickersRef(String filename) =>
      imagesRef.child('stickers/$filename');

  Reference letterAudioRef(String filename) =>
      audioRef.child('letters/$filename');

  Reference lessonAudioRef(String filename) =>
      audioRef.child('lessons/$filename');

  // Debug logging
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[FirebaseService] $message');
    }
  }
}
