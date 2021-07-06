import 'package:flutter/material.dart';
import 'package:flutter_module/utils/color_util.dart';
import '../views/navigation_bar.dart';

class AppRootPage extends StatelessWidget {
  const AppRootPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ControllerView(
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Text(
                "flutter_boost",
                style: TextStyle(
                  fontSize: 15,
                  color: ColorUtil.dynamicColor(
                    context: context,
                    light: Colors.black45,
                    dark: Colors.white,
                  ),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          NavigationBar(
            title: "",
          ),
        ],
      ),
    );
  }
}
