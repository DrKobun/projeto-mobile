import 'package:flutter/material.dart';

class DataStorage extends ChangeNotifier 
{
  String _searchedTerm = '';

  String get searchedTerm => _searchedTerm;

  
  void setSearchedTerm(String newTerm)
  {
    _searchedTerm = newTerm;
    notifyListeners(); 
  }
}