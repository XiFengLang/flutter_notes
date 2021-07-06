import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'app/flutter_app.dart';
import 'utils/native_messenger.dart';

void main() {
  runZonedGuarded(() {
    runApp(FlutterApp());

    /// App.native通信员初始化
    NativeMessenger.shared();

    configureSystemUIOverlayStyle();
  }, (Object error, StackTrace stack) {
    /// 处理所有未处理的异常
    print("catch error in main() func.   $error");
    // reportErrorLog(makeErrorDetails(error, stack));
  }, zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
    parent.print(zone, "JK Log: $line");
    // collectLog(line);
  }));
}

/// 状态栏
configureSystemUIOverlayStyle() {
  if (Platform.isAndroid) {
    /// 沉侵式状态栏
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // statusBarBrightness: Brightness.dark,
    ));
  }
  // else if (Platform.isIOS) {
  //   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  // }

  /// 单页面沉侵式导航栏  AnnotatedRegion<SystemUiOverlayStyle>
  // AnnotatedRegion<SystemUiOverlayStyle>(
  //   value: SystemUiOverlayStyle.dark,
  //   child: Scaffold,
  // );
}
