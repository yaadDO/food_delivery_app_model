import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_page.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.15),
              // Logo with shadow and animation
              Animate(
                effects: [ScaleEffect(duration: 500.ms)],
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Image.asset(
                    "assets/img/store_icon.png",
                    width: size.width * 0.5,
                    height: size.width * 0.5,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.orange.shade600,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'Food Express',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Base color (will be overridden)
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),
              SizedBox(height: size.height * 0.02),
              // Rest of the code remains the same...
              const Text(
                'Savor the flavor, delivered to your door',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ).animate().slideY(duration: 500.ms),
              SizedBox(height: size.height * 0.1),
              // Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthPage(initialShowLogin: true),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideX(
                  begin: -1,
                  duration: 500.ms,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              // Register Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.amber.shade400, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthPage(initialShowLogin: false),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, color: Colors.amber),
                      const SizedBox(width: 10),
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade400,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideX(
                  begin: 1,
                  duration: 500.ms,
                ),
              ),
              SizedBox(height: size.height * 0.05),

              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}