import 'package:flutter/material.dart';
import 'package:projeto_mobile/screens/home/components/beers_list.dart';
import 'package:projeto_mobile/screens/home/components/search_input.dart';

class SearchList extends StatelessWidget 
{
  const SearchList({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return Column
    (
      children: const<Widget>
      [
        SearchInput(), 
        BeersList(),   
      ],
    );
  }
}