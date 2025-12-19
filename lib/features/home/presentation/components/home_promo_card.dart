import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../promo/domain/entities/promo_item.dart';

class HomePromoItemCard extends StatelessWidget {
  final PromoItem item;
  final VoidCallback onTap;

  const HomePromoItemCard({super.key, required this.item, required this.onTap});

  Future<String> _getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discountPercentage != null;
    final discountedPrice = hasDiscount
        ? item.price * (1 - item.discountPercentage! / 100)
        : item.price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Hero(
                      tag: item.id,
                      child: FutureBuilder<String>(
                        future: _getImageUrl(item.imagePath),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData) {
                            return CachedNetworkImage(
                              imageUrl: snapshot.data!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.fastfood,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                              ),
                            );
                          }
                          return Container(
                            color: Theme.of(context).colorScheme.secondary,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '\$${discountedPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Theme.of(context).colorScheme.inversePrimary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  hasDiscount
                      ? '${item.discountPercentage!.toStringAsFixed(0)}% OFF'
                      : 'SALE',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}