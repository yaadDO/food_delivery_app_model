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
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Force load items when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryItems();
    });
  }

  Future<void> _loadCategoryItems() async {
    if (!_isInitialLoad) return;

    setState(() {
      _isInitialLoad = false;
    });

    // Force the cubit to load fresh data
    await BlocProvider.of<CatalogCubit>(context).loadCategories();
  }

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
            return const Text('Loading...');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              BlocProvider.of<CatalogCubit>(context).loadCategories();
            },
          ),
        ],
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          // Show loading initially
          if (_isInitialLoad) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CatalogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CatalogError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      BlocProvider.of<CatalogCubit>(context).loadCategories();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CatalogDataLoaded) {
            // Get items from allItems that belong to this category
            final categoryItems = state.allItems.where(
                  (item) => item.categoryId == widget.categoryId,
            ).toList();

            if (categoryItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No items available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the + button to add your first item',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: categoryItems.length,
              itemBuilder: (context, index) {
                final item = categoryItems[index];
                return AdminItemCard(
                  item: item,
                  onTap: () => _navigateToItemDetail(context, item),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category data not loaded')),
      );
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