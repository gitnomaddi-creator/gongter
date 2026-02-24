import 'package:go_router/go_router.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/screens/auth/login_screen.dart';
import 'package:gongter/screens/auth/signup_screen.dart';
import 'package:gongter/screens/auth/profile_setup_screen.dart';
import 'package:gongter/screens/home/home_screen.dart';
import 'package:gongter/screens/post/post_detail_screen.dart';
import 'package:gongter/screens/post/post_write_screen.dart';
import 'package:gongter/screens/post/post_edit_screen.dart';
import 'package:gongter/screens/explore/explore_screen.dart';
import 'package:gongter/screens/notification/notification_screen.dart';
import 'package:gongter/screens/profile/profile_screen.dart';
import 'package:gongter/screens/profile/my_posts_screen.dart';
import 'package:gongter/screens/profile/my_comments_screen.dart';
import 'package:gongter/screens/profile/bookmarks_screen.dart';
import 'package:gongter/screens/settings/settings_screen.dart';
import 'package:gongter/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = SupabaseService.isLoggedIn;
    final loc = state.matchedLocation;
    final isAuthRoute =
        loc == '/login' || loc == '/signup' || loc == '/profile-setup';
    if (!loggedIn && !isAuthRoute) return '/login';
    if (loggedIn && (loc == '/login' || loc == '/signup')) return '/';
    return null;
  },
  routes: [
    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    // Main shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ExploreScreen(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotificationScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    // Detail screens (outside shell)
    GoRoute(
      path: '/post/:id',
      builder: (context, state) => PostDetailScreen(
        postId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/write',
      builder: (context, state) => const PostWriteScreen(),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) => PostEditScreen(
        postId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/my-posts',
      builder: (context, state) => const MyPostsScreen(),
    ),
    GoRoute(
      path: '/my-comments',
      builder: (context, state) => const MyCommentsScreen(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
  ],
);
