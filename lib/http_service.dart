import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projeto_mobile/models/beer.dart'; 


class HttpService 
{
  static String baseUrl = 'https://fakestoreapi.com';
  static String getBeersUrl = '$baseUrl/products';

  Future<List<Beer>> fetchBeers() async
  {
    final response = await http.get(Uri.parse(getBeersUrl));

    if(response.statusCode == 200)
    {
      List<dynamic> body = json.decode(response.body);
      List<Beer> beers = body.map((item) => Beer.fromJson(item)).toList();
      return beers;
    }
    else
    {
      throw Exception("Failed to load beers data!");
    }
  }

  Future<Beer> fetchSingleBeer(int beerId) async {
  final response = await http.get(Uri.parse('$getBeersUrl/$beerId'));

  if (response.statusCode == 200) 
  {
    Map<String, dynamic> body = json.decode(response.body);
    
    return Beer.fromJson(body);
  } else {
    throw Exception("Failed to load single beer data!");
  }
}

}