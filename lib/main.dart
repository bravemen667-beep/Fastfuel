import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/health_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase Initialization ───────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const GoFasterApp());
}

class GoFasterApp extends StatelessWidget {
  const GoFasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GFAuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        title: 'GoFaster Health',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AuthGate(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
// Primary source of truth: FirebaseAuth.instance.authStateChanges()
// If FirebaseAuth has no user  → OnboardingScreen → LoginScreen
// If FirebaseAuth has a user   → MainShell (home)
// GFAuthProvider.status is kept in sync by its own authStateChanges listener.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Loading / initialising ─────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;

        if (user != null) {
          // ── Authenticated — boot services once ───────────────
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final hp   = context.read<HealthProvider>();
            final auth = context.read<GFAuthProvider>();
            final uid  = user.uid;
            final name = user.displayName ?? user.phoneNumber ?? 'User';
            hp.initForUser(uid, name);
            NotificationService.instance.init(uid: auth.firestoreUid);
          });
          return const MainShell();
        } else {
          // ── Not authenticated ────────────────────────────────
          return const OnboardingScreen();
        }
      },
    );
  }
}

// ── Splash / Loading Screen ───────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.fire,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text('GoFaster', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
            const SizedBox(height: 32),
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
