import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto_mobile/screens/favorites/favorites_screen.dart';
import 'package:projeto_mobile/screens/home/components/search_list.dart';
import 'package:projeto_mobile/servicos/authentication_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TelaInicial extends StatefulWidget {
  final User user;

  const TelaInicial({
    super.key,
    required this.user,
  });

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}
// TELA INICIAL DE CLIENTE
class _TelaInicialState extends State<TelaInicial> {
  int _selected_Index = 0;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  static const List<Widget> _pages = [
    SearchList(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.user.uid}.jpg');
      
      final url = await ref.getDownloadURL();
      setState(() {
        _profileImageUrl = url;
      });
    } catch (e) {
      // 
    }
  }

  Future<void> _changeProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.user.uid}.jpg');
      
      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();
      
      setState(() {
        _profileImageUrl = url;
      });
    }
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Opções de Imagem'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Ver Imagem'),
                  onTap: () {
                    Navigator.pop(context);
                    if (_profileImageUrl != null || _imageFile != null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              width: double.infinity,
                              height: 400,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.contain,
                                  image: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : NetworkImage(_profileImageUrl!) as ImageProvider,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Alterar Imagem'),
                  onTap: () {
                    Navigator.pop(context);
                    _changeProfileImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selected_Index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bem vindo(a) ao Market-ile!'),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: GestureDetector(
                  onTap: _showImageOptions,
                  child: CircleAvatar(
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage("assets/giant-servbot.gif") as ImageProvider,
                    child: (_imageFile == null && _profileImageUrl == null)
                        ? const Icon(Icons.add_a_photo, color: Colors.white)
                        : null,
                  ),
                ),
                  accountName: Text((widget.user.displayName != null)
                      ? widget.user.displayName!
                      : ""),
                  accountEmail: Text(widget.user.email!)),
              ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {
                    AuthenticationService().logout();
                  }),
            ],
          ),
        ),
        body: _pages[_selected_Index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selected_Index,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Favoritos",
            )
          ],
        ));
  }
}