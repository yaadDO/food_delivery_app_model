import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../payments/payment_settings.dart';
import '../../../settings/data/firebase_settings_repo.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final FirebaseSettingsRepo _settingsRepo = FirebaseSettingsRepo();
  late PaymentSettings _paymentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _paymentSettings = await _settingsRepo.getPaymentSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _paymentSettings = PaymentSettings(
        allowCashOnDelivery: true,
        allowPaystack: true,
        deliveryFeeEnabled: false,
        deliveryFeeAmount: 5.0,
        allowPickup: true,
        lastUpdated: DateTime.now(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsRepo.updatePaymentSettings(_paymentSettings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // UPDATED: Simplified logout method
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                context.read<AuthCubit>().logout();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveSettings,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment Methods'),
            _buildPaymentSettings(),
            const SizedBox(height: 20),
            _buildLastUpdatedInfo(),
            const SizedBox(height: 30),
            _buildLogoutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildPaymentSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPaymentOption(
              title: 'Cash on Delivery',
              subtitle: 'Allow customers to pay when they receive their order',
              value: _paymentSettings.allowCashOnDelivery,
              onChanged: (value) {
                setState(() {
                  _paymentSettings = _paymentSettings.copyWith(
                    allowCashOnDelivery: value,
                  );
                });
              },
            ),
            const Divider(),
            _buildPaymentOption(
              title: 'Paystack Payment',
              subtitle: 'Allow customers to pay online using Paystack',
              value: _paymentSettings.allowPaystack,
              onChanged: (value) {
                setState(() {
                  _paymentSettings = _paymentSettings.copyWith(
                    allowPaystack: value,
                  );
                });
              },
            ),
            const Divider(),
            _buildPaymentOption(
              title: 'Allow Pickup Option',
              subtitle: 'Allow customers to choose pickup instead of delivery',
              value: _paymentSettings.allowPickup,
              onChanged: (value) {
                setState(() {
                  _paymentSettings = _paymentSettings.copyWith(
                    allowPickup: value,
                  );
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Delivery Fee',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: _paymentSettings.deliveryFeeEnabled
                  ? Text('Delivery fee: \$${_paymentSettings.deliveryFeeAmount.toStringAsFixed(2)}')
                  : const Text('No delivery fee'),
              value: _paymentSettings.deliveryFeeEnabled,
              onChanged: (value) {
                setState(() {
                  _paymentSettings = _paymentSettings.copyWith(
                    deliveryFeeEnabled: value,
                  );
                });
              },
              secondary: Icon(
                Icons.delivery_dining,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (_paymentSettings.deliveryFeeEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                child: TextFormField(
                  initialValue: _paymentSettings.deliveryFeeAmount.toStringAsFixed(2),
                  decoration: const InputDecoration(
                    labelText: 'Delivery Fee Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    if (amount >= 0) {
                      setState(() {
                        _paymentSettings = _paymentSettings.copyWith(
                          deliveryFeeAmount: amount,
                        );
                      });
                    }
                  },
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Note: At least one payment method must be enabled',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        title.contains('Cash') ? Icons.money_off_csred : Icons.credit_card,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Last updated: ${_paymentSettings.lastUpdated.toString().substring(0, 16)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}