import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/components/category_card.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/catalogue/presentation/pages/category_items_page.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CatalogCubit(FirebaseCatalogRepo())..loadCategories(),
      child: Scaffold(
        body: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            if (state is CatalogLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CatalogDataLoaded) { // Changed from CatalogLoaded
              return AnimationLimiter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final category = state.categories[index]; // Now uses CatalogDataLoaded
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 8.0,
                                      ),
                                      child: CategoryCard(
                                        category: category,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CategoryItemsPage(category: category),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: state.categories.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}