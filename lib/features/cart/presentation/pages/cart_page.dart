import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paypal_native/flutter_paypal_native.dart';
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
  List<CartItem> _currentCartItems = [];
  String? _selectedPaymentMethod;
  final _paypalNative = FlutterPaypalNative.instance;
  bool _paypalInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context
          .read<AuthCubit>()
          .currentUser!
          .uid;
      context.read<CartCubit>().loadCart(userId);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CartError) {
            return Center(child: Text(state.message));
          } else if (state is CartLoaded) {
            _currentCartItems = state.items;
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Qty: ${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final userId = context
                              .read<AuthCubit>()
                              .currentUser!
                              .uid;
                          context.read<CartCubit>().removeFromCart(
                              userId, item.itemId);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Your cart is empty'));
        },
      ),
      floatingActionButton: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final userId = context
                  .read<AuthCubit>()
                  .currentUser!
                  .uid;
              final profile = await context.read<ProfileCubit>().getUserProfile(
                  userId);
              final address = profile?.address ?? 'No address set';

              if (_currentCartItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your cart is empty')),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) =>
                    StatefulBuilder(
                      builder: (context, setState) =>
                          AlertDialog(
                            title: const Text('Confirm Purchase'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Shipping to: $address'),
                                Text('Total: \$${_calculateTotal(
                                    _currentCartItems).toStringAsFixed(2)}'),
                                const SizedBox(height: 16),
                                const Text('Payment Method:', style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                                _buildPaymentMethodTile(
                                  title: 'Visa',
                                  leading: Image.asset(
                                      'assets/img/visa_icon.png', width: 40),
                                  onChanged: (val) =>
                                      setState(() =>
                                      _selectedPaymentMethod = val),
                                ),
                                _buildPaymentMethodTile(
                                  title: 'PayPal',
                                  leading: Image.asset(
                                      'assets/img/paypal.png', width: 40),
                                  onChanged: (val) =>
                                      setState(() =>
                                      _selectedPaymentMethod = val),
                                ),
                                _buildPaymentMethodTile(
                                  title: 'Cash on Delivery',
                                  leading: const Icon(
                                      Icons.attach_money, size: 40,
                                      color: Colors.green),
                                  onChanged: (val) =>
                                      setState(() =>
                                      _selectedPaymentMethod = val),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: _selectedPaymentMethod == null
                                    ? null
                                    : () {
                                  context.read<CartCubit>().confirmPurchase(
                                      userId, address, _selectedPaymentMethod!);
                                  Navigator.pop(context);
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                    ),
              );
            },
            label: const Text('Checkout'),
            icon: const Icon(Icons.shopping_cart_checkout),
          );
        },
      ),
    );
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required Widget leading,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: leading,
      title: Text(title),
      trailing: Radio<String>(
        value: title,
        groupValue: _selectedPaymentMethod,
        onChanged: onChanged,
      ),
    );
  }
}