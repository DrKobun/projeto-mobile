import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaCarrinho extends StatefulWidget {
  const TelaCarrinho({super.key});

  @override
  State<TelaCarrinho> createState() => _TelaCarrinhoState();
}

class _TelaCarrinhoState extends State<TelaCarrinho> {
  // Change user to private and non-final to allow promotion
  User? _user = FirebaseAuth.instance.currentUser;

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
    // Early return if user is null
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user?.uid) // Use safe call operator
                  .collection('carrinho')
                  .where('finalizada', isEqualTo: false)
                  .limit(1)
                  .snapshots(),
              builder: (context, carrinhoSnapshot) {
                if (carrinhoSnapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar carrinho'));
                }

                if (carrinhoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!carrinhoSnapshot.hasData || carrinhoSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum carrinho ativo'));
                }

                final carrinhoAtivo = carrinhoSnapshot.data!.docs.first;
                // Fix the data access with proper casting
                final carrinhoData = carrinhoAtivo.data() as Map<String, dynamic>;
                final totalValorCompra = carrinhoData['totalValorCompra'] ?? 0.0;

                return StreamBuilder<QuerySnapshot>(
                  stream: carrinhoAtivo.reference
                      .collection('compra')
                      .snapshots(),
                  builder: (context, compraSnapshot) {
                    if (compraSnapshot.hasError) {
                      return const Center(child: Text('Erro ao carregar itens'));
                    }

                    if (compraSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!compraSnapshot.hasData || compraSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Carrinho vazio'));
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: compraSnapshot.data!.docs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final compraDoc = compraSnapshot.data!.docs[index];
                              final compraData = compraDoc.data() as Map<String, dynamic>;

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _getProdutoDetails(compraData['idProdItemCompra']),
                                builder: (context, produtoSnapshot) {
                                  if (!produtoSnapshot.hasData) {
                                    return const Card(
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }

                                  final produtoData = produtoSnapshot.data!;

                                  // Replace the existing Card widget with this responsive version
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          // Adjust layout based on available width
                                          final isNarrow = constraints.maxWidth < 360;
                                          
                                          return isNarrow
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Product name and delete button
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            produtoData['nome'] ?? 'Produto não encontrado',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                          onPressed: () async {
                                                            try {
                                                              // Delete the item
                                                              await compraDoc.reference.delete();

                                                              // Recalculate cart total
                                                              final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                                  .collection('compra')
                                                                  .get();

                                                              final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                                0,
                                                                (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                              );

                                                              // Update cart total
                                                              await carrinhoAtivo.reference.update({
                                                                'totalValorCompra': newTotal,
                                                              });

                                                              if (context.mounted) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text('Item removido do carrinho'),
                                                                    backgroundColor: Colors.green,
                                                                    duration: Duration(seconds: 2),
                                                                  ),
                                                                );
                                                              }
                                                            } catch (e) {
                                                              print('Error removing item: $e');
                                                              if (context.mounted) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text('Erro ao remover item'),
                                                                    backgroundColor: Colors.red,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(minWidth: 40),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Quantity controls and price
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        // Quantity controls
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.remove, size: 18),
                                                              onPressed: compraData['qtdProdItemCompra'] > 1 
                                                                ? () async {
                                                                    try {
                                                                      final newQtd = compraData['qtdProdItemCompra'] - 1;
                                                                      final produtoPreco = produtoData['preco'] ?? 0.0;
                                                                      final newSubTotal = produtoPreco * newQtd;

                                                                      // Update quantity and subtotal
                                                                      await compraDoc.reference.update({
                                                                        'qtdProdItemCompra': newQtd,
                                                                        'subTotalItemCompra': newSubTotal,
                                                                      });

                                                                      // Recalculate cart total
                                                                      final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                                          .collection('compra')
                                                                          .get();

                                                                      final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                                        0,
                                                                        (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                                      );

                                                                      // Update cart total
                                                                      await carrinhoAtivo.reference.update({
                                                                        'totalValorCompra': newTotal,
                                                                      });
                                                                    } catch (e) {
                                                                      print('Error updating quantity: $e');
                                                                      if (context.mounted) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          const SnackBar(
                                                                            content: Text('Erro ao atualizar quantidade'),
                                                                            backgroundColor: Colors.red,
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  }
                                                                : null,
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(minWidth: 30),
                                                            ),
                                                            SizedBox(
                                                              width: 30,
                                                              child: Text(
                                                                '${compraData['qtdProdItemCompra']}',
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.add, size: 18),
                                                              onPressed: () async {
                                                                try {
                                                                  final newQtd = compraData['qtdProdItemCompra'] + 1;
                                                                  final produtoPreco = produtoData['preco'] ?? 0.0;
                                                                  final newSubTotal = produtoPreco * newQtd;

                                                                  // Update quantity and subtotal
                                                                  await compraDoc.reference.update({
                                                                    'qtdProdItemCompra': newQtd,
                                                                    'subTotalItemCompra': newSubTotal,
                                                                  });

                                                                  // Recalculate cart total
                                                                  final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                                      .collection('compra')
                                                                      .get();

                                                                  final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                                    0,
                                                                    (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                                  );

                                                                  // Update cart total
                                                                  await carrinhoAtivo.reference.update({
                                                                    'totalValorCompra': newTotal,
                                                                  });
                                                                } catch (e) {
                                                                  print('Error updating quantity: $e');
                                                                  if (context.mounted) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text('Erro ao atualizar quantidade'),
                                                                        backgroundColor: Colors.red,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(minWidth: 30),
                                                            ),
                                                          ],
                                                        ),
                                                        // Price
                                                        Text(
                                                          'R\$ ${compraData['subTotalItemCompra']?.toStringAsFixed(2) ?? '0.00'}',
                                                          style: const TextStyle(
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  children: [
                                                    // Product name
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        produtoData['nome'] ?? 'Produto não encontrado',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Quantity controls
                                                    Container(
                                                      constraints: const BoxConstraints(minWidth: 100),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.remove, size: 20),
                                                            onPressed: compraData['qtdProdItemCompra'] > 1 
                                                              ? () async {
                                                                  try {
                                                                    final newQtd = compraData['qtdProdItemCompra'] - 1;
                                                                    final produtoPreco = produtoData['preco'] ?? 0.0;
                                                                    final newSubTotal = produtoPreco * newQtd;

                                                                    // Update quantity and subtotal
                                                                    await compraDoc.reference.update({
                                                                      'qtdProdItemCompra': newQtd,
                                                                      'subTotalItemCompra': newSubTotal,
                                                                    });

                                                                    // Recalculate cart total
                                                                    final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                                        .collection('compra')
                                                                        .get();

                                                                    final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                                      0,
                                                                      (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                                    );

                                                                    // Update cart total
                                                                    await carrinhoAtivo.reference.update({
                                                                      'totalValorCompra': newTotal,
                                                                    });
                                                                  } catch (e) {
                                                                    print('Error updating quantity: $e');
                                                                    if (context.mounted) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text('Erro ao atualizar quantidade'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                }
                                                              : null,
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(minWidth: 30),
                                                          ),
                                                          SizedBox(
                                                            width: 30,
                                                            child: Text(
                                                              '${compraData['qtdProdItemCompra']}',
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.add, size: 20),
                                                            onPressed: () async {
                                                              try {
                                                                final newQtd = compraData['qtdProdItemCompra'] + 1;
                                                                final produtoPreco = produtoData['preco'] ?? 0.0;
                                                                final newSubTotal = produtoPreco * newQtd;

                                                                // Update quantity and subtotal
                                                                await compraDoc.reference.update({
                                                                  'qtdProdItemCompra': newQtd,
                                                                  'subTotalItemCompra': newSubTotal,
                                                                });

                                                                // Recalculate cart total
                                                                final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                                    .collection('compra')
                                                                    .get();

                                                                final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                                  0,
                                                                  (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                                );

                                                                // Update cart total
                                                                await carrinhoAtivo.reference.update({
                                                                  'totalValorCompra': newTotal,
                                                                });
                                                              } catch (e) {
                                                                print('Error updating quantity: $e');
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text('Erro ao atualizar quantidade'),
                                                                      backgroundColor: Colors.red,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(minWidth: 30),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Price
                                                    Container(
                                                      constraints: const BoxConstraints(minWidth: 80),
                                                      child: Text(
                                                        'R\$ ${compraData['subTotalItemCompra']?.toStringAsFixed(2) ?? '0.00'}',
                                                        textAlign: TextAlign.right,
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    // Delete button
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                      onPressed: () async {
                                                        try {
                                                          // Delete the item
                                                          await compraDoc.reference.delete();

                                                          // Recalculate cart total
                                                          final updatedCompraSnapshot = await carrinhoAtivo.reference
                                                              .collection('compra')
                                                              .get();

                                                          final newTotal = updatedCompraSnapshot.docs.fold<double>(
                                                            0,
                                                            (sum, doc) => sum + (doc.data()['subTotalItemCompra'] ?? 0),
                                                          );

                                                          // Update cart total
                                                          await carrinhoAtivo.reference.update({
                                                            'totalValorCompra': newTotal,
                                                          });

                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Item removido do carrinho'),
                                                                backgroundColor: Colors.green,
                                                                duration: Duration(seconds: 2),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          print('Error removing item: $e');
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Erro ao remover item'),
                                                                backgroundColor: Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 40),
                                                    ),
                                                  ],
                                                );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${totalValorCompra.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Continuar Comprando'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Get reference to active cart
                        final activeCartQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user?.uid)
                            .collection('carrinho')
                            .where('finalizada', isEqualTo: false)
                            .limit(1)
                            .get();

                        if (activeCartQuery.docs.isNotEmpty) {
                          final activeCart = activeCartQuery.docs.first;
                          
                          // Update cart to finalized
                          await activeCart.reference.update({
                            'finalizada': true,
                            'finalizadaEm': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Compra finalizada com sucesso!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            
                            // Return to home screen
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        }
                      } catch (e) {
                        print('Error finalizing purchase: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao finalizar compra'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Finalizar Compra', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Cart tab
        onTap: (index) {
          if (index != 2) { // If not cart tab
            Navigator.pop(context); // Go back to previous screen
            if (index == 0) { // Home tab
              // Make sure we're at the home tab when we go back
              Navigator.popUntil(context, (route) => route.isFirst);
            }
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
}