import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/models/produto.dart';
import 'package:projeto_mobile/screens/details/details_screen.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<DataStorage>(context, listen: false).fetchFavoriteProdutos();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      child: Consumer<DataStorage>(builder: (consumerCtx, dataStorage, child) {
        List<Produto> favoriteProdutos = dataStorage.favoriteProdutos;
        if (favoriteProdutos.isNotEmpty) {
          return ListView.builder(
              itemCount: favoriteProdutos.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(id: favoriteProdutos[index].id),
                        ),
                      );
                    },
                    title: Text(favoriteProdutos[index].name),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(favoriteProdutos[index].imageUrl),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        dataStorage.removeProdutoFromFavorites(favoriteProdutos[index].id);
                      },
                    ),
                  ),
                );
              });
        } else {
          return Center(
            child: Text("List of favorite produtos is empty"),
          );
        }
      }),
    );
  }
}
