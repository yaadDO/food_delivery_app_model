import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/add_item_page.dart';
import 'package:food_delivery/features/admin/presentation/components/admin_item_card.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/catalogue/presentation/pages/item_page_detail.dart';

class AdminCategoryItemsPage extends StatefulWidget {
  final Category category;

  const AdminCategoryItemsPage({super.key, required this.category});

  @override
  State<AdminCategoryItemsPage> createState() => _AdminCategoryItemsPageState();
}

class _AdminCategoryItemsPageState extends State<AdminCategoryItemsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogCubit>().loadItemsForCategory(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),

      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          if (state is CatalogLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CatalogError) {
            return Center(child: Text(state.message));
          }
          if (state is CatalogLoaded) {
            final category = state.categories.firstWhere(
                  (c) => c.id == widget.category.id,
              orElse: () => Category(id: '', name: '', imageUrl: ''),
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
      ),
    );
  }

  void _navigateToAddItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(category: widget.category),
      ),
    );
  }

  void _navigateToEditCategory(BuildContext context) {
    // Implement category editing navigation
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

