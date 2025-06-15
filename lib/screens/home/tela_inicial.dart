import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto_mobile/data_storage.dart';
import 'package:projeto_mobile/screens/favorites/favorites_screen.dart';
import 'package:projeto_mobile/screens/home/components/search_list.dart';
import 'package:projeto_mobile/servicos/authentication_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../tela_carrinho.dart';
import '../home/tela_favoritos.dart';
import './tela_produto.dart';

// import 'package:projeto_mobile/provider/data_storage.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isVendedor = false;

  // Add this variable to track cart items
  int _cartItemCount = 0;

  // Add this variable to the state class
  Map<String, int> _quantities = {};

  static final List<Widget> _pages = [
    Consumer<DataStorage>(
      builder: (context, dataStorage, child) => const SearchList(),
    ),
    const FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _checkUserType();
    _loadCartItemCount(); // Add this line
  }

  // Update the _loadCartItemCount method
  void _loadCartItemCount() {
    try {
      // Listen to cart changes
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('carrinho')
          .where('finalizada', isEqualTo: false)
          .limit(1)  // Get only the active cart
          .snapshots()
          .listen((carrinhoSnapshot) {
        if (!carrinhoSnapshot.docs.isEmpty) {
          // Get the active cart reference
          final activeCart = carrinhoSnapshot.docs.first;
          
          // Listen to compra collection changes
          activeCart.reference
              .collection('compra')
              .snapshots()
              .listen((compraSnapshot) {
            if (mounted) {
              setState(() {
                _cartItemCount = compraSnapshot.docs.length;
                print('Cart items updated: $_cartItemCount items');
              });
            }
          });
        } else {
          if (mounted) {
            setState(() {
              _cartItemCount = 0;
              print('No active cart found');
            });
          }
        }
      });
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  Future<void> _checkUserType() async {
    try {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
          
      setState(() {
        _isVendedor = userData.data()?['tipoUsuario'] == 'vendedor';
      });
    } catch (e) {
      print('Error checking user type: $e');
    }
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

  // Update the _getFilteredProducts method
  Stream<QuerySnapshot> _getFilteredProducts() {
    if (_searchQuery.isEmpty) {
      return FirebaseFirestore.instance
          .collection('produtos')
          .snapshots();
    }

    // Create wildcard pattern for case-insensitive search
    String searchTerm = _searchQuery;
    
    return FirebaseFirestore.instance
        .collection('produtos')
        .orderBy('nome')
        .startAt([searchTerm])
        .endAt([searchTerm + '\uf8ff'])
        .snapshots();
  }

  // Add this method to create product with searchable fields
  Future<void> createProductWithSearch(Map<String, dynamic> productData) async {
    // Add lowercase version of name for searching
    productData['nomeLowerCase'] = productData['nome'].toLowerCase();
    
    await FirebaseFirestore.instance
        .collection('produtos')
        .add(productData);
  }

  // Add this method to generate search tokens
  List<String> _generateSearchTokens(String text) {
    final words = text.toLowerCase().split(' ');
    final tokens = <String>{};
    
    for (var word in words) {
      for (int i = 1; i <= word.length; i++) {
        tokens.add(word.substring(0, i));
      }
    }
    
    return tokens.toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selected_Index = index;
    });
  }

  // Add this method to handle quantity updates
  void _updateQuantity(String productId, bool increment) {
    setState(() {
      _quantities[productId] = (_quantities[productId] ?? 1) + (increment ? 1 : -1);
      if (_quantities[productId]! < 1) _quantities[productId] = 1;
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
          padding: EdgeInsets.zero,  // Add this line
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
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar produtos por nome...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Product list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredProducts(),
              builder: (context, snapshot) {
                // Add debug logging
                print('Search query: $_searchQuery');
                print('Snapshot has data: ${snapshot.hasData}');
                print('Number of docs: ${snapshot.data?.docs.length ?? 0}');

                if (snapshot.hasError) {
                  print('Search error: ${snapshot.error}');
                  return const Center(child: Text('Erro ao carregar produtos'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado'));
                }

                // Replace the existing GridView.builder with this responsive version
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallDevice = constraints.maxWidth <= 425;
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallDevice ? 1 : (constraints.maxWidth > 600 ? 3 : 2),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: isSmallDevice ? 1.5 : 0.7, // Adjust aspect ratio for single column
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return Card(
                          elevation: 4,
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              return isSmallDevice
                                  ? _buildHorizontalCard(context, data, doc, cardConstraints)
                                  : _buildVerticalCard(context, data, doc, cardConstraints);
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected_Index,
        onTap: (index) {
          if (index == 2) { // Cart tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaCarrinho()),
            );
          } else if (index == 1) { // Favorites tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaFavoritos()),
            );
          } else {
            setState(() {
              _selected_Index = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Carrinho',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 14),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, Map<String, dynamic> data, 
      DocumentSnapshot doc, BoxConstraints constraints) {
    return Row(
      children: [
        // Product Image
        Container(
          width: 140,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(data['imagemUrl'] ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Product Details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  data['nome'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price
                Text(
                  'R\$ ${(data['preco'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  data['descricao'] ?? '',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaProduto(produtoId: doc.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Ver Detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
                const Spacer(),
                // Quantity Controls
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => _updateQuantity(doc.id, false),
                      ),
                      Text(
                        '${_quantities[doc.id] ?? 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => _updateQuantity(doc.id, true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Get reference to user's cart
                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid);

                        // Find or create active cart
                        final cartsQuery = await userRef
                            .collection('carrinho')
                            .where('finalizada', isEqualTo: false)
                            .get();

                        DocumentReference cartRef;
                        if (cartsQuery.docs.isEmpty) {
                          // Create new cart
                          cartRef = await userRef.collection('carrinho').add({
                            'iniciadaEm': FieldValue.serverTimestamp(),
                            'finalizada': false,
                            'totalValorCompra': 0,
                          });
                        } else {
                          cartRef = cartsQuery.docs.first.reference;
                        }

                        // Add item to cart
                        final compraRef = await cartRef.collection('compra').add({
                          'idProdItemCompra': doc.id,
                          'qtdProdItemCompra': _quantities[doc.id] ?? 1,
                          'timeStamp': FieldValue.serverTimestamp(),
                        });

                        // Get product price and update totals
                        final produtoDoc = await FirebaseFirestore.instance
                            .collection('produtos')
                            .doc(doc.id)
                            .get();
                        final preco = produtoDoc.data()?['preco'] ?? 0.0;

                        // Calculate and update subtotal
                        final subtotal = preco * (_quantities[doc.id] ?? 1);
                        await compraRef.update({
                          'subTotalItemCompra': subtotal,
                        });

                        // Update cart total
                        final compraItems = await cartRef.collection('compra').get();
                        final total = compraItems.docs.fold<double>(
                          0,
                          (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                        );

                        await cartRef.update({
                          'totalValorCompra': total,
                        });

                        // Cart count will update automatically through the stream listener

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produto adicionado ao carrinho'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error adding to cart: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao adicionar ao carrinho'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalCard(BuildContext context, Map<String, dynamic> data, 
      DocumentSnapshot doc, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(data['imagemUrl'] ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Product Details
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name and Details
                Text(
                  data['nome'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${(data['preco'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['descricao'] ?? '',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaProduto(produtoId: doc.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Ver Detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
                const Spacer(),
                // Quantity Controls
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => _updateQuantity(doc.id, false),
                      ),
                      Text(
                        '${_quantities[doc.id] ?? 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => _updateQuantity(doc.id, true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid);

                        final cartsQuery = await userRef
                            .collection('carrinho')
                            .where('finalizada', isEqualTo: false)
                            .get();

                        DocumentReference cartRef;
                        if (cartsQuery.docs.isEmpty) {
                          cartRef = await userRef.collection('carrinho').add({
                            'iniciadaEm': FieldValue.serverTimestamp(),
                            'finalizada': false,
                            'totalValorCompra': 0,
                          });
                        } else {
                          cartRef = cartsQuery.docs.first.reference;
                        }

                        final compraRef = await cartRef.collection('compra').add({
                          'idProdItemCompra': doc.id,
                          'qtdProdItemCompra': _quantities[doc.id] ?? 1,
                          'timeStamp': FieldValue.serverTimestamp(),
                        });

                        final produtoDoc = await FirebaseFirestore.instance
                            .collection('produtos')
                            .doc(doc.id)
                            .get();
                        final preco = produtoDoc.data()?['preco'] ?? 0.0;

                        final subtotal = preco * (_quantities[doc.id] ?? 1);
                        await compraRef.update({
                          'subTotalItemCompra': subtotal,
                        });

                        final compraItems = await cartRef.collection('compra').get();
                        final total = compraItems.docs.fold<double>(
                          0,
                          (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                        );

                        await cartRef.update({
                          'totalValorCompra': total,
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produto adicionado ao carrinho'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error adding to cart: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao adicionar ao carrinho'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Top-level function to generate search tokens for example usage
List<String> generateSearchTokens(String text) {
  final words = text.toLowerCase().split(' ');
  final tokens = <String>{};

  for (var word in words) {
    for (int i = 1; i <= word.length; i++) {
      tokens.add(word.substring(0, i));
    }
  }

  return tokens.toList();
}

// Example of how to structure a product document
final productData = {
  'nome': 'Nome do Produto',
  'descricao': 'Descrição do produto',
  'preco': 99.99,
  'imagemUrl': 'url_da_imagem',
  'searchTokens': [
    ...generateSearchTokens('Nome do Produto'),
    ...generateSearchTokens('Descrição do produto'),
  ],
};

// Run this once to update existing products
Future<void> updateExistingProducts() async {
  final products = await FirebaseFirestore.instance
      .collection('produtos')
      .get();
      
  for (var doc in products.docs) {
    await doc.reference.update({
      'nomeLowerCase': doc.data()['nome'].toLowerCase(),
    });
  }
}