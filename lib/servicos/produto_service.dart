import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProdutoService {
  final CollectionReference produtos = FirebaseFirestore.instance.collection('produtos');

  Future<void> addProduto(
    String nome,
    String descricao,
    double preco,
    int qtdEstoque, {
    String? imagemUrl,
  }) async {
    await produtos.add({
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'qtdEstoque': qtdEstoque,
      'imagemUrl': imagemUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadImage(String path, XFile image) async {
    final ref = FirebaseStorage.instance.ref(path).child(image.name);
    await ref.putFile(File(image.path));
    final url = await ref.getDownloadURL();
    return url;
  }

  Future<String> getImageUrl(String path) async {
    try {
      if (path.startsWith('http')) {
        return path; // Already a URL
      }
      
      final ref = FirebaseStorage.instance.ref(path);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting image URL: $e');
      throw Exception('Failed to load image');
    }
  }

  Stream<QuerySnapshot> getProdutos() {
    return produtos.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> deleteProduto(String id, String? imageUrl) async {
    try {
      // Delete document from Firestore
      await FirebaseFirestore.instance.collection('produtos').doc(id).delete();

      // Delete image from Storage if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product');
    }
  }

  Future<void> updateProduto(
    String id, 
    Map<String, dynamic> data, 
    File? novaImagem,
    Uint8List? novaImagemWeb,
    String? imagemUrlAntiga,
  ) async {
    try {
      if (novaImagem != null || novaImagemWeb != null) {
        // Delete old image if exists
        if (imagemUrlAntiga != null) {
          try {
            final oldRef = FirebaseStorage.instance.refFromURL(imagemUrlAntiga);
            await oldRef.delete();
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }

        // Upload new image
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('produtos/${DateTime.now().millisecondsSinceEpoch}');

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(novaImagemWeb!);
        } else {
          uploadTask = storageRef.putFile(novaImagem!);
        }

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        data['imagemUrl'] = url;
      }

      // Update document
      await FirebaseFirestore.instance.collection('produtos').doc(id).update(data);
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product');
    }
  }

  Future<Map<String, dynamic>?> getProdutoById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('produtos').doc(id).get();
      return doc.data();
    } catch (e) {
      print('Error getting product: $e');
      throw Exception('Failed to get product');
    }
  }

  Stream<QuerySnapshot> searchProdutos(String query) {
    final searchLower = query.toLowerCase();

    return FirebaseFirestore.instance
        .collection('produtos')
        .where('nome', isGreaterThanOrEqualTo: searchLower)
        .where('nome', isLessThanOrEqualTo: searchLower + '\uf8ff')
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> _getFilteredProducts(String _searchQuery) async* {
    final baseQuery = FirebaseFirestore.instance.collection('produtos');
    
    if (_searchQuery.isEmpty) {
      yield* baseQuery.snapshots().map((snapshot) => snapshot.docs);
      return;
    }

    final searchLower = _searchQuery.toLowerCase();

    // Firestore does not support OR queries directly, so we perform two queries and merge results.
    final nomeQuery = baseQuery
        .where('nome', isGreaterThanOrEqualTo: searchLower)
        .where('nome', isLessThanOrEqualTo: searchLower + '\uf8ff')
        .snapshots();

    final descricaoQuery = baseQuery
        .where('descricao', isGreaterThanOrEqualTo: searchLower)
        .where('descricao', isLessThanOrEqualTo: searchLower + '\uf8ff')
        .snapshots();

    await for (final nomeSnapshot in nomeQuery) {
      final descricaoSnapshot = await descricaoQuery.first;
      // Merge and remove duplicates
      final allDocs = [
        ...nomeSnapshot.docs,
        ...descricaoSnapshot.docs.where((doc) => !nomeSnapshot.docs.any((d) => d.id == doc.id)),
      ];
      yield allDocs;
    }
  }
}