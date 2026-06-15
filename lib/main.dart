import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:yvl/screens/home_shell.dart';
import 'package:yvl/screens/login_screen.dart';
import 'package:yvl/services/storage_service.dart';
import 'package:yvl/services/navigator_key.dart';
import 'package:yvl/services/notification_service.dart';
import 'package:yvl/providers/theme_provider.dart';
import 'package:yvl/providers/settings_provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final container = ProviderContainer();

  await Future.wait(<Future<dynamic>>[
    JustAudioBackground.init(
      androidNotificationChannelId: 'com.shashwat.yvl.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
    container.read(storageServiceProvider).init(),
    NotificationService().init(),
  ]);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final themeType = ref.watch(settingsProvider).themeType;
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final effectiveBrightness = themeType == ThemeType.auto
            ? platformBrightness
            : (themeType == ThemeType.light ? Brightness.light : Brightness.dark);
        final selectedDynamic =
            effectiveBrightness == Brightness.light ? lightDynamic : darkDynamic;

        Future.microtask(() {
          if (ref.read(dynamicColorSchemeProvider) != selectedDynamic) {
            ref.read(dynamicColorSchemeProvider.notifier).state = selectedDynamic;
          }
        });

        final theme = ref.watch(themeProvider);
        final storage = ref.watch(storageServiceProvider);
        final showLogin = !storage.hasCompletedOnboarding;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'YVL',
          debugShowCheckedModeBanner: false,
          theme: theme,
          // No builder — each destination manages its own layout.
          // HomeShell wraps HomeScreen with GlobalBackground + MainLayout.
          // LoginScreen manages its own full-screen rendering.
          home: showLogin ? const LoginScreen() : const HomeShell(),
        );
      },
    );
  }
}
