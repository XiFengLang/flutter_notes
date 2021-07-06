// import 'dart:ui';
// import 'package:flutter/material.dart' show Brightness;
// import 'observers_holder.dart';
//
// typedef ThemeModeObserver = void Function(Brightness brightness);
//
//
// class ThemeModeDispatcher {
//   static final ThemeModeDispatcher _shared = ThemeModeDispatcher._init();
//
//   ThemeModeDispatcher._init();
//
//   static ThemeModeDispatcher shared() => _shared;
//
//   final ObserversHolder _observers = ObserversHolder();
//
//
//   VoidCallback addObserver(ThemeModeObserver observer) =>
//       _observers.addObserver<ThemeModeObserver>(observer);
//
//   void removeObserver(ThemeModeObserver observer) =>
//       _observers.removeObserver<ThemeModeObserver>(observer);
//
//   void handlePlatformBrightnessChanged(Brightness brightness) {
//     for (final ThemeModeObserver observer
//     in _observers.observersOf<ThemeModeObserver>()) {
//       observer(brightness);
//     }
//   }
// }