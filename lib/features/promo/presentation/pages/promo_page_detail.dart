import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add this import
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoItemDetailPage extends StatelessWidget {
  final PromoItem item;

  const PromoItemDetailPage({super.key, required this.item});

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
              child: Stack(
                children: [
                  FutureBuilder<String>(
                    future: _getImageUrl(item.imagePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          return CachedNetworkImage(
                            imageUrl: snapshot.data!,
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.5,
                            fit: BoxFit.cover,
                          );
                        }
                      }
                      return Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.5,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Material(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          'On Sale!',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                ],
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
                            fontSize: 24, fontWeight: FontWeight.bold),
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
                    'Only ${item.quantity} left in stock!',
                    style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.description,
                    style: GoogleFonts.poppins(
                        fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: Text('Add to Cart',
                          style: GoogleFonts.poppins(fontSize: 16)),
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
                          imagePath: item.imagePath,
                          quantity: 1,
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

  // Helper method to get image URL from storage path
  Future<String> _getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }
}