import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:flutter_boost/messages.dart';
import 'package:flutter_boost/boost_navigator.dart';

import '../views/navigation_bar.dart';
import '../views/navigation_bar.dart';
import '../views/navigation_bar.dart';
import '../views/search_navigation_bar.dart';
import '../views/navigation_bar.dart';
import '../views/search_navigation_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    /// 延迟弹出键盘，不然会导致Flutter渲染异常抖动
    Future.delayed(Duration(milliseconds: 800), (){
      if (mounted) {
        focusNode.requestFocus();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    print('搜索页已释放');

    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ControllerView(
            child: Container(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: (){
                  CommonParams params = CommonParams()..pageName = "a"..arguments = {"a":"a",
                    "b":"a"}..uniqueId = "asadadas";
                  NativeRouterApi().pushNativeRoute(params);
                  BoostNavigator.instance.push("name");
                },
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: Container(
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
          ),
          SearchNavigationBar(
            focusNode: focusNode,
            controller: controller,
            placeholder: "输入你想搜索的东东或者西西",
            onSubmitted: (query) {
              print('搜索 :${query.trim()}');
            },
            onChanged: (text) {
              print('输入文字 :$text');
            },
          ),
        ],
      ),
    );
  }
}
