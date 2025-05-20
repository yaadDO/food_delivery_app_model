import 'package:flutter/material.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/admin_catelog_items_page.dart';
import 'package:food_delivery/features/admin/presentation/catalogue_pages/editCatalogpage.dart';
import 'package:food_delivery/features/admin/presentation/promo_pages/add_promoitem_page.dart';
import 'package:food_delivery/features/cart/presentation/pages/cart_admin.dart';
import 'package:food_delivery/features/chat/presentation/pages/admin_chat_list.dart';
import '../catalogue_pages/AdminCatalogPage.dart';
import '../promo_pages/admin_promo_item_page.dart';


class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CartAdmin(),
    const AdminChatList(),
    const AdminCatalogScreen(),
    const AdminPromoItemPage(),
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