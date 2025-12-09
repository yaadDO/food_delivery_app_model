import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import '../../../payments/payment_dialog.dart';
import '../../../payments/payment_settings.dart';
import '../../../settings/data/firebase_settings_repo.dart';
import '../../domain/entities/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _processingOrder = false;
  String _selectedPaymentMethod = '';
  String _deliveryOption = 'delivery'; // 'delivery' or 'pickup'
  final FirebaseSettingsRepo _settingsRepo = FirebaseSettingsRepo();
  PaymentSettings? _paymentSettings;
  bool _loadingPaymentSettings = false;

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
      // Set initial selected payment method
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
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
            child: FutureBuilder<String>(
              future: _getImageUrl(item.imagePath),
              builder: (context, snapshot) {
                // Cache the image URL
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: snapshot.hasData && snapshot.data!.isNotEmpty
                      ? Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    cacheHeight: 100,
                    cacheWidth: 100,
                  )
                      : Center(
                    child: Icon(
                      Icons.fastfood,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
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
                      // Optimized quantity controls
                      _buildQuantityControls(item),
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

  Widget _buildQuantityControls(CartItem item) {
    return Container(
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
          // Use ValueListenableBuilder for smooth quantity updates
          ValueListenableBuilder<int>(
            valueListenable: ValueNotifier<int>(item.quantity),
            builder: (context, quantity, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _updateQuantity(item, 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final subtotal = state is CartLoaded ? _calculateSubtotal(state.items) : 0.0;
        final deliveryFee = _calculateDeliveryFee();
        final total = subtotal + deliveryFee;
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
        // This will trigger the optimistic update
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
        builder: (context, dialogSetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Order',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: _buildCheckoutContent(context, state.items, address, dialogSetState),
          actions: _buildDialogActions(context, dialogSetState, user.uid),
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(
      BuildContext context,
      List<CartItem> items,
      String address,
      StateSetter dialogSetState,
      ) {
    final subtotal = _calculateSubtotal(items);
    final deliveryFee = _calculateDeliveryFee();
    final total = subtotal + deliveryFee;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delivery/Pickup Option
          if (_paymentSettings?.allowPickup == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Option',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDeliveryOptionButton(
                        icon: Icons.delivery_dining,
                        label: 'Delivery',
                        selected: _deliveryOption == 'delivery',
                        onTap: () {
                          dialogSetState(() {
                            _deliveryOption = 'delivery';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDeliveryOptionButton(
                        icon: Icons.storefront,
                        label: 'Pickup',
                        selected: _deliveryOption == 'pickup',
                        onTap: () {
                          dialogSetState(() {
                            _deliveryOption = 'pickup';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Address Section (only show for delivery)
          if (_deliveryOption == 'delivery')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor, size: 20),
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
                const SizedBox(height: 16),
              ],
            ),

          // Payment Method Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodSelector(dialogSetState),
            ],
          ),

          const SizedBox(height: 20),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOrderSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                if (deliveryFee > 0)
                  _buildOrderSummaryRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                if (_deliveryOption == 'pickup')
                  _buildOrderSummaryRow('Pickup', 'Free'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${items.length} item${items.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          // Info Message
          if (_deliveryOption == 'delivery' && deliveryFee > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery fee will be added to your total',
                      style: TextStyle(color: Colors.blue[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          if (_deliveryOption == 'pickup')
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Icon(Icons.storefront, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ll pickup your order at our store location',
                      style: TextStyle(color: Colors.green[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(StateSetter dialogSetState) {
    if (_loadingPaymentSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentSettings == null) {
      return const Text('Unable to load payment options');
    }

    final List<Map<String, dynamic>> availableMethods = [];

    if (_paymentSettings!.allowCashOnDelivery) {
      availableMethods.add({
        'value': 'Cash on Delivery',
        'title': 'Cash on Delivery',
        'subtitle': 'Pay when your order arrives',
        'icon': Icons.money,
      });
    }

    if (_paymentSettings!.allowPaystack) {
      availableMethods.add({
        'value': 'Paystack',
        'title': 'Paystack',
        'subtitle': 'Pay securely with card, bank, etc.',
        'icon': Icons.credit_card,
      });
    }

    if (availableMethods.isEmpty) {
      return Column(
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 10),
          Text(
            'No payment methods available. Please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange),
          ),
        ],
      );
    }

    if (availableMethods.length == 1 && _selectedPaymentMethod != availableMethods[0]['value']) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dialogSetState(() {
          _selectedPaymentMethod = availableMethods[0]['value'] as String;
        });
      });
    }

    return Column(
      children: availableMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['value'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant ?? Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          elevation: isSelected ? 2 : 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'] as IconData,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              method['title'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              method['subtitle'] as String,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
                  : null,
            ),
            onTap: () {
              dialogSetState(() {
                _selectedPaymentMethod = method['value'] as String;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildDialogActions(
      BuildContext context,
      StateSetter dialogSetState,
      String userId,
      ) {
    return [
      TextButton(
        onPressed: _processingOrder ? null : () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
      ),
      ElevatedButton(
        onPressed: _processingOrder || !_paymentMethodsAvailable() || _selectedPaymentMethod.isEmpty
            ? null
            : () => _confirmOrder(context, dialogSetState, userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: !_paymentMethodsAvailable() && _selectedPaymentMethod.isEmpty
              ? const Text('No Payment Methods', style: TextStyle(color: Colors.white))
              : _processingOrder
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text('Confirm Order', style: TextStyle(color: Colors.white)),
        ),
      ),
    ];
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _confirmOrder(
      BuildContext context,
      StateSetter dialogSetState,
      String userId,
      ) async {
    if (!_isPaymentMethodAllowed(_selectedPaymentMethod)) {
      dialogSetState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected payment method is not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    dialogSetState(() => _processingOrder = true);

    try {
      final state = context.read<CartCubit>().state;
      if (state is CartLoaded) {
        final profile = await context.read<ProfileCubit>().getUserProfile(userId);
        final address = _deliveryOption == 'delivery'
            ? profile?.address ?? 'No address set'
            : 'Store Pickup';
        final user = context.read<AuthCubit>().currentUser;

        final subtotal = _calculateSubtotal(state.items);
        final deliveryFee = _calculateDeliveryFee();
        final total = subtotal + deliveryFee;

        if (_selectedPaymentMethod == 'Paystack') {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => PaystackPaymentDialog(
              amount: total, // Use total including delivery fee
              userEmail: user?.email ?? 'customer@example.com',
              onPaymentComplete: (result) {
                Navigator.pop(context, result);
              },
            ),
          );

          if (result?['success'] == true) {
            // We need to update CartCubit to accept delivery options
            await context.read<CartCubit>().confirmPurchase(
              userId,
              address,
              _selectedPaymentMethod,
              paymentReference: result?['paymentReference'],
              deliveryOption: _deliveryOption,
              deliveryFee: deliveryFee,
            );

            Navigator.pop(context); // Close checkout dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! Order confirmed. ${_deliveryOption == 'pickup' ? 'Ready for pickup!' : 'Your food is on the way!'}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            dialogSetState(() => _processingOrder = false);
            return;
          }
        } else {
          await context.read<CartCubit>().confirmPurchase(
            userId,
            address,
            _selectedPaymentMethod,
            deliveryOption: _deliveryOption,
            deliveryFee: deliveryFee,
          );

          Navigator.pop(context); // Close checkout dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order confirmed! ${_deliveryOption == 'pickup' ? 'Ready for pickup!' : 'Your food is on the way!'}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      dialogSetState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return '';
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      print('Error loading image: $e');
      return '';
    }
  }
}