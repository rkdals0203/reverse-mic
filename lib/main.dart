import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/audio_provider.dart';
import 'providers/file_manager_provider.dart';
import 'providers/instagram_reels_provider.dart';
import 'services/app_share_handler.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const ReverseMicApp());
}

class ReverseMicApp extends StatelessWidget {
  const ReverseMicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => FileManagerProvider()),
        ChangeNotifierProvider(create: (_) => InstagramReelsProvider()),
      ],
      child: MaterialApp(
        title: 'Reverse Mic',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
