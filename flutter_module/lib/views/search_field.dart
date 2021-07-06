import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../utils/color_util.dart';

class SearchField extends StatefulWidget {
  final FocusNode focusNode;
  final String placeholder;
  final TextEditingController controller;
  final Function(String query) onSubmitted;
  final Function(String text) onChanged;

  SearchField({
    Key key,
    this.focusNode,
    this.placeholder,
    this.controller,
    this.onSubmitted,
    this.onChanged,
  }) : super(key: key);

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  String _lastText = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        color: ColorUtil.dynamicColor(
            context: context,
            light: Color(0xFFE3E3E3),
            dark: Color(0xFF151515)),
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          autofocus: false,
          focusNode: widget.focusNode,
          onSubmitted: _submitSearch,
          onChanged: _textChanged,

          /// 2021/2/26高版本属性2.10.1才可以使用
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(
                "[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]")),
            LengthLimitingTextInputFormatter(20),

            /// 下面的正则会影响自带的文字联想功能
            // FilteringTextInputFormatter.allow(RegExp("[&\\· a-zA-Z\u4E00-\u9FA5\\u0030-\\u0039➋-➒]")),
          ],
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          textInputAction: TextInputAction.search,
          cursorColor: Colors.purple,
          cursorRadius: Radius.circular(1),

          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent)),
            disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent)),
            border: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent)),

            /// 设置border、focusedBorder后即可实现文字居中和文字边缘裁剪，disabledBorder和enabledBorder最好也实现
            /// contentPadding.vertical会影响文字的边缘，修改后文字底部或顶部会被裁剪
            /// contentPadding.vertical还会影响光标，默认的光标高度过高(cursorHeight)，光标的顶部或者底部会被裁剪
            /// 所以光标的高度（cursorHeight）最好随字体设置，避免被裁剪（默认值就会被裁剪）
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            prefixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 36),
            // 文字居中
            prefixIcon: SizedBox(
              width: 38,
              height: 36,
              child: Container(
                padding: EdgeInsets.only(left: 10),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.search,
                  size: 24,
                  color: Color(0xFFC8C8C8),
                ),
              ),
            ),
            hintText: widget.placeholder ?? '搜索关键词',
            hintStyle: TextStyle(
              fontSize: 14,
              color: ColorUtil.dynamicColor(
                context: context,
                light: Color(0xFFA8A8A8),
                dark: Color(0xFF3D3D3D),
              ),
              // color: Color(0xFFC8C8C8),
            ),
            suffixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 36),
            suffixIcon: Visibility(
              visible: widget.controller.text.isNotEmpty,
              child: GestureDetector(
                onTap: _clear,
                child: Container(
                  color: Colors.transparent,
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Icon(
                      Icons.clear,
                      size: 24,
                      color: Color(0xFFC8C8C8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _textChanged(String text) {
    /// 刷新clearButton
    setState(() {});
    final query = text.trim();
    if (_lastText != query) {
      _lastText = query;
      widget.onChanged(query);
    } else {
      /// 超出长度之类的，输入的内容被截取，对于外部而言，内容是没有变的，所以这里要避免重复回调
      print('已拦截：$query');
    }
  }

  void _submitSearch(String value) {
    String query = value.trim();
    widget.controller.text = query;
    if (query.length != value.length) {
      _textChanged(query);
    }
    widget.onSubmitted(query);
  }

  void _clear() {
    widget.controller.clear();

    /// controller.clear()不会触发onChanged，需要手动调用
    _textChanged(widget.controller.text);

    /// 直接点击搜索历史，再清空，lastText是空的，不会再textChanged方法中回调出去，可以看print('拦截：');
    if (_lastText.isEmpty) {
      widget.onChanged(widget.controller.text);
    }
  }
}
