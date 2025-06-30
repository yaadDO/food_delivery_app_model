import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import '../../domain/entities/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _processingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().currentUser;
      if (user != null) {
        context.read<CartCubit>().loadCart(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                if (state is CartLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CartError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                }
                if (state is CartLoaded) {
                  if (state.items.isEmpty) {
                    return _buildEmptyCart();
                  }
                  return _buildCartItems(state.items);
                }
                return _buildEmptyCart();
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Add delicious items to get started', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<CartItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.network(
              item.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: Icon(Icons.fastfood, size: 40, color: Colors.grey[400]),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () => _updateQuantity(item, -1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item.quantity.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => _updateQuantity(item, 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                        onPressed: () => _removeItem(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final total = state is CartLoaded ? _calculateTotal(state.items) : 0.0;
        final itemCount = state is CartLoaded ? state.items.length : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Total:', style: TextStyle(fontSize: 16, color: Colors.black), ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: itemCount > 0 ? () => _handleCheckout(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateQuantity(CartItem item, int change) {
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      final newQuantity = item.quantity + change;
      if (newQuantity > 0) {
        // CHANGE: Call updateItemQuantity instead of updateQuantity
        context.read<CartCubit>().updateItemQuantity(user.uid, item.itemId, newQuantity);
      } else {
        _removeItem(item);
      }
    }
  }

  void _removeItem(CartItem item) {
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      context.read<CartCubit>().removeFromCart(user.uid, item.itemId);
    }
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to checkout')),
      );
      return;
    }

    final state = context.read<CartCubit>().state;
    if (state is! CartLoaded || state.items.isEmpty) {
      return;
    }

    final profile = await context.read<ProfileCubit>().getUserProfile(user.uid);
    final address = profile?.address ?? 'No address set';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Order',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: _buildCheckoutContent(context, state.items, address),
          actions: _buildDialogActions(context, setState, user.uid),
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(
      BuildContext context,
      List<CartItem> items,
      String address,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.payment_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cash on Delivery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pay when your order arrives',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: TextStyle(color: Colors.grey)),
                  Text('Items', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${_calculateTotal(items).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${items.length} item${items.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '\$${_calculateTotal(items).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDialogActions(
      BuildContext context,
      StateSetter setState,
      String userId,
      ) {
    return [
      TextButton(
        onPressed: _processingOrder ? null : () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
      ),
      ElevatedButton(
        onPressed: _processingOrder
            ? null
            : () => _confirmOrder(context, setState, userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: _processingOrder
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Order', style: TextStyle(color: Colors.white)),
        ),
      ),
    ];
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _confirmOrder(
      BuildContext context,
      StateSetter setState,
      String userId,
      ) async {
    setState(() => _processingOrder = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order confirmed! Your food is on the way'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      context.read<CartCubit>().clearCart(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _processingOrder = false);
    }
  }
}