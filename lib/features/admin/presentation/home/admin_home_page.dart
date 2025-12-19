import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/admin_catelog_items_page.dart';
import 'package:food_delivery/features/cart/presentation/pages/cart_admin.dart';
import 'package:food_delivery/features/chat/presentation/pages/admin_chat_list.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import '../catalogue_pages/admin_catalog_page.dart';
import '../promo_pages/admin_promo_item_page.dart';
import '../settings/admin_settings_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    CartAdmin(),
    const AdminChatList(),
    _CatalogPageWithRefresh(),
    const AdminPromoItemPage(),
    const AdminSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
class _CatalogPageWithRefresh extends StatefulWidget {
  @override
  State<_CatalogPageWithRefresh> createState() => _CatalogPageWithRefreshState();
}

class _CatalogPageWithRefreshState extends State<_CatalogPageWithRefresh> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  Future<void> _loadCatalog() async {
    if (_hasLoaded) return;

    final catalogCubit = BlocProvider.of<CatalogCubit>(context);
    await catalogCubit.loadCategories();
    setState(() {
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCatalog();
      });
    }

    return BlocProvider.value(
      value: BlocProvider.of<CatalogCubit>(context),
      child: const AdminCatalogScreen(),
    );
  }
}