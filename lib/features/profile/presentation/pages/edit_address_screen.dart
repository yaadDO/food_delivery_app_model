import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import '../../domain/entities/profile_user.dart';
import '../cubits/profile_states.dart';

class EditAddressScreen extends StatefulWidget {
  final ProfileUser profile;

  const EditAddressScreen({super.key, required this.profile});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController _addressController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.profile.address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (_isUpdating) {
            if (state is ProfileLoaded) {
              Navigator.pop(context);
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              setState(() => _isUpdating = false);
            }
          }
        },
        child: _buildEditForm(),
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isUpdating ? null : _saveAddress,
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  void _saveAddress() {
    setState(() => _isUpdating = true);
    context.read<ProfileCubit>().updateProfile(
      uid: widget.profile.uid,
      name: widget.profile.name,
      bio: widget.profile.bio,
      phoneNumber: widget.profile.phoneNumber,
      address: _addressController.text,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}