import 'package:flutter/material.dart';
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
  final _produtoService = ProdutoService();

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
               ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _produtoService.addProduto(
                      _nomeController.text,
                      _descricaoController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context); // Return to list screen after saving
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