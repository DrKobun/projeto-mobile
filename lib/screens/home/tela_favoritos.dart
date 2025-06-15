import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './tela_produto.dart';
import '../tela_carrinho.dart';

class TelaFavoritos extends StatefulWidget {
  const TelaFavoritos({Key? key}) : super(key: key);

  @override
  State<TelaFavoritos> createState() => _TelaFavoritosState();
}

class _TelaFavoritosState extends State<TelaFavoritos> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int _selected_Index = 1; // Start with favorites tab selected
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
  }

  void _loadCartItemCount() {
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .collection('carrinho')
          .where('finalizada', isEqualTo: false)
          .limit(1)
          .snapshots()
          .listen((carrinhoSnapshot) {
        if (!carrinhoSnapshot.docs.isEmpty) {
          final activeCart = carrinhoSnapshot.docs.first;

          activeCart.reference
              .collection('compra')
              .snapshots()
              .listen((compraSnapshot) {
            if (mounted) {
              setState(() {
                _cartItemCount = compraSnapshot.docs.length;
              });
            }
          });
        } else {
          if (mounted) {
            setState(() {
              _cartItemCount = 0;
            });
          }
        }
      });
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  Future<Map<String, dynamic>?> _getProdutoDetails(String produtoId) async {
    try {
      final produtoDoc = await FirebaseFirestore.instance
          .collection('produtos')
          .doc(produtoId)
          .get();
      return produtoDoc.data();
    } catch (e) {
      print('Error fetching produto details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Usuário não autenticado'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .collection('favoritos')
            .snapshots(),
        builder: (context, favoritosSnapshot) {
          if (favoritosSnapshot.hasError) {
            return const Center(child: Text('Erro ao carregar favoritos'));
          }

          if (favoritosSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!favoritosSnapshot.hasData || favoritosSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum produto favorito'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: favoritosSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final favorito = favoritosSnapshot.data!.docs[index];
              final idProdFavorito = favorito['idProdFavorito'] as String;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getProdutoDetails(idProdFavorito),
                builder: (context, produtoSnapshot) {
                  if (!produtoSnapshot.hasData) {
                    return const Card(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final produtoData = produtoSnapshot.data!;

                  return Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(produtoData['imagemUrl'] ?? ''),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            produtoData['nome'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'R\$ ${(produtoData['preco'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TelaProduto(produtoId: idProdFavorito),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('Ver Detalhes'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await favorito.reference.delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produto removido dos favoritos'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('Error removing favorite: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Erro ao remover dos favoritos'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected_Index,
        onTap: (index) {
          if (index == 2) { // Cart tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaCarrinho()),
            );
          } else if (index == 0) { // Home tab
            Navigator.pop(context);
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
}