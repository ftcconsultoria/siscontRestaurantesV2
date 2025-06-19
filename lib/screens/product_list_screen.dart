import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final produtos = [
      {'nome': 'Produto A', 'preco': 25.0},
      {'nome': 'Produto B', 'preco': 40.5},
      {'nome': 'Produto C', 'preco': 18.75},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Produtos')),
      body: ListView.builder(
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          return ListTile(
            title: Text(produto['nome'].toString()),
            subtitle: Text('Preço: R\$ ${produto['preco']}'),
            leading: const Icon(Icons.shopping_cart),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          );
        },
      ),
    );
  }
}