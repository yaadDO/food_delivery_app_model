import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added import

class EditPromoItemPage extends StatefulWidget {
  final PromoItem item;

  const EditPromoItemPage({super.key, required this.item});

  @override
  State<EditPromoItemPage> createState() => _EditPromoItemPageState();
}

class _EditPromoItemPageState extends State<EditPromoItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  Uint8List? _imageBytes;
  String? _currentImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController =
        TextEditingController(text: widget.item.price.toString());
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _descriptionController =
        TextEditingController(text: widget.item.description);
    _discountController = TextEditingController(
        text: widget.item.discountPercentage?.toString() ?? '');
    _currentImagePath =
        widget.item.imagePath; // Use imagePath instead of imageUrl
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // Helper method to get download URL from Firebase Storage path
  Future<String> _getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        description: _descriptionController.text,
        discountPercentage: _discountController.text.isEmpty
            ? null
            : double.parse(_discountController.text),
      );

      context.read<PromoCubit>().updateItem(updatedItem, _imageBytes).then((_) {
        Navigator.pop(context, true);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Promo Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (_currentImagePath != null &&
                              _currentImagePath!.isNotEmpty
                          ? FutureBuilder<String>(
                              future: _getImageUrl(_currentImagePath!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return CachedNetworkImage(
                                    imageUrl: snapshot.data!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  );
                                }
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate, size: 50),
                                Text('Tap to add image'),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
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
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
