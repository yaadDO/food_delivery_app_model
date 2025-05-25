import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
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
  List<CartItem> _currentCartItems = [];
  String? _selectedPaymentMethod;
  bool _cardDetailsComplete = false;
  bool _processingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthCubit>().currentUser!.uid;
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
                          final userId = context.read<AuthCubit>().currentUser!.uid;
                          context.read<CartCubit>().removeFromCart(userId, item.itemId);
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
              final userId = context.read<AuthCubit>().currentUser!.uid;
              final profile = await context.read<ProfileCubit>().getUserProfile(userId);
              final address = profile?.address ?? 'No address set';

              if (_currentCartItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your cart is empty')),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('Confirm Purchase'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shipping to: $address',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Text('Total: \$${_calculateTotal(_currentCartItems).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text('Payment Method:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                        // Credit/Debit Card Payment Option
                        _buildPaymentMethodTile(
                          title: 'Credit/Debit Card',
                          leading: Image.asset('assets/img/visa_icon.png', width: 40),
                          onChanged: (val) => setState(() {
                            _selectedPaymentMethod = val;
                            _cardDetailsComplete = false;
                          }),
                        ),
                        if (_selectedPaymentMethod == 'Credit/Debit Card')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Text('Card Details',
                                  style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: flutter_stripe.CardField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                  onCardChanged: (card) {
                                    setState(() {
                                      _cardDetailsComplete = card?.complete ?? false;
                                    });
                                  },
                                ),
                              ),
                              if (!_cardDetailsComplete && _selectedPaymentMethod == 'Credit/Debit Card')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Please fill all card details',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        // Other payment methods
                        _buildPaymentMethodTile(
                          title: 'PayPal',
                          leading: Image.asset('assets/img/paypal.png', width: 40),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                        ),
                        _buildPaymentMethodTile(
                          title: 'Cash on Delivery',
                          leading: Icon(Icons.money, size: 30, color: Colors.green[700]),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: (_selectedPaymentMethod == null ||
                            (_selectedPaymentMethod == 'Credit/Debit Card' && !_cardDetailsComplete) ||
                            _processingPayment)
                            ? null
                            : () async {
                          setState(() => _processingPayment = true);
                          try {
                            String? paymentIntentId;
                            if (_selectedPaymentMethod == 'Credit/Debit Card') {
                              final paymentIntent = await _handleStripePayment(
                                context,
                                _calculateTotal(_currentCartItems),
                              );
                              paymentIntentId = paymentIntent.id;
                            }

                            await context.read<CartCubit>().confirmPurchase(
                              userId,
                              address,
                              _selectedPaymentMethod!,
                              paymentIntentId: paymentIntentId,
                            );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment successful!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment failed: ${e.toString()}')),
                            );
                          } finally {
                            setState(() => _processingPayment = false);
                          }
                        },
                        child: _processingPayment
                            ? const CircularProgressIndicator()
                            : const Text('Confirm'),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == title
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: leading,
        title: Text(title,
            style: TextStyle(
              fontWeight: _selectedPaymentMethod == title
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: _selectedPaymentMethod == title
                  ? Theme.of(context).primaryColor
                  : Colors.black,
            )),
        trailing: Radio<String>(
          value: title,
          groupValue: _selectedPaymentMethod,
          activeColor: Theme.of(context).primaryColor,
          onChanged: onChanged,
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<flutter_stripe.PaymentIntent> _handleStripePayment(
      BuildContext context,
      double amount,
      ) async {
    try {
      // 1. Create payment method from card details
      final paymentMethod = await flutter_stripe.Stripe.instance.createPaymentMethod(
        params: const flutter_stripe.PaymentMethodParams.card(
          paymentMethodData: flutter_stripe.PaymentMethodData(),
        ),
      );

      // 2. Create payment intent using Cloud Function
      final response = await FirebaseFunctions.instance
          .httpsCallable('createPaymentIntent')
          .call({
        'amount': (amount * 100).toInt(),
        'currency': 'USD',
        'paymentMethodId': paymentMethod.id,
      });

      final clientSecret = response.data['clientSecret'];

      // 3. Confirm payment with the client secret
      final paymentIntent = await flutter_stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: flutter_stripe.PaymentMethodParams.card(
          paymentMethodData: flutter_stripe.PaymentMethodData(),
        ),
      );

      return paymentIntent;
    } catch (e) {
      throw Exception('Payment failed: ${e.toString()}');
    }
  }
}