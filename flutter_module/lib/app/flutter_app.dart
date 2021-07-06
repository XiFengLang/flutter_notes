import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_boost/flutter_boost.dart';

import '../routes/routes.dart';

class FlutterApp extends StatefulWidget {
  const FlutterApp({Key key}) : super(key: key);

  @override
  _FlutterAppState createState() => _FlutterAppState();
}

class _FlutterAppState extends State<FlutterApp> {
  @override
  void initState() {
    /// init
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterBoostApp(
      AppRouter.routeFactory,
      initialRoute: '/',
      appBuilder: (Widget home) {
        return MaterialApp(
          home: home,
          title: 'flutter_boost采坑',
          themeMode: ThemeMode.system,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.yellow,//Color(0xFFFFFFFF),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Color(0xFF000000),
          ),
        );
      },
    );
  }
}
