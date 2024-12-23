import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:signature/signature.dart';
import 'package:sirve_poc/pdf/theme_page.dart';
import 'package:sirve_poc/pdf_e_sign.dart';

void main() {
  runApp(const MyApp());
}

class ThemeSettings {
  final Color color;
  final TextStyle textStyle;

  ThemeSettings({required this.color, required this.textStyle});
}

ValueNotifier<ThemeSettings> themeSettings = ValueNotifier<ThemeSettings>(
  ThemeSettings(
    color: Colors.orange,
    textStyle: const TextStyle(fontFamily: 'Roboto'),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: themeSettings,
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: settings.color),
            textTheme: TextTheme(
              bodyLarge: settings.textStyle,
              bodyMedium: settings.textStyle,
              bodySmall: settings.textStyle,
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: settings.color,
              textTheme: ButtonTextTheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.color,
                foregroundColor: Colors.white,
                textStyle: settings.textStyle,
              ),
            ),
            useMaterial3: true,
          ),
          home: const MyHomePage(
            title: 'Sirva POCs',
          ),
          routes: {
            '/pdf-sign': (context) => const PdfESign(),
            '/home': (context) => const MyHomePage(title: 'Sirva POCs'),
            '/theme': (context) => const ThemePage(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? signatureData;
  Color? pickerColor;
  bool relatedColorsVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        // color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        // ignore: use_build_context_synchronously
                        context,
                        '/pdf-sign',
                      );
                    },
                    child: const Text('Pdf Signature'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Select Application theme color',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      themeSettings.value = ThemeSettings(
                        color: Colors.red,
                        textStyle: const TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 18,
                        ),
                      );
                      navigateToThemePage(context);
                    },
                    child: const Text('Red'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      themeSettings.value = ThemeSettings(
                        color: Colors.green,
                        textStyle: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 18,
                        ),
                      );
                      navigateToThemePage(context);
                    },
                    child: const Text('Green'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      themeSettings.value = ThemeSettings(
                        color: Colors.blue,
                        textStyle: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                        ),
                      );
                      navigateToThemePage(context);
                    },
                    child: const Text(
                      'Blue',
                    ),
                  ),
                ),
              ],
            ),

            // demo text
            const SizedBox(height: 10),
            Text(
              'See the text style changes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ), //
    );
  }

  void navigateToThemePage(BuildContext context) {
    Navigator.pushNamed(
      // ignore: use_build_context_synchronously
      context,
      '/theme',
    );
  }

  void showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Colors.blue,
              onColorChanged: (Color color) {
                setState(() {
                  pickerColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
