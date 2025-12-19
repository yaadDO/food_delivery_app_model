import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:image_picker/image_picker.dart';

class EditCatalogPage extends StatefulWidget {
  final Category? existingCategory;

  const EditCatalogPage({super.key, this.existingCategory});

  @override
  _EditCatalogPageState createState() => _EditCatalogPageState();
}

class _EditCatalogPageState extends State<EditCatalogPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Uint8List? _imageBytes;
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!.name;
      _existingImagePath = widget.existingCategory!.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCategory == null
            ? 'Add Category'
            : 'Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image preview
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : _existingImagePath != null
                      ? FutureBuilder(
                    future: _getImageUrl(_existingImagePath!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Image.network(snapshot.data!, fit: BoxFit.cover);
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  )
                      : const Icon(Icons.add_a_photo, size: 50),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              BlocConsumer<CatalogCubit, CatalogState>(
                listener: (context, state) {
                  if (state is CatalogDataLoaded) {
                    Navigator.pop(context);
                  } else if (state is CatalogError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is CatalogLoading
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) {
                        final category = Category(
                          id: widget.existingCategory?.id ?? '',
                          name: _nameController.text,
                          imagePath: _existingImagePath ?? '',
                        );

                        if (widget.existingCategory == null) {
                          context.read<CatalogCubit>().addCategory(category, _imageBytes);
                        } else {
                          context.read<CatalogCubit>().updateCategory(category, _imageBytes);
                        }
                      }
                    },
                    child: state is CatalogLoading
                        ? const CircularProgressIndicator()
                        : Text(widget.existingCategory == null
                        ? 'Add Category'
                        : 'Update Category'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return '';
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }
}