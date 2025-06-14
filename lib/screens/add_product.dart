import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:projeto_mobile/servicos/produto_service.dart';

class AddProdutoScreen extends StatefulWidget {
  const AddProdutoScreen({super.key});

  @override
  State<AddProdutoScreen> createState() => _AddProdutoScreenState();
}

class _AddProdutoScreenState extends State<AddProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _qtdEstoqueController = TextEditingController();
  final _produtoService = ProdutoService();

  XFile? _imageFile;
  String? _imageUrl;
  Uint8List? _webImage; // Add this field

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = picked;
          if (kIsWeb) {
            picked.readAsBytes().then((value) {
              setState(() {
                _webImage = value;
              });
            });
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('produtos')
          .child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        // Handle Web Upload
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/${image.name.split('.').last}',
            customMetadata: {'picked-file-path': image.name}
          ),
        );
      } else {
        // Handle Android Upload
        uploadTask = storageRef.putFile(
          File(image.path),
          SettableMetadata(
            contentType: 'image/${image.name.split('.').last}',
            customMetadata: {'picked-file-path': image.path}
          ),
        );
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return const Text('Nenhuma imagem selecionada');
    }

    if (kIsWeb) {
      // Web: Use Image.memory for preview
      return Image.memory(
        _webImage!,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      // Android: Use Image.file for preview
      return Image.file(
        File(_imageFile!.path),
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Produto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira a descrição';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o valor';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _qtdEstoqueController,
                decoration: const InputDecoration(labelText: 'Quantidade em Estoque'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira a quantidade em estoque';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildImagePreview(),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Selecionar Imagem'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? imageUrl;
                    if (_imageFile != null) {
                      imageUrl = await _uploadImage(_imageFile!);
                    }
                    
                    double preco = double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
                    int qtdEstoque = int.tryParse(_qtdEstoqueController.text) ?? 0;
                    
                    await _produtoService.addProduto(
                      _nomeController.text,
                      _descricaoController.text,
                      preco,
                      qtdEstoque,
                      imagemUrl: imageUrl,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Salvar Produto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
