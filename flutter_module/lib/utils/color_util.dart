import 'package:flutter/material.dart';

class ColorUtil {
  /// 动态选择深浅色
  static Color dynamicColor({
    @required BuildContext context,
    @required Color light,
    @required Color dark,
  }) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
