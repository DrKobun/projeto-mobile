import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:projeto_mobile/servicos/produto_service.dart';

class EditProdutoScreen extends StatefulWidget {
  final String produtoId;

  const EditProdutoScreen({Key? key, required this.produtoId}) : super(key: key);

  @override
  State<EditProdutoScreen> createState() => _EditProdutoScreenState();
}

class _EditProdutoScreenState extends State<EditProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService();
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _qtdEstoqueController = TextEditingController();
  
  File? _imagem;
  Uint8List? _webImagem;
  String? _imagemUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProduto();
  }

  Future<void> _carregarProduto() async {
    try {
      final produto = await _produtoService.getProdutoById(widget.produtoId);
      if (produto != null) {
        setState(() {
          _nomeController.text = produto['nome'] ?? '';
          _descricaoController.text = produto['descricao'] ?? '';
          _precoController.text = produto['preco']?.toString() ?? '';
          _qtdEstoqueController.text = produto['qtdEstoque']?.toString() ?? '';
          _imagemUrl = produto['imagemUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar produto')),
      );
    }
  }

  Future<void> _selecionarImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    
    if (imagem != null) {
      if (kIsWeb) {
        // Handle web image
        final bytes = await imagem.readAsBytes();
        setState(() {
          _webImagem = bytes;
          _imagem = null;
        });
      } else {
        // Handle mobile image
        setState(() {
          _imagem = File(imagem.path);
          _webImagem = null;
        });
      }
    }
  }

  Widget _buildImageWidget() {
    if (_imagem != null) {
      return Image.file(_imagem!, fit: BoxFit.cover);
    } else if (_webImagem != null) {
      return Image.memory(_webImagem!, fit: BoxFit.cover);
    } else if (_imagemUrl != null && _imagemUrl!.isNotEmpty) {
      return Image.network(_imagemUrl!, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.add_photo_alternate, size: 50);
    }
  }

  Future<void> _salvarProduto() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Pass either File or Uint8List depending on platform
        await _produtoService.updateProduto(
          widget.produtoId,
          {
            'nome': _nomeController.text,
            'descricao': _descricaoController.text,
            'preco': double.parse(_precoController.text),
            'qtdEstoque': int.parse(_qtdEstoqueController.text),
          },
          _imagem,
          _webImagem,
          _imagemUrl,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar produto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Produto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _selecionarImagem,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildImageWidget(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a descrição do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o preço do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtdEstoqueController,
                decoration: const InputDecoration(labelText: 'Quantidade em Estoque'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a quantidade em estoque';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarProduto,
                child: const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _qtdEstoqueController.dispose();
    super.dispose();
  }
}