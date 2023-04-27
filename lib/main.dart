import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/bottom_nav_bar.dart';
import 'package:project/db.dart';
import 'package:project/screens/get_screen.dart';
import 'package:project/screens/unknown_screen.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize database and values for today
  await DB.instance.database;
  DB().setDay(DB.id);

  runApp(
    ChangeNotifierProvider(
      create: (context) => DB(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const BottomBar());
        }

        var uri = Uri.parse(settings.name!);
        if (uri.pathSegments.first == 'get') {
          return MaterialPageRoute(
              builder: (context) => GetScreen(uri.pathSegments[1]));
        }

        return MaterialPageRoute(builder: (context) => UnknownScreen());
      },
    );
  }
}
