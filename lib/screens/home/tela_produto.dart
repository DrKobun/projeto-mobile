import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../tela_carrinho.dart';
import 'tela_favoritos.dart';

class TelaProduto extends StatefulWidget {
  final String produtoId;

  const TelaProduto({Key? key, required this.produtoId}) : super(key: key);

  @override
  State<TelaProduto> createState() => _TelaProdutoState();
}

class _TelaProdutoState extends State<TelaProduto> {
  int _selected_Index = 0;
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('produtos')
            .doc(widget.produtoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produto'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Produto não encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          final dateStr = timestamp != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
              : 'Data não disponível';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(data['imagemUrl'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        data['nome'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Text(
                        'R\$ ${(data['preco'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stock
                      Row(
                        children: [
                          const Icon(Icons.inventory, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Estoque: ${data['qtdEstoque'] ?? 0}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      const Text(
                        'Descrição:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['descricao'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      // Favorite Button
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user?.uid)
                            .collection('favoritos')
                            .where('idProdFavorito', isEqualTo: widget.produtoId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                          
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final favoritosRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user?.uid)
                                      .collection('favoritos');

                                  if (isFavorite) {
                                    // Remove from favorites
                                    await favoritosRef
                                        .where('idProdFavorito', isEqualTo: widget.produtoId)
                                        .get()
                                        .then((snapshot) {
                                      for (var doc in snapshot.docs) {
                                        doc.reference.delete();
                                      }
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produto removido dos favoritos'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Add to favorites
                                    await favoritosRef.add({
                                      'idProdFavorito': widget.produtoId,
                                      'timeStamp': FieldValue.serverTimestamp(),
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produto adicionado aos favoritos'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  print('Error toggling favorite: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Erro ao atualizar favoritos'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              label: Text(isFavorite ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: isFavorite ? Colors.red : Theme.of(context).primaryColor,
                                ),
                                foregroundColor: isFavorite ? Colors.red : Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Quantity Controls
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () => _updateQuantity(widget.produtoId, false),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '${_quantities[widget.produtoId] ?? 1}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () => _updateQuantity(widget.produtoId, true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Get reference to user's cart
                              final userRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user?.uid);

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
                                'idProdItemCompra': widget.produtoId,
                                'qtdProdItemCompra': _quantities[widget.produtoId] ?? 1,
                                'timeStamp': FieldValue.serverTimestamp(),
                              });

                              // Get product price and update totals
                              final produtoDoc = await FirebaseFirestore.instance
                                  .collection('produtos')
                                  .doc(widget.produtoId)
                                  .get();
                              final preco = produtoDoc.data()?['preco'] ?? 0.0;

                              // Calculate and update subtotal
                              final subtotal = preco * (_quantities[widget.produtoId] ?? 1);
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

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Produto adicionado ao carrinho'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
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
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Adicionar ao Carrinho'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected_Index,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaCarrinho()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaFavoritos()),
            );
          } else {
            Navigator.pop(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrinho',
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String productId, bool increment) {
    setState(() {
      _quantities[productId] = (_quantities[productId] ?? 1) + (increment ? 1 : -1);
      if (_quantities[productId]! < 1) _quantities[productId] = 1;
    });
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }
}