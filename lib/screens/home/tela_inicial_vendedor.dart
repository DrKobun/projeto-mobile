import "package:flutter/material.dart";
import "package:projeto_mobile/models/produto_modelo.dart";
import "package:projeto_mobile/servicos/authentication_service.dart";

class InicioTelaVendedor extends StatelessWidget {
   InicioTelaVendedor({super.key});


  final List<ProdutoModelo> listaProdutos = [
    
  ];
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela de Vendas"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: (){
                AuthenticationService().logout();
              },
            )
          ],
        ),
      ),
    );
  }
}