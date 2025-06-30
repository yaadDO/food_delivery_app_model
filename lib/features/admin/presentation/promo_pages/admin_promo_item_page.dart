import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';

import '../components/admin_promo_item_card.dart';
import 'add_promo_item_page.dart';
import 'edit_promo_item_page.dart' show EditPromoItemPage;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';

import '../components/admin_promo_item_card.dart';
import 'add_promo_item_page.dart';
import 'edit_promo_item_page.dart';

class AdminPromoItemPage extends StatefulWidget {
  const AdminPromoItemPage({super.key});

  @override
  State<AdminPromoItemPage> createState() => _AdminPromoItemPageState();
}

class _AdminPromoItemPageState extends State<AdminPromoItemPage> {
  @override
  void initState() {
    super.initState();
    context.read<PromoCubit>().loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Promo Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PromoCubit>().loadItems(),
          ),
        ],
      ),
      body: BlocConsumer<PromoCubit, PromoState>(
        listener: (context, state) {
          if (state is PromoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PromoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PromoError) {
            return Center(child: Text(state.message));
          }
          if (state is PromoLoaded) {
            if (state.items.isEmpty) {
              return const Center(child: Text('No promo items available'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return AdminPromoItemCard(
                  item: item,
                  onDelete: () => _confirmDeleteItem(context, item),
                  onEdit: () => _navigateToEditPromoItem(context, item),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPromoItem(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToAddPromoItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPromoItemPage()),
    ).then((_) {
      // Refresh after adding new item
      context.read<PromoCubit>().loadItems();
    });
  }

  void _navigateToEditPromoItem(BuildContext context, PromoItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPromoItemPage(item: item),
      ),
    ).then((_) {
      // Refresh after editing item
      context.read<PromoCubit>().loadItems();
    });
  }

  void _confirmDeleteItem(BuildContext context, PromoItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promo Item'),
        content: Text('Delete "${item.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PromoCubit>().deleteItem(item.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}