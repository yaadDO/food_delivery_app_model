import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/notifications/presentation/pages/notification_page.dart';
import 'package:food_delivery/features/payments/presentation/pages/payment_details_page.dart';
import 'package:food_delivery/features/profile/presentation/pages/profile_view.dart';
import 'package:food_delivery/features/themes/themes_cubit.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../profile/presentation/pages/edit_address_screen.dart';
import 'about_us.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background.withOpacity(0.4),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5,35,5,5),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([

                  _buildMenuItem(
                    context,
                    title: 'Profile',
                    icon: Icons.person_outline,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewProfileScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Change Address',
                    icon: Icons.location_on_outlined,
                    color: Colors.blue,
                    onTap: () async {
                      final currentUser = authCubit.currentUser;
                      if (currentUser != null) {
                        final profile = await context.read<ProfileCubit>().getUserProfile(currentUser.uid);
                        if (profile != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAddressScreen(profile: profile),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile not found')),
                          );
                        }
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsView(),
                      ),
                    ),
                  ),
                  _buildSectionHeader(context, 'Support'),
                  _buildMenuItem(
                    context,
                    title: 'Customer Care',
                    icon: Icons.message_outlined,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChatScreen(
                          userId: authCubit.currentUser!.uid,
                        ),
                      ),
                    ),
                  ),
                  _buildThemeSwitch(context, themeCubit),
                  _buildSectionHeader(context, 'General'),
                  _buildMenuItem(
                    context,
                    title: 'Share App',
                    icon: Icons.share,
                    color: Colors.blue,
                    onTap: () => Share.share('Check out this awesome food delivery app!'),
                  ),
                  _buildMenuItem(
                    context,
                    title: 'About',
                    icon: Icons.info_outline,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutPage()),
                    ),
                  ),
                  _buildSectionHeader(context, 'Account'),
                  _buildMenuItem(
                    context,
                    title: 'Logout',
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  authCubit.logout();
                                  Navigator.of(context)
                                    ..pop() // Close dialog
                                    ..pop(); // Close MorePage
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context, ThemeCubit themeCubit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.brightness_6_outlined,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            Switch(
              value: themeCubit.isDarkMode,
              onChanged: (value) => themeCubit.toggleTheme(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}