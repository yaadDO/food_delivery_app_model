import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../../../admin/presentation/home/admin_home_page.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_states.dart';

class LoginPage extends StatefulWidget {
  final void Function()? togglePages;

  const LoginPage({
    super.key,
    required this.togglePages,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  late AnimationController _owlController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _owlController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _playOwlAnimation();

    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _playOwlAnimation();
    });
  }

  void _playOwlAnimation() {
    _owlController
      ..reset()
      ..forward();
  }

  void login() {
    final String email = emailController.text;
    final String pw = pwController.text;

    final authCubit = context.read<AuthCubit>();

    if (email.isNotEmpty && pw.isNotEmpty) {
      authCubit.login(email, pw);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login error')));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    pwController.dispose();
    _owlController.dispose();
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _playOwlAnimation,
                      child: Lottie.asset(
                        'assets/lottie/owl.json',
                        controller: _owlController,
                        width: 225,
                        height: 225,
                        fit: BoxFit.contain,
                        repeat: false,
                        animate: false,
                        errorBuilder: (context, error, stackTrace) {
                          return Text('Error loading animation: $error');
                        },
                      ),
                    ),
                    Text(
                      'Welcome',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 25),
                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 15),
                    MyTextField(
                      controller: pwController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return MyButton(
                          onTap: state is AuthLoading ? null : login,
                          text: 'Login',
                          isLoading: state is AuthLoading, // Added
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return IconButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () => context.read<AuthCubit>().signInWithGoogle(),
                          icon: Image.asset(
                            'assets/img/google_icon.png',
                            width: 32,
                            height: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: widget.togglePages,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IgnorePointer(
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      WavyAnimatedText(
                                        'Register me >',
                                        textStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                        speed: const Duration(milliseconds: 200),
                                      ),
                                    ],
                                    repeatForever: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}