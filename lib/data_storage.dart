import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projeto_mobile/models/produto.dart';

class DataStorage extends ChangeNotifier {
  String _searchedTerm = '';
  List<Produto> _favoriteProdutos = [];

  String get searchedTerm => _searchedTerm;
  List<Produto> get favoriteProdutos => UnmodifiableListView(_favoriteProdutos);

  void setSearchedTerm(String newTerm) {
    _searchedTerm = newTerm;
    notifyListeners();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/favorites.json');
  }

  Future<void> fetchFavoriteProdutos() async {
    try {
      final file = await _localFile;

      if (!await file.exists()) {
        await file.create();
      }

      String fileContent = await file.readAsString();
      List<dynamic> jsonFileContent = jsonDecode(fileContent);
      List<Produto> produtos = jsonFileContent
          .map(
            (dynamic item) => Produto.fromJson(item),
          )
          .toList();

      _favoriteProdutos = produtos;
      notifyListeners();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> addProdutoToFavorites(Produto newFavoriteProduto) async {

    try
    {
      final file = await _localFile;

      if(!await file.exists())
      {
        await file.create();
      }

      _favoriteProdutos.add(newFavoriteProduto);
      notifyListeners();
      await file.writeAsString(json.encode(_favoriteProdutos).toString());
    }catch(e)
    {
      throw Exception(e);
    }
  }

  Future<void> removeProdutoFromFavorites(int produtoId) async {
    try {
      final file = await _localFile;

      if (!await file.exists()) {
        await file.create();
      }

      List<Produto> newList = _favoriteProdutos.where((produto) => produto.id !=produtoId).toList();
      _favoriteProdutos = newList;
      notifyListeners();
      
      await file.writeAsString(json.encode(_favoriteProdutos).toString());
    } catch (e) {
      throw Exception(e);
    }
  } 
}
