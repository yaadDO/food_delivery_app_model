import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/add_item_page.dart';
import 'package:food_delivery/features/admin/presentation/components/admin_item_card.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/catalogue/presentation/pages/item_page_detail.dart';

class AdminCategoryItemsPage extends StatefulWidget {
  final String categoryId;

  const AdminCategoryItemsPage({super.key, required this.categoryId});

  @override
  State<AdminCategoryItemsPage> createState() => _AdminCategoryItemsPageState();
}

class _AdminCategoryItemsPageState extends State<AdminCategoryItemsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            if (state is CatalogDataLoaded) {
              final category = state.categories.firstWhere(
                    (c) => c.id == widget.categoryId,
                orElse: () => Category(id: '', name: '', imagePath: ''),
              );
              return Text(category.name);
            }
            return const Text('Category Items');
          },
        ),
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          if (state is CatalogLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CatalogError) {
            return Center(child: Text(state.message));
          }
          if (state is CatalogDataLoaded) {
            final category = state.categories.firstWhere(
                  (c) => c.id == widget.categoryId,
              orElse: () => Category(id: '', name: '', imagePath: ''),
            );

            if (category.items.isEmpty) {
              return const Center(child: Text('No items available'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: category.items.length,
              itemBuilder: (context, index) {
                final item = category.items[index];
                return AdminItemCard(
                  item: item,
                  onTap: () => _navigateToItemDetail(context, item),
                );
              },
            );
          }
          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddItem(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToAddItem(BuildContext context) {
    final state = BlocProvider.of<CatalogCubit>(context).state;

    if (state is CatalogDataLoaded) {
      final category = state.categories.firstWhere(
            (c) => c.id == widget.categoryId,
        orElse: () => Category(id: '', name: '', imagePath: ''),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemPage(category: category),
        ),
      );
    } else {
      // Handle error state - show message or reload data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category data not loaded')),
      );
      // Optionally reload categories
      BlocProvider.of<CatalogCubit>(context).loadCategories();
    }
  }

  void _navigateToItemDetail(BuildContext context, CatalogItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(item: item),
      ),
    );
  }
}