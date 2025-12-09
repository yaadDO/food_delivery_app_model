import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/admin_catelog_items_page.dart';
import 'package:food_delivery/features/admin/presentation/components/admin_category_card.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';

import 'edit_catalog_page.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  @override
  void initState() {
    super.initState();
    // Force load catalog when this screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogCubit = BlocProvider.of<CatalogCubit>(context);
      catalogCubit.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Catalog'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              BlocProvider.of<CatalogCubit>(context).loadCategories();
            },
          ),
        ],
      ),
      body: BlocConsumer<CatalogCubit, CatalogState>(
        listener: (context, state) {
          if (state is CatalogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          // Show loading when we're in CatalogLoading state
          if (state is CatalogLoading) {
            return const _LoadingGrid();
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
            if (state.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      'No categories found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap the + button to add your first category',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return AdminCategoryCard(
                    category: category,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminCategoryItemsPage(categoryId: category.id),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Initial state - show loading
          return const _LoadingGrid();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditCatalogPage()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const Card(
        child: SizedBox.expand(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}