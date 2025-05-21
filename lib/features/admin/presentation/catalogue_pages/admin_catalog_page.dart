import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/admin_catelog_items_page.dart';
import 'package:food_delivery/features/admin/presentation/components/admin_category_card.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';

import 'edit_catalog_page.dart';


class AdminCatalogScreen extends StatelessWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      CatalogCubit(FirebaseCatalogRepo())..loadCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Catalog'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            if (state is CatalogLoading) {
              return const _LoadingGrid();
            }
            if (state is CatalogError) {
              return Center(child: Text(state.message));
            }
            if (state is CatalogDataLoaded) {
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
                          builder: (context) =>
                              AdminCategoryItemsPage(category: category),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditCatalogPage()),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Category', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4,
        ),
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