import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/cinematic/presentation/cinematic_screen.dart';
import 'core/theme/app_theme.dart';

class ComicCineApp extends StatelessWidget {
  const ComicCineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/cinematic/:comicId',
          builder: (context, state) => CinematicScreen(
            comicId: state.pathParameters['comicId']!,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ComicCine',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
