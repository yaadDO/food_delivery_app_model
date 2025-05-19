import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/notifications/presentation/pages/notification_page.dart';
import 'package:food_delivery/features/payments/presentation/pages/payment_details_page.dart';
import 'package:food_delivery/features/profile/presentation/pages/profile_view.dart';
import 'package:food_delivery/features/settings/presentation/pages/settings_page.dart';
import 'package:food_delivery/features/themes/themes_cubit.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    bool isDarkMode = themeCubit.isDarkMode;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
        child: Column(
          children: [
            ListTile(
                title: Text(
                  'Profile',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.person),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewProfileScreen()));
                }),
            ListTile(
                title: Text(
                  'Payment Details',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.credit_card),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentDetailsView()))),
            const SizedBox(height: 5),
            ListTile(
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.notifications),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsView()))),
            ListTile(
                title: Text(
                  'Message Customer care',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.message),
              onTap: () {
                // Get the user ID from your state management (like AuthCubit)
                final currentUserId = context.read<AuthCubit>().currentUser!.uid;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserChatScreen(userId: currentUserId), // Pass the user ID
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            ListTile(
                title: Text(
                  'Settings',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.settings),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()));
                }),
          ],
        ),
      ),
    );
  }
}
