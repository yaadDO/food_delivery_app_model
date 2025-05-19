import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/admin_catelog_items_page.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/editCatalogpage.dart';
import 'package:food_delivery/features/admin/presentation/components/admin_category_card.dart';
import 'package:food_delivery/features/admin/presentation/promo_pages/add_promoitem_page.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../chat/presentation/pages/admin_chat_list.dart';


class AdminCatalogPage extends StatelessWidget {
  const AdminCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CatalogCubit(FirebaseCatalogRepo())..loadCategories(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCatalogPage(),
                ),
              );
            }
          ),
          IconButton(
              icon: const Icon(Icons.monetization_on_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPromoItemPage(),
                  ),
                );
              }
          ),
          IconButton(
              icon: const Icon(Icons.mail),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminChatList(),
                  ),
                );
              }
          ),
          ],
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
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return AdminCategoryCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminCategoryItemsPage(category: category),
                        ),
                      );
                    },
                  );
                },
              );
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: () => context.read<AuthCubit>().logout()),
      ),
    );
  }
}