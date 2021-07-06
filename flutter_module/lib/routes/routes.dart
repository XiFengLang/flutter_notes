import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


import 'package:flutter_boost/boost_navigator.dart';

import '../pages/app_root_page.dart';
import '../pages/search_page.dart';

class AppRouter {
  static Map<String, FlutterBoostRouteFactory> routerMap = {
    '/': (settings, uniqueId) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => AppRootPage(),
      );
    },

    'root_page': (settings, uniqueId) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => AppRootPage(),
      );
    },


    'search_page': (settings, uniqueId) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => SearchPage(),
      );
    },

  };

  static Route<dynamic> routeFactory(RouteSettings setting, String uniqueId) {
    FlutterBoostRouteFactory factory = routerMap[setting.name];
    if (factory == null) {
      return null;
    }
    return factory(setting, uniqueId);
  }
}
