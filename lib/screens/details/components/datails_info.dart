import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/models/produto.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class DetailsInfo extends StatelessWidget {
  final Produto produto;
  const DetailsInfo({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Card(
            margin: EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text(produto.name),
                  Text(produto.description),
                ],
              ),
            )),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.0),
          child: Consumer<DataStorage>(
            builder: ((consumerCtx, dataStorage, child) {
              bool produtoIsAddedToFavorites = dataStorage.favoriteProdutos
                      .firstWhereOrNull(
                          (favoriteProduto) => favoriteProduto.id == produto.id) !=
                  null;
              return ElevatedButton.icon(
                icon: const Icon(Icons.favorite),
                label: produtoIsAddedToFavorites 
                ? const Text("Added to Favorites") 
                : const Text("Adicionar item aos favoritos"),
                onPressed: produtoIsAddedToFavorites 
                ? null 
                : () {
                  dataStorage.addProdutoToFavorites(produto);
                },
              );
            }),
          ),
        )
      ]),
    );
  }
}
