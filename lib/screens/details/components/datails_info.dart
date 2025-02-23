import 'package:flutter/material.dart';
import 'package:projeto_mobile/models/beer.dart';

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
              margin: EdgeInsets.all(10.0),
              horizontal: 10.0,
            ),
            ElevatedButton.icon(
              onPressed: (){},
              label: const Text("Adicionar item aos favoritos!"),
              icon: const Icon(Icons.favorite),
              ),
      ]),
    );
  }
}
