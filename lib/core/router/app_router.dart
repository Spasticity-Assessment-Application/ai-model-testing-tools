import 'package:go_router/go_router.dart';
import 'package:poc/features/presentation/home_page.dart';

class AppRouter {
  GoRouter get router => GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    ],
  );
}
