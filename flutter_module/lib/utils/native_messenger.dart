import 'package:flutter/services.dart';

import 'package:flutter_boost/boost_navigator.dart';
// import 'theme_mode_dispatcher.dart';

class NativeMessenger {
  static final NativeMessenger _shared = NativeMessenger._init();

  static NativeMessenger shared() => _shared;

  NativeMessenger._init() {
    _initMessageChannel();
  }

  final _methodChannel = const MethodChannel('app_global_channel');

  MethodChannel get channel => _methodChannel;

  /// 跟Native通信交互
  void _initMessageChannel() {
    _methodChannel.setMethodCallHandler((MethodCall call) {
      print(
          'NativeMessenger收到native消息： method:${call.method}     arguments:${call.arguments}');

      if (call.method == 'set_theme_mode') {
        // final Brightness brightness = call.arguments['mode'] as String == 'dark'
        //     ? Brightness.dark
        //     : Brightness.light;
        // ThemeModeDispatcher.shared()
        //     .handlePlatformBrightnessChanged(brightness);
      } else if (call.method == 'exit_current_page') {
        BoostNavigator.instance.pop();
      }
      return Future<dynamic>.value();
    });
  }
}
