import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/models/beer.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class DetailsInfo extends StatelessWidget {
  final Beer beer;
  const DetailsInfo({super.key, required this.beer});

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
                  Text(beer.name),
                  Text(beer.description),
                ],
              ),
            )),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.0),
          child: Consumer<DataStorage>(
            builder: ((consumerCtx, dataStorage, child) {
              bool beerIsAddedToFavorites = dataStorage.favoriteBeers
                      .firstWhereOrNull(
                          (favoriteBeer) => favoriteBeer.id == beer.id) !=
                  null;
              return ElevatedButton.icon(
                icon: const Icon(Icons.favorite),
                label: beerIsAddedToFavorites 
                ? const Text("Added to Favorites") 
                : const Text("Adicionar item aos favoritos"),
                onPressed: beerIsAddedToFavorites 
                ? null 
                : () {
                  dataStorage.addBeerToFavorites(beer);
                },
              );
            }),
          ),
        )
      ]),
    );
  }
}
