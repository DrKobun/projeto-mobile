import 'package:flutter/material.dart';
import 'package:projeto_mobile/screens/favorites/favorites_screen.dart';
import 'package:projeto_mobile/screens/home/components/search_list.dart';

class TelaInicial extends StatefulWidget 
{
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}


class _TelaInicialState extends State<TelaInicial> 
{
  int _selected_Index = 0;

  static const List<Widget> _pages = 
  [
    SearchList(),
    FavoritesScreen(),
  ];


  void _onItemTapped(int index)
  {
    setState(() {
      _selected_Index = index;
    });
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text('I love programming!'),
      ),
      body: _pages[_selected_Index],
      bottomNavigationBar: BottomNavigationBar
      (
        currentIndex: _selected_Index,
        onTap: _onItemTapped,
        items: 
        const 
        [
          BottomNavigationBarItem
          (
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem
          (
            icon: Icon(Icons.favorite),
            label: "Favoritos",
          )
        ],
      )
    );
  }
}

