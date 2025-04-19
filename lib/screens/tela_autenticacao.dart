import 'package:flutter/material.dart';
import 'package:projeto_mobile/_common/my_colors.dart';
import 'package:projeto_mobile/components/decoration_autentication_field.dart';

class AutenticacaoTela extends StatefulWidget {
  const AutenticacaoTela({super.key});

  @override
  State<AutenticacaoTela> createState() => _AutenticacaoTelaState();
}

class _AutenticacaoTelaState extends State<AutenticacaoTela> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: MyColors.amareloPadrao,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MyColors.amareloTopoGradiente,
                    MyColors.amareloBaixoGradiente,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 75,
                          backgroundColor: MyColors.cinzaPadrao,
                          child: Image.asset(
                            'assets/carrinho.webp',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        Center(
                          child: Text(
                            "Market-ile!",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                            decoration: getAuthenticationInputDecoration("Email"),
                            validator: (String? value) {
                              if(value == null)
                              {
                                return "O e-mail não pode ser vazio!!!";
                              }
                              if(value.length < 5)
                              {
                                return "O endereço de email é muito curto!";
                              }
                              if(!value.contains("@"))
                              {
                                return "O email não é válido!";
                              }

                                return null;

                            },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: getAuthenticationInputDecoration("Senha"),
                          obscureText: true,
                          validator: (String? value) {
                              if(value == null)
                              {
                                return "A senha não pode ser vazia!";
                              }
                              if(value.length < 5)
                              {
                                return "Senha muito curta!";
                              }
                                return null;
                            },
                          
                        ),
                        Visibility(
                            visible: !isLogin,
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: getAuthenticationInputDecoration("Confirme a senha"),
                                  obscureText: true,
                                  validator: (String? value) {
                                  if(value == null)
                                  {
                                    return "A confirmação de senha não pode ser vazia!";
                                  }
                                  if(value.length < 5)
                                  {
                                    return "Confirmação de senha muito curta!";
                                  }
                                    return null;

                                },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                    decoration: getAuthenticationInputDecoration("Nome de usuário"),
                                    validator: (String? value) {
                                    if(value == null)
                                    {
                                      return "O nome não pode ser vazio!";
                                    }
                                    if(value.length < 5)
                                    {
                                      return "Nome muito curto!";
                                    }
                                      return null;
                                  },
                                    
                                    ),
                                    
                              ],
                            )),
                        const SizedBox(
                          height: 16,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              botaoPrincipalClicado();
                            },
                            child: Text((isLogin) ? "Entrar" : "Cadastrar")),
                        //Divider(),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: Text(
                                (isLogin)
                                    ? "ainda não tem uma conta? cadastre-se"
                                    : "já tem uma conta? entrar",
                                style: TextStyle(fontSize: 10)))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
  botaoPrincipalClicado()
  {
    if(_formKey.currentState!.validate())
    {
      print("Form válido!");
    }
    else{
      print("Form inválido!");
    }
  }
}
