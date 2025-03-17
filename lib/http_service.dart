import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projeto_mobile/models/produto.dart'; 


class HttpService 
{
  static String baseUrl = 'https://fakestoreapi.com';
  static String getProdutosUrl = '$baseUrl/products';

  Future<List<Produto>> fetchProdutos() async
  {
    final response = await http.get(Uri.parse(getProdutosUrl));

    if(response.statusCode == 200)
    {
      List<dynamic> body = json.decode(response.body);
      List<Produto> produtos = body.map((item) => Produto.fromJson(item)).toList();
      return produtos;
    }
    else
    {
      throw Exception("Failed to load produtos data!");
    }
  }

  Future<Produto> fetchSingleProduto(int produtoId) async {
  final response = await http.get(Uri.parse('$getProdutosUrl/$produtoId'));

  if (response.statusCode == 200) 
  {
    Map<String, dynamic> body = json.decode(response.body);
    
    return Produto.fromJson(body);
  } else {
    throw Exception("Failed to load single produto data!");
  }
}

}