import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/screens/home/tela_inicial.dart';
import 'package:projeto_mobile/screens/home/tela_inicial_vendedor.dart';
import 'package:projeto_mobile/screens/login_form.dart';
import 'package:projeto_mobile/screens/tela_autenticacao.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
  runApp(ChangeNotifierProvider(
      create: (context) => DataStorage(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RoteadorTela(),
            //RoteadorTela(),
    );
  }
}

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(), 
      builder: (context, snapshot)
      {
        if(snapshot.hasData)
        {
          return InicioTelaVendedor();//TelaInicial();
        }
        else
        {
          return AutenticacaoTela();
        }
      },
    );
  }
}