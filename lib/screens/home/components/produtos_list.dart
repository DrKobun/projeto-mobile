
import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/http_service.dart';
import 'package:projeto_mobile/models/produto.dart';
import 'package:projeto_mobile/screens/details/details_screen.dart';
import 'package:provider/provider.dart';

class ProdutosList extends StatefulWidget 
{
  const ProdutosList({super.key});

  @override
  State<ProdutosList> createState() => _ProdutosListState();
}

class _ProdutosListState extends State<ProdutosList> 
{
  final HttpService _httpService = HttpService();
  late Future<List<Produto>> _produtos;
  

  @override
  void initState() 
  {
    super.initState();
    _produtos = _httpService.fetchProdutos();
  }


  @override
  Widget build(BuildContext context) 
  {
    Size size = MediaQuery.of(context).size;
    return SizedBox
    (

      height: size.height - 245,

      child: FutureBuilder
      (
        future: _produtos, 
        builder: (BuildContext context, AsyncSnapshot snapshot) 
        {  
          if(snapshot.hasData)
          {
            return Consumer<DataStorage>(builder: (consumerCtx, dataStorage, child,) 
            {
              List<Produto> produtosData = snapshot.data;
              List<Produto> filteredProdutosData = produtosData.where((produto) => produto.name.toLowerCase().contains(dataStorage.searchedTerm.toLowerCase())).toList();
              return GridView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: filteredProdutosData.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2), 
              padding: const EdgeInsets.symmetric(horizontal: 10.0,),
              itemBuilder: 
              (_, index){

                return GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(id: filteredProdutosData[index].id)));   
                  },
                  child: Card
                  (
                    child: Padding
                    (
                      padding: const EdgeInsets.all(10.0),
                      child: Column
                      (
                        children: <Widget>
                        [
                          Expanded
                          (
                            child: Image.network(filteredProdutosData[index].imageUrl)
                          ),
                          Container
                          (
                            margin: const EdgeInsets.only(top: 20.0),
                            child: 
                            Text
                            (
                              textAlign: TextAlign.center,
                              filteredProdutosData[index].name,
                              style: 
                              const TextStyle
                              (
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          
                        ], 
                      ),
                    ),
                  ),
                );
              },
            );
            }
            );
            
          }
          else if(snapshot.hasError)
          {
            return Text('${snapshot.error}');
          }
          return const Center
          (
            child: CircularProgressIndicator(),
          );
        },
        
      ),
    );
  }
}