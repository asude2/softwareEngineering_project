import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  String? displayName;
  String role; // 'user', 'admin'

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.role = 'user',
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: data['role'] as String? ?? 'user',
    );
  }
}

class UserAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoggedIn => _auth.currentUser != null;

  UserAuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          _currentUser = AppUser.fromFirestore(userDoc);
        } else {

          _currentUser = AppUser(uid: firebaseUser.uid, email: firebaseUser.email, displayName: firebaseUser.displayName);

          print("UYARI: Firestore'da kullanıcı belgesi bulunamadı: ${firebaseUser.uid}. Varsayılan rol atandı.");
        }
      } catch (e) {
        print("Kullanıcı rolü alınırken hata: $e");
        _currentUser = AppUser(uid: firebaseUser.uid, email: firebaseUser.email, displayName: firebaseUser.displayName); // Hata durumunda varsayılan
      }
    }
    notifyListeners(); // Dinleyicileri bilgilendir
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
