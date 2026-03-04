import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
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

// ── Auth Gate ────────────────────────────────────────────
// Watches auth state; when user becomes authenticated/guest,
// boots HealthProvider streams and NotificationService.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();

    // Only react when status actually changes to authenticated / guest
    if (auth.status != _lastStatus) {
      _lastStatus = auth.status;

      if (auth.status == AuthStatus.authenticated ||
          auth.status == AuthStatus.guest) {
        // Defer so the widget tree is stable before calling provider methods
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final hp   = context.read<HealthProvider>();
          final uid  = auth.uid.isEmpty ? 'guest_${auth.userPhone}' : auth.uid;
          final name = auth.userName;

          // Start Firestore real-time streams
          hp.initForUser(uid, name);

          // Init FCM (request permissions + subscribe topics)
          NotificationService.instance.init(uid: uid);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.unauthenticated:
        return const OnboardingScreen();
      case AuthStatus.authenticated:
      case AuthStatus.guest:
        return const MainShell();
    }
  }
}

// ── Splash / Loading Screen ───────────────────────────────
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
