import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/catalog_item.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ItemDetailPage extends StatelessWidget {
  final CatalogItem item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: item.id,
              child: Container(
                color: Colors.grey[200],
                height: MediaQuery.of(context).size.height * 0.5,
                child: FutureBuilder<String>(
                  future: _getImageUrl(item.imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return CachedNetworkImage(
                          imageUrl: snapshot.data!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        );
                      }
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quantity Available: ${item.quantity}',
                    style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.description,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        height: 1.5
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: Text(
                          'Add to Cart',
                          style: GoogleFonts.poppins(fontSize: 16)
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final userId = context.read<AuthCubit>().currentUser?.uid;
                        if (userId == null) return;

                        final cartItem = CartItem(
                          itemId: item.id,
                          name: item.name,
                          price: item.price,
                          quantity: 1, // Add this required parameter
                          imagePath: item.imagePath,
                        );
                        context.read<CartCubit>().addToCart(userId, cartItem);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${item.name} to cart')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }
}