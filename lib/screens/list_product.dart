import 'dart:developer' as console;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_ui_storage/firebase_ui_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_mobile/screens/add_product.dart';
import 'package:projeto_mobile/screens/edit_product.dart';
import 'package:projeto_mobile/servicos/authentication_service.dart';
import 'package:projeto_mobile/servicos/produto_service.dart';
import 'package:rxdart/rxdart.dart';

class ListaProdutosScreen extends StatefulWidget {
  const ListaProdutosScreen({super.key});

  @override
  State<ListaProdutosScreen> createState() => _ListaProdutosScreenState();
}

class _ListaProdutosScreenState extends State<ListaProdutosScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final AuthenticationService _authService = AuthenticationService();
  bool _isVendedor = false;

  // Add these new variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  // Update the _isVendedor check in _checkUserType method
  Future<void> _checkUserType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        setState(() {
          _isVendedor = userData.data()?['tipoUsuario'] == 'vendedor';
        });
      }
    } catch (e) {
      console.log('Error checking user type: $e');
    }
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      httpHeaders: const {
        'Access-Control-Allow-Origin': '*',
      },
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      ),
    );
  }

  Future<String> _getImageUrl(String path) async {
  if (path.isEmpty) {
    throw Exception('Image path is empty');
  }

  try {
    if (path.startsWith('http')) {
      return path;
    }
    
    final ref = FirebaseStorage.instance.ref(path);
    final url = await ref.getDownloadURL();
    
    // Validate URL
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      throw Exception('Invalid URL format');
    }
    
    return url;
  } catch (e) {
    console.log('Error getting image URL: $e');
    throw Exception('Failed to load image: $e');
  }
}
  
  // Add this method to handle search
  Stream<QuerySnapshot> _getFilteredProducts() {
  if (_searchQuery.isEmpty) {
    return FirebaseFirestore.instance
        .collection('produtos')
        .snapshots();
  }

  final searchTerms = _searchQuery;
  
  return FirebaseFirestore.instance
      .collection('produtos')
      .where('nome', isGreaterThanOrEqualTo: searchTerms)
      .where('nome', isLessThanOrEqualTo: searchTerms + '\uf8ff')
      .orderBy('nome')
      .snapshots();
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.logout();
            },
          ),
        ],
      ),
      // Add search bar below AppBar
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar produtos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                ),
              ],
            ),
          ),
          // Existing StreamBuilder wrapped in Expanded
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Replace stream with filtered stream
              stream: _getFilteredProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Algo deu errado'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // Remove childAspectRatio para permitir altura dinâmica
                    mainAxisExtent: 380, // Altura fixa inicial para cada item
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: _buildImageWidget(data['imagemUrl']?.toString()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['nome']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['descricao']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'R\$ ${(data['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estoque: ${(data['qtdEstoque'] as num?)?.toString() ?? '0'} un',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              
                            ),
                          ),
                          // Show edit/delete buttons only for vendedor
                          if (_isVendedor) ...[
                            Positioned(
                              top: 0,
                              right: 40,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProdutoScreen(produtoId: doc.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text('Deseja realmente excluir este produto?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await _produtoService.deleteProduto(
                                        doc.id,
                                        data['imagemUrl']?.toString(),
                                      );
                                      
                                      // Show success message
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Produto excluído com sucesso'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Erro ao excluir produto'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Replace the existing FloatingActionButton code
      floatingActionButton: _isVendedor ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProdutoScreen(),
            ),
          );
        },
        label: const Text('Novo Produto', style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.add, color:  Colors.white),
        backgroundColor: Colors.blue,
        tooltip: 'Adicionar novo produto',
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

//   Future<String> _getImageUrl(String path) async {
//     try {
//       final ref = FirebaseStorage.instance.ref(path);
//       return await ref.getDownloadURL();
//     } catch (e) {
//       print('Error getting image URL: $e');
//       throw e;
//     }
//   }
}