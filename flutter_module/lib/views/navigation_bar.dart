import 'package:flutter/material.dart';
import '../utils/color_util.dart';

/// 默认高度44（不包括状态栏的高度safeArea.top）
const double kNavigationBarHeight = 44;

/// 默认的导航栏，有leftItem、titleItem、rightItem 3个控件
class NavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final double barHeight;
  final Color backgroundColor;
  final DecorationImage backgroundImage;
  final String title;
  final NavigationBarItem titleItem; // titleItem 和 title 2选1就行
  final Widget leftItem;
  final Widget rightItem;

  NavigationBar({
    Key key,
    this.barHeight = kNavigationBarHeight,
    this.backgroundColor,
    this.backgroundImage,
    this.title,
    this.titleItem,
    this.leftItem,
    this.rightItem,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    return NavigationBarContainer(
      color: backgroundColor ??
          ColorUtil.dynamicColor(
              context: context,
              light: Color(0xFFF7F7F7),
              dark: Color(0xFF212121)),
      image: backgroundImage,
      barHeight: barHeight,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        children: [
          Container(
            child: _titleView(),
          ),
          Positioned(
            left: 0,
            child: Padding(
              padding: EdgeInsets.only(left: 10),
              child: leftItem,
            ),
          ),
          Positioned(
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: rightItem,
            ),
          )
        ],
      ),
    );
  }

  /// 创建titleView
  NavigationBarItem _titleView() {
    if (titleItem != null) {
      return titleItem;
    } else {
      return NavigationBarItem(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          title ?? "",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }
  }
}

/// 导航栏容器，safeArea.top + barHeight(44)
class NavigationBarContainer extends StatelessWidget {
  final Color color;
  final DecorationImage image;
  final Widget child;
  final double barHeight;

  NavigationBarContainer({
    Key key,
    this.image,
    this.color,
    this.barHeight = kNavigationBarHeight,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// 整个导航栏容器（铺满了状态栏底部）
    final MediaQueryData data = MediaQuery.of(context);
    final double topPadding = data.padding.top;

    var backgroundColor = color ??
        ColorUtil.dynamicColor(
            context: context,
            light: Color(0xFFF7F7F7),
            dark: Color(0xFF212121));

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        image: image,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: false,
          removeTop: true,
          removeRight: false,
          removeBottom: false,

          /// 实际导航栏容器，默认高度44
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(color: backgroundColor),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 相当于iOS中UIViewController的self.view  顶部边距 Padding：safeArea.top + barHeight(44)
class ControllerView extends StatelessWidget {
  final double barHeight;
  final Widget child;

  ControllerView({
    Key key,
    this.child,
    this.barHeight = kNavigationBarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double topPadding = data.padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: false,
        removeTop: true,
        removeRight: false,
        removeBottom: true,
        child: Container(
          padding: EdgeInsets.only(top: barHeight),
          child: child,
        ),
      ),
    );
  }
}

/// 左右单个action的容器，也可以做title的容器
/// 默认高度44 [kNavigationBarHeight]
class NavigationBarItem extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback onTap;

  NavigationBarItem({
    Key key,
    this.child,
    this.onTap,
    this.padding,
    this.height = kNavigationBarHeight,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        color: Colors.transparent,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 5),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
