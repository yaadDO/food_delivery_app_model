// view_profile_screen.dart
// view_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_states.dart';
import 'package:food_delivery/features/profile/presentation/pages/edit_profile_page.dart';
import '../../domain/entities/profile_user.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit,),
            onPressed: () => _navigateToEditScreen(context),
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoaded) {
            return _buildProfileContent(state.profileUser as ProfileUser);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProfileContent(ProfileUser profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(profile),
          const SizedBox(height: 30),
          _buildInfoSection(profile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileUser profile) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all( width: 2),
          ),
          child: Center(
            child: Text(
              _getInitials(profile.name),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,

              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          profile.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,

          ),
        ),
        if (profile.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              profile.bio,
              style: TextStyle(
                fontSize: 16,

                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(ProfileUser profile) {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.email,
          title: 'Email',
          value: profile.email,
        ),
        const SizedBox(height: 15),
        _buildInfoCard(
          icon: Icons.phone_android,
          title: 'Phone',
          value: profile.phoneNumber,
        ),
        const SizedBox(height: 15),
        _buildInfoCard(
          icon: Icons.location_pin,
          title: 'Address',
          value: profile.address,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28,),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,

                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : 'Not provided',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _navigateToEditScreen(BuildContext context) {
    final currentState = context.read<ProfileCubit>().state;
    if (currentState is ProfileLoaded) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(profile: currentState.profileUser),
        ),
      );
    }
  }
}