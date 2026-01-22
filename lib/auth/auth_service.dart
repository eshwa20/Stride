import 'package:flutter/foundation.dart'; // Fixed: Required for debugPrint
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save selection during Ascension
  static Future<void> saveUserPath(String path) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).set({
          'selectedPath': path,
          'level': 1,
          'xp': 0,
          'currentStreak': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Firestore Error: $e");
      }
    }
  }

  // ================= EMAIL =================
  static Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  static Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ================= GOOGLE =================
  static Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  // ================= FACEBOOK =================
  static Future<User?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;

    // Fixed: Use tokenString instead of token for version 6.0.0+
    final credential =
    FacebookAuthProvider.credential(result.accessToken!.tokenString);
    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  // ================= GITHUB =================
  static Future<User?> signInWithGitHub() async {
    final githubProvider = GithubAuthProvider();
    final userCred = await _auth.signInWithProvider(githubProvider);
    return userCred.user;
  }

  // ================= SIGN OUT =================
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}