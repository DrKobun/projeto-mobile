import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projeto_mobile/data_storage.dart';

class SearchInput extends StatefulWidget 
{
  const SearchInput({super.key});

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> 
{

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() 
  {
    super.initState();
    _controller.text = Provider.of<DataStorage>(context, listen: false).searchedTerm;
  }
  @override
  Widget build(BuildContext context) 
  {
    return Container
    (
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.symmetric
      (
        horizontal: 15.0
      ),
      decoration: BoxDecoration
      (
        color: const Color.fromARGB(255, 203, 216, 231),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Consumer<DataStorage>(builder: (context, dataStorage, child,) {
        return TextField
        (
          controller: _controller,
          onChanged: (text)
          {
            dataStorage.setSearchedTerm(text);
          },
          decoration: const InputDecoration
          (
            hintText: "Search",
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          )
        );
      })
    );
  }
}