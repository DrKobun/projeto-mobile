import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoService {
  final CollectionReference produtos = FirebaseFirestore.instance.collection('produtos');

  Future<void> addProduto(String nome, String descricao) async {
    await produtos.add({
      'nome': nome,
      'descricao': descricao,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getProdutos() {
    return produtos.orderBy('timestamp', descending: true).snapshots();
  }
}