import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/catalogue/presentation/pages/category_items_page.dart';
import 'package:food_delivery/features/home/presentation/components/home_catagory_card.dart';
import 'package:food_delivery/features/promo/data/firebase_promo_repo.dart';
import 'package:food_delivery/features/promo/presentation/components/promo_item_card.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';
import 'package:food_delivery/features/promo/presentation/pages/promo_page_detail.dart';
import 'package:food_delivery/features/search/presentation/pages/search_page.dart';
import '../../../catalogue/presentation/components/item_card.dart';
import '../../../catalogue/presentation/pages/item_page_detail.dart';
import '../../../profile/data/firebase_profile_repo.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../profile/presentation/cubits/profile_states.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CatalogCubit(FirebaseCatalogRepo())..loadCategories(),
        ),
        BlocProvider(
          create: (context) => PromoCubit(FirebasePromoRepo())..loadItems(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = ProfileCubit(profileRepo: FirebaseProfileRepo());
            // Fetch profile if user is logged in
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              cubit.fetchUserProfile(user.uid);
            }
            return cubit;
          },
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppHeader(context),
              _buildCategoriesSection(context),
              _buildSalesSection(context),
              _buildMenuSection(context),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget _buildAppHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final greeting = _getGreeting();
              String userName = 'there'; // Default name

              if (state is ProfileLoaded) {
                userName = state.profileUser.name.isNotEmpty
                    ? state.profileUser.name
                    : 'there';
              } else if (state is ProfileError) {
                userName = 'there';
              }

              return Text(
                "$greeting, $userName",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Categories",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, state) {
              if (state is CatalogDataLoaded) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    return HomeCategoryCard(
                      category: state.categories[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryItemsPage(
                              category: state.categories[index]),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Special Offers",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200, // Increased height to accommodate card content
          child: BlocBuilder<PromoCubit, PromoState>(
            builder: (context, state) {
              if (state is PromoLoaded) {
                if (state.items.isEmpty) {
                  return const Center(child: Text("No offers available"));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return SizedBox( // Add fixed width constraint
                      width: 300, // Adjust based on your design needs
                      child: PromoItemCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PromoItemDetailPage(item: item),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (state is PromoError) {
                return Center(child: Text("Error: ${state.message}"));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Menu",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, state) {
              if (state is CatalogDataLoaded) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: state.allItems.length,
                  itemBuilder: (context, index) {
                    final item = state.allItems[index];
                    return ItemCard(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailPage(item: item),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }
}