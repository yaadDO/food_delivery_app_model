//Creates a global key that can be used to access the NavigatorState from anywhere in the app. This is useful for navigating between screens without needing a BuildContext import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/data/firebase_auth_repo.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_states.dart';
import 'package:food_delivery/features/auth/presentation/pages/welcome_page.dart';
import 'package:food_delivery/features/cart/data/firebase_cart_repo.dart';
import 'package:food_delivery/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:food_delivery/features/catalogue/data/firebase_catalog_repo.dart';
import 'package:food_delivery/features/catalogue/presentation/cubits/catalog_cubit.dart';
import 'package:food_delivery/features/home/presentation/pages/main_tabview.dart';
import 'package:food_delivery/features/profile/data/firebase_profile_repo.dart';
import 'package:food_delivery/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:food_delivery/features/promo/data/firebase_promo_repo.dart';
import 'package:food_delivery/features/promo/presentation/cubit/promo_cubit.dart';
import 'package:food_delivery/features/search/data/firebase_search_repo.dart';
import 'package:food_delivery/features/search/domain/repository/search_repo.dart';
import 'package:food_delivery/features/search/presentation/cubits/search_cubit.dart';
import 'package:food_delivery/features/themes/themes_cubit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'features/admin/presentation/home/admin_home_page.dart';
import 'features/chat/data/firebase_chat_repo.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/notifications/data/notification_repo.dart';
import 'features/notifications/presentation/cubits/notifications_cubit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final firebaseAuthRepo = FirebaseAuthRepo();
  final firebaseProfileRepo = FirebaseProfileRepo();
  final firebaseCatalogRepo = FirebaseCatalogRepo();
  final firebasePromoRepo = FirebasePromoRepo();
  final firebaseCartRepo = FirebaseCartRepo();
  final firebaseChatRepo = FirebaseChatRepo();

  @override
  void initState() {
    super.initState();
    GoogleSignIn().signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) =>
          AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: firebaseProfileRepo,
          ),
        ),
        BlocProvider<CatalogCubit>(
          create: (context) => CatalogCubit(firebaseCatalogRepo),
        ),
        BlocProvider<PromoCubit>(
          create: (context) => PromoCubit(firebasePromoRepo),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(FirebaseCartRepo()),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(
            FirebaseSearchRepo(
              context.read<CatalogCubit>().catalogRepo,
              context.read<PromoCubit>().promoRepo,
            ) as SearchRepo,
          ),
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(FirebaseChatRepo()),
        ),
        BlocProvider<NotificationsCubit>(
          create: (context) => NotificationsCubit(FirebaseNotificationsRepo()),
        ),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, currentTheme) => MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: currentTheme,
          home: BlocConsumer<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is Unauthenticated) return const WelcomeView();
              if (authState is Authenticated) {
                if (authState.isAdmin) return const AdminHomePage();
                return const NavBar();
              }
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            },
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is Authenticated) {
                final currentUserId = context.read<AuthCubit>().currentUser!.uid;
                context.read<ProfileCubit>().fetchUserProfile(currentUserId);

                context.read<NotificationsCubit>().reset();

                navigatorKey.currentState?.popUntil((route) => route.isFirst);
              } else if (state is Unauthenticated) {
                context.read<NotificationsCubit>().reset();
                navigatorKey.currentState?.popUntil((route) => route.isFirst);
              }
            },
          ),
        ),
      ),
    );
  }
}