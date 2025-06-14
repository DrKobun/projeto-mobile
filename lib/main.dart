import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/screens/home/tela_inicial.dart';
import 'package:projeto_mobile/screens/list_product.dart';
import 'package:projeto_mobile/screens/tela_autenticacao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 if (kIsWeb) {
    // Web-specific initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
  } else {
    // Non-web initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataStorage()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RoteadorTela(),
    );
  }
}

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasData) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final tipoUsuario = userData['tipoUsuario'] as String;

                if (tipoUsuario == 'vendedor') {
                  return ListaProdutosScreen();
                } else {
                  return TelaInicial(
                    user: snapshot.data!,
                  );
                }
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        } else {
          return AutenticacaoTela();
        }
      },
    );
  }
}
