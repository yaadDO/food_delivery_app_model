import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import '../../../catalogue/presentation/cubits/catalog_cubit.dart';

class EditCatalogPage extends StatefulWidget {
  const EditCatalogPage({super.key});

  @override
  _EditCatalogPageState createState() => _EditCatalogPageState();
}

class _EditCatalogPageState extends State<EditCatalogPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final category = Category(
                      id: '', // Firebase will generate ID
                      name: _nameController.text,
                      imageUrl: _imageController.text,
                    );
                    context.read<CatalogCubit>().addCategory(category);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}