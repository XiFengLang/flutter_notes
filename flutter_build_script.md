# iOS远程依赖flutter module构建脚本

构建脚本是基于[远程依赖Flutter Module组件库编译产物  方案0x05](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md#id-h3-05)实现的，但同样适用于[远程依赖Flutter Module组件库编译产物（升级版 ）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_remotely_upgrades.md)。  

脚本内容详见[`flutter_build_script.sh 文件`](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.sh)  


## 实现功能

- [x] 校验git是否有未提交的更新
- [x] git commit, git tag ,git push等一系列git操作
- [x] 校验.ios/Runner.xcworkspace
- [x] 编译Flutter module，导出framework
- [ ] 选择debug / profile / release 编译模式
- [x] 版本号自增 或 手动输入
- [x] 修改podspec版本号
- [x] 钉钉通知
- [x] 杂七杂八的结果校验
- [x] xcframework黑名单，过滤掉重复依赖的framwork，用来解决问题[内嵌依赖的xcframework和pod依赖的第三方库重复冲突，新版Xcode编译失败](https://github.com/XiFengLang/flutter_notes/blob/main/multiple_commands_produce_framework.md)


## 使用

1.修改这几个本地仓库的路径

```C
readonly workspace_root_path="$HOME/Desktop/workspace"
readonly flutter_module_path="${workspace_root_path}/flutter_notes/flutter_module"
readonly flutter_build_output_path="${workspace_root_path}/futter_build_tmp"
readonly flutter_module_sdk_podspec_path="${workspace_root_path}/flutter_module_sdk_podspec"
readonly flutter_app_sdk_path="${workspace_root_path}/flutter_app_sdk"
readonly flutter_plugin_sdk_path="${workspace_root_path}/flutter_plugin_sdk"

readonly app_sdk_podspec_path="$flutter_module_sdk_podspec_path/FlutterAppSDK.podspec"
readonly plugin_sdk_podspec_path="$flutter_module_sdk_podspec_path/FlutterPluginSDK.podspec"
```

2.修改黑名单，不需要黑名单就清空

```C
blacklist=(
"FMDB.xcframework"
"MMKV.xcframework"
"MMKVCore.xcframework"
"Sentry.xcframework"
)
```

3.执行脚本，按提示输入即可


## 参考

> * [linux shell 实现自增版本号](https://github.com/zedxpp/PPPrivatePodPushScript/blob/master/README.md)
> * [PPPrivatePodPushScript iOS私有库发布脚本](https://github.com/zedxpp/PPPrivatePodPushScript)







