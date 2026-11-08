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
          path: '/cinematic',
          builder: (context, state) {
            // Query parameters থেকে পাথ এবং নাম বের করা
            final filePath = state.uri.queryParameters['path'] ?? 'Unknown Path';
            final fileName = state.uri.queryParameters['name'] ?? 'Unknown File';
            
            return CinematicScreen(
              filePath: filePath,
              fileName: fileName,
            );
          },
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
