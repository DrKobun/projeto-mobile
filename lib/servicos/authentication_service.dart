import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> initializeAuth() async {
    try {
      if (kIsWeb && Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.web,
        );
      }
    } catch (e) {
      print('Firebase initialization error: $e');
      throw Exception('Failed to initialize Firebase');
    }
  }

  Future<User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  Future<String?> userRegistration(
      {required String nome,
      required String email,
      required String senha,
      required String tipoUsuario}) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: senha);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'tipoUsuario': tipoUsuario,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await userCredential.user!.updateDisplayName(nome);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return "O usuário já está cadastrado";
      }
      return "Erro desconhecido";
    }
  }

  Future<String?> loginUsers({
    required String email,
    required String senha,
    required String nome,
  }) async {
    try {
      // Ensure Firebase is initialized
      await initializeAuth();

      // Validate email and password before attempting login
      if (email.isEmpty || senha.isEmpty) {
        return 'Email e senha são obrigatórios';
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(), // Remove whitespace
        password: senha,
      );

      if (userCredential.user == null) {
        return 'Falha na autenticação';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'invalid-email':
          return 'Email inválido';
        case 'user-disabled':
          return 'Usuário desabilitado';
        case 'user-not-found':
          return 'Usuário não encontrado';
        case 'wrong-password':
          return 'Senha incorreta';
        case 'network-request-failed':
          return 'Erro de conexão';
        default:
          return 'Erro: ${e.message}';
      }
    } catch (e) {
      print('Unexpected error: $e');
      return 'Erro inesperado durante o login';
    }
  }

  Future<void> logout() async {
    return _firebaseAuth.signOut();
  }
}
