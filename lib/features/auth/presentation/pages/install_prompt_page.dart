import 'package:flutter/material.dart';

class InstallPromptPage extends StatelessWidget {
  const InstallPromptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1D37),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_to_home_screen,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Lütfen Uygulamayı Yükleyin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Bildirimleri doğru alabilmek ve uygulamayı daha verimli kullanabilmek için lütfen tarayıcınızın menüsünden "Ana Ekrana Ekle" (Add to Home Screen) veya "Uygulamayı Yükle" (Install App) seçeneğine tıklayarak uygulamayı cihazınıza yükleyin.\n\nArdından ana ekranınızdaki simgeden giriş yapın.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
