import 'package:flutter/material.dart';
import 'package:projeto_mobile/http_service.dart';
import 'package:projeto_mobile/models/beer.dart';
import 'package:projeto_mobile/screens/details/components/datails_info.dart';
import 'package:projeto_mobile/screens/details/components/details_app_bar.dart';

class DetailsScreen extends StatefulWidget 
{
  final int id;
  const DetailsScreen({super.key, required this.id});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> 
{

  final HttpService _httpService = HttpService();
  late Future<Beer> _beerDetails;
  

  @override
  void initState() {
    super.initState();
    _beerDetails = _httpService.fetchSingleBeer(widget.id);
  }
  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      body: FutureBuilder
      (
        future: _beerDetails,
        builder:(
          BuildContext context, 
          AsyncSnapshot snapshot,
        ){
          if(snapshot.hasData)
          {
            return CustomScrollView
            (
              physics: const BouncingScrollPhysics
              (
                parent: AlwaysScrollableScrollPhysics(), 
              ),
              slivers: <Widget>
              [                                       //try just image
                DetailsAppBar(imageUrl: snapshot.data.imageUrl,),
                DetailsInfo(beer: snapshot.data),
              ],
            );
          }
          else if(snapshot.hasError)
          {
            return Text('${snapshot.error}');
          }

          return const Center
          (
            child: CircularProgressIndicator()
          );

        },
      ),
    );
  }
}