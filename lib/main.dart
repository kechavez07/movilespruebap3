
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'logica/providers/app_provider.dart';
import 'paginas/home_page.dart';
import 'whitgest/ux/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Continuar incluso si falta el archivo para permitir usar --dart-define
    debugPrint('⚠️ .env no cargado: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Evaluador Tests Inteligente',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Colors
          primaryColor: kPrimaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
          useMaterial3: true,
          scaffoldBackgroundColor: kBackgroundColor,
          
          // AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),

          // Buttons
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          // Floating Action Button
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: kSecondaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
