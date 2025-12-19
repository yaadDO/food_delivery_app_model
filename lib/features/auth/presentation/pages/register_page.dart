import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/home/presentation/pages/main_tabview.dart';
import 'package:lottie/lottie.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_states.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? togglePages;

  const RegisterPage({super.key, required this.togglePages});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();
  late AnimationController _regController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _regController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _playRegAnimation();

    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _playRegAnimation();
    });
  }

  void _playRegAnimation() {
    _regController
      ..reset()
      ..forward();
  }

  void register() {
    final String name = nameController.text;
    final String email = emailController.text;
    final String pw = pwController.text;
    final String confirmPw = confirmPwController.text;

    final authCubit = context.read<AuthCubit>();

    if (email.isNotEmpty &&
        name.isNotEmpty &&
        pw.isNotEmpty &&
        confirmPw.isNotEmpty) {
      if (pw == confirmPw) {
        authCubit.register(name, email, pw);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('password mismatch')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please complete all fields')));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    _regController.dispose();
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _playRegAnimation,
                  child: Lottie.asset(
                    'assets/lottie/register.json',
                    controller: _regController,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: false,
                    animate: false,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('Error loading animation: $error');
                    },
                  ),
                ),
                Text(
                  'Join the family',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                MyTextField(
                  controller: nameController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: pwController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: confirmPwController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 5),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return MyButton(
                      onTap: state is AuthLoading ? null : register,
                      text: 'Register',
                      isLoading: state is AuthLoading,
                    );
                  },
                ),
                const SizedBox(height: 10),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return IconButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () => context.read<AuthCubit>().signInWithGoogle(),
                      icon: Image.asset(
                        'assets/img/google_icon.png',
                        width: 37,
                        height: 37,
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
                const SizedBox(height: 5),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Spacer(),
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
                                    '< Login Now',
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
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}