import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AppUser? user;
  bool loading = true; // true until the saved session has been checked
  bool _manual = false; // register/login load the profile themselves
  StreamSubscription<User?>? _sub;

  AuthProvider() {
    _sub = _auth.authStateChanges().listen((u) async {
      if (u == null) {
        user = null;
        loading = false;
        notifyListeners();
      } else if (!_manual) {
        await _loadProfile(u.uid); // restores session on app start
        loading = false;
        notifyListeners();
      }
    });
  }

  /// Returns an error message, or null on success.
  Future<String?> _loadProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return 'Profile not found.';
      }
      final p = AppUser.fromMap(uid, doc.data()!);
      if (!p.isActive) {
        await _auth.signOut();
        return 'Your account is inactive. Contact an admin.';
      }
      user = p;
      loading = false;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not load your profile. Try again.';
    }
  }

  // FR-01
  Future<String?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _manual = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'role': 'customer', // BR-01: self-registered users are customers
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return await _loadProfile(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    } catch (_) {
      return 'Could not register. Check your connection and try again.';
    } finally {
      _manual = false;
    }
  }

  // FR-02
  Future<String?> login(String email, String password) async {
    _manual = true;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return await _loadProfile(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    } catch (_) {
      return 'Could not log in. Check your connection and try again.';
    } finally {
      _manual = false;
    }
  }

  // FR-03
  Future<String?> updateProfile(
      {required String name, required String phone}) async {
    try {
      await _db
          .collection('users')
          .doc(user!.uid)
          .update({'name': name.trim(), 'phone': phone.trim()});
      user = AppUser(
        uid: user!.uid,
        name: name.trim(),
        email: user!.email,
        phone: phone.trim(),
        role: user!.role,
        isActive: user!.isActive,
      );
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not save, try again.';
    }
  }

  Future<void> logout() => _auth.signOut();

  String _msg(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong ($code).';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}