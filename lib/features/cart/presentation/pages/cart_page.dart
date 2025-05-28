import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as flutter_stripe;
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
  String? _selectedPaymentMethod;
  bool _cardDetailsComplete = false;
  bool _processingPayment = false;
  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

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
      appBar: AppBar(title: const Text('Your Cart')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) return const Center(child: CircularProgressIndicator());
          if (state is CartError) return Center(child: Text(state.message));
          if (state is CartLoaded) {
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50, errorBuilder: (_, __, ___) =>
                  const Icon(Icons.fastfood, size: 50)),
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Qty: ${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final user = context.read<AuthCubit>().currentUser;
                          if (user != null) {
                            context.read<CartCubit>().removeFromCart(user.uid, item.itemId);
                          }
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
            onPressed: () async => _handleCheckout(context),
            label: const Text('Checkout'),
            icon: const Icon(Icons.shopping_cart_checkout),
          );
        },
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    final profile = await context.read<ProfileCubit>().getUserProfile(user.uid);
    final address = profile?.address ?? 'No address set';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Purchase'),
          content: _buildCheckoutContent(context, setState, state.items, address),
          actions: _buildDialogActions(context, setState, user.uid, address),
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(
      BuildContext context,
      StateSetter setState,
      List<CartItem> items,
      String address,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping to: $address', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Text('Total: \$${_calculateTotal(items).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Column(
          children: [
            _buildPaymentMethodTile(
              context: context,
              title: 'Credit/Debit Card',
              icon: Icons.credit_card,
              isSelected: _selectedPaymentMethod == 'Credit/Debit Card',
              onTap: () => setState(() {
                _selectedPaymentMethod = 'Credit/Debit Card';
                _cardDetailsComplete = false;
              }),
            ),
            if (_selectedPaymentMethod == 'Credit/Debit Card')
              _buildCardDetailsSection(context, setState),
            _buildPaymentMethodTile(
              context: context,
              title: 'Cash on Delivery',
              icon: Icons.money,
              isSelected: _selectedPaymentMethod == 'Cash on Delivery',
              onTap: () => setState(() => _selectedPaymentMethod = 'Cash on Delivery'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Theme.of(context).primaryColor : Colors.black,
          ),
        ),
        trailing: Radio<String>(
          value: title,
          groupValue: _selectedPaymentMethod,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (value) => onTap(),
        ),
        onTap: onTap,
      ),
    );
  }

  List<Widget> _buildDialogActions(
      BuildContext context,
      StateSetter setState,
      String userId,
      String address,
      ) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: (_selectedPaymentMethod == null ||
            (_selectedPaymentMethod == 'Credit/Debit Card' && !_cardDetailsComplete) ||
            _processingPayment)
            ? null
            : () => _processPayment(context, setState, userId, address),
        child: _processingPayment
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Confirm'),
      ),
    ];
  }

  Widget _buildCardDetailsSection(BuildContext context, StateSetter setState) {
    return Form(
      key: _cardFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '4242 4242 4242 4242',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (!RegExp(r'^\d{16}$').hasMatch(value.replaceAll(' ', ''))) {
                return 'Invalid card number';
              }
              return null;
            },
            onChanged: (value) => setState(() => _updateCardValidation()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    hintText: '12/25',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                      return 'Invalid expiry';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => _updateCardValidation()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) return 'Invalid CVC';
                    return null;
                  },
                  onChanged: (value) => setState(() => _updateCardValidation()),
                ),
              ),
            ],
          ),
          if (!_cardDetailsComplete)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please fill all card details',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _updateCardValidation() {
    final isValid = _cardFormKey.currentState?.validate() ?? false;
    setState(() => _cardDetailsComplete = isValid);
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _processPayment(
      BuildContext context,
      StateSetter setState,
      String userId,
      String address,
      ) async {
    setState(() => _processingPayment = true);

    try {
      final cartState = context.read<CartCubit>().state;
      if (cartState is! CartLoaded) throw Exception('Cart not loaded');

      final total = _calculateTotal(cartState.items);

      // Validate total amount
      if (total <= 0) throw Exception('Invalid payment amount');

      final callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final response = await callable.call(<String, dynamic>{
        'amount': (total * 100).toInt(),
        'currency': 'usd',
      }).timeout(const Duration(seconds: 30));

      final clientSecret = response.data['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Invalid payment configuration');
      }

      await flutter_stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: flutter_stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Food Delivery',
        ),
      );

      // Present the payment sheet
      await flutter_stripe.Stripe.instance.presentPaymentSheet();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );

      context.read<CartCubit>().clearCart(userId);
    } on flutter_stripe.StripeException catch (e) {
      final message = switch (e.error.code) {
        flutter_stripe.FailureCode.Failed => 'Payment failed: ${e.error.message}',
        flutter_stripe.FailureCode.Canceled => 'Payment canceled by user',
        flutter_stripe.FailureCode.Timeout => 'Payment timed out',
        _ => 'Payment error: ${e.error.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment setup failed: ${e.message}')),
      );
    } on SocketException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment timed out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _processingPayment = false);
    }
  }

  void _handlePaymentError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
    );
  }
}
