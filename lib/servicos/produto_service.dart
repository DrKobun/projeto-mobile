import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProdutoService {
  final CollectionReference produtos = FirebaseFirestore.instance.collection('produtos');

  Future<void> addProduto(String nome, String descricao, {String? imagemUrl}) async {
    await produtos.add({
      'nome': nome,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Future<String> uploadImage(String path, XFile image) async
  {

    final ref = FirebaseStorage.instance.ref(path).child(image.name);
    await ref.putFile(File(image.path)); 
    final url = await ref.getDownloadURL();
    return url;

    
  }

  Stream<QuerySnapshot> getProdutos() {
    return produtos.orderBy('timestamp', descending: true).snapshots();
  }
}