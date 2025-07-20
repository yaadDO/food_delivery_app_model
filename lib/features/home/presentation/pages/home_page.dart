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
          create: (context) => PromoCubit(FirebasePromoRepo())..loadItems(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = ProfileCubit(profileRepo: FirebaseProfileRepo());
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
              String userName = 'Beautiful'; // Default name

              if (state is ProfileLoaded) {
                userName = state.profileUser.name.isNotEmpty
                    ? state.profileUser.name
                    : 'Beautiful';
              } else if (state is ProfileError) {
                userName = 'Beautiful';
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
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
                    final category = state.categories[index];
                    return HomeCategoryCard(
                      category: category,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: BlocProvider.of<CatalogCubit>(context),
                            child: CategoryItemsPage(
                              category: category,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (state is CatalogError) {
                return Center(child: Text(state.message));
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 240,
          child: BlocBuilder<PromoCubit, PromoState>(
            builder: (context, state) {
              if (state is PromoLoaded) {
                if (state.items.isEmpty) {
                  return const Center(child: Text("No offers available"));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 20),
                      child: PromoItemCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PromoItemDetailPage(item: item),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
              fontSize: 22,
            ),
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
