import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/presentation/components/item_card.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/catalogue/presentation/pages/item_page_detail.dart';

class CategoryItemsPage extends StatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
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
          if (state is CatalogDataLoaded) { // Changed from CatalogLoaded
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
                return ItemCard(
                  item: item,
                  onTap: () => _navigateToItemDetail(context, item),
                );
              },
            );
          }
          return Container();
        },
      ),
    );
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
