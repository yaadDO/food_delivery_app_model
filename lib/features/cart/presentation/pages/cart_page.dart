import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import '../../../payments/payment_dialog.dart';
import '../../../payments/payment_settings.dart';
import '../../../settings/data/firebase_settings_repo.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/models/order_summary.dart';
import '../components/cart_item_card.dart';
import '../components/checkout_dialog.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  PaymentSettings? _paymentSettings;
  bool _loadingPaymentSettings = false;
  String _selectedPaymentMethod = '';
  String _deliveryOption = 'delivery';
  final FirebaseSettingsRepo _settingsRepo = FirebaseSettingsRepo();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().currentUser;
      if (user != null) {
        context.read<CartCubit>().loadCart(user.uid);
      }
      _loadPaymentSettings();
    });
  }

  Future<void> _loadPaymentSettings() async {
    setState(() {
      _loadingPaymentSettings = true;
    });
    try {
      _paymentSettings = await _settingsRepo.getPaymentSettings();
      if (_paymentSettings != null) {
        if (_paymentSettings!.allowCashOnDelivery) {
          _selectedPaymentMethod = 'Cash on Delivery';
        } else if (_paymentSettings!.allowPaystack) {
          _selectedPaymentMethod = 'Paystack';
        }
      }
    } catch (e) {
      _paymentSettings = PaymentSettings(
        allowCashOnDelivery: true,
        allowPaystack: true,
        deliveryFeeEnabled: false,
        deliveryFeeAmount: 5.0,
        allowPickup: true,
        lastUpdated: DateTime.now(),
      );
      _selectedPaymentMethod = 'Cash on Delivery';
    } finally {
      setState(() {
        _loadingPaymentSettings = false;
      });
    }
  }

  bool _isPaymentMethodAllowed(String method) {
    if (_paymentSettings == null) return true;

    if (method == 'Cash on Delivery') {
      return _paymentSettings!.allowCashOnDelivery;
    } else if (method == 'Paystack') {
      return _paymentSettings!.allowPaystack;
    }
    return false;
  }

  bool _paymentMethodsAvailable() {
    if (_paymentSettings == null) return true;
    return _paymentSettings!.allowCashOnDelivery || _paymentSettings!.allowPaystack;
  }

  double _calculateDeliveryFee() {
    if (_deliveryOption == 'pickup') return 0.0;
    if (_paymentSettings?.deliveryFeeEnabled == true) {
      return _paymentSettings!.deliveryFeeAmount;
    }
    return 0.0;
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
        return CartItemCard(
          item: item,
          onIncreaseQuantity: () => _updateQuantity(item, 1),
          onDecreaseQuantity: () => _updateQuantity(item, -1),
          onRemove: () => _removeItem(item),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
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
          child: SizedBox(
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
        );
      },
    );
  }

  void _updateQuantity(CartItem item, int change) {
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      final newQuantity = item.quantity + change;
      if (newQuantity > 0) {
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
      builder: (context) => CheckoutDialog(
        items: state.items,
        userAddress: address,
        paymentSettings: _paymentSettings,
        onCancel: () => Navigator.pop(context),
        onConfirm: (result) => _confirmOrder(
          context,
          user.uid,
          address,
          result,
          state.items,
        ),
      ),
    );
  }

  Future<void> _confirmOrder(
      BuildContext context,
      String userId,
      String address,
      CheckoutResult result,
      List<CartItem> items,
      ) async {
    try {
      if (result.paymentMethod == 'Paystack') {
        final user = context.read<AuthCubit>().currentUser;
        final paymentResult = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => PaystackPaymentDialog(
            amount: result.deliveryFee + items.fold(
              0.0,
                  (sum, item) => sum + (item.price * item.quantity),
            ),
            userEmail: user?.email ?? 'customer@example.com',
            onPaymentComplete: (result) => Navigator.pop(context, result),
          ),
        );

        if (paymentResult?['success'] == true) {
          await context.read<CartCubit>().confirmPurchase(
            userId,
            address,
            result.paymentMethod,
            paymentReference: paymentResult?['paymentReference'],
            deliveryOption: result.deliveryOption,
            deliveryFee: result.deliveryFee,
          );

          Navigator.pop(context);
          _showSuccessSnackbar(context, result.deliveryOption);
        }
      } else {
        await context.read<CartCubit>().confirmPurchase(
          userId,
          address,
          result.paymentMethod,
          deliveryOption: result.deliveryOption,
          deliveryFee: result.deliveryFee,
        );

        Navigator.pop(context);
        _showSuccessSnackbar(context, result.deliveryOption);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackbar(BuildContext context, String deliveryOption) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order confirmed! ${deliveryOption == 'pickup' ? 'Ready for pickup!' : 'Your food is on the way!'}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}