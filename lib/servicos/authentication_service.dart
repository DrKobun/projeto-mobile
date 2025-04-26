import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //Testar com String? userRegistration
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
        'tipoUsuario': tipoUsuario, // Save the user type
        'createdAt': FieldValue.serverTimestamp(),
      });
      await userCredential.user!.updateDisplayName(nome);
      //teste de adicionar uma coleção de usuário

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return "O usuário já está cadastrado";
      }
      return "Erro desconhecido";
    }
  }

  Future<String?> loginUsers(
      {required String email,
      required String senha,
      required String nome}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    return _firebaseAuth.signOut();
  }
}
