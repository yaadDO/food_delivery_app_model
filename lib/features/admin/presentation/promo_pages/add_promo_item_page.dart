import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';

class AddPromoItemPage extends StatefulWidget {
  const AddPromoItemPage({super.key});

  @override
  State<AddPromoItemPage> createState() => _AddPromoItemPageState();
}

class _AddPromoItemPageState extends State<AddPromoItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _discountController = TextEditingController(); // New controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Promo Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              // New discount percentage field
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage (%)',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isNotEmpty) {
                    final num = double.tryParse(value);
                    if (num == null) return 'Enter valid number';
                    if (num < 0 || num > 100) return 'Enter 0-100';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newItem = PromoItem(
        id: '',
        name: _nameController.text,
        imageUrl: _imageController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        description: _descriptionController.text,
        discountPercentage: _discountController.text.isEmpty
            ? null
            : double.parse(_discountController.text),
      );

      context.read<PromoCubit>().addItem(newItem).then((_) {
        Navigator.pop(context, true);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      });
    }
  }
}