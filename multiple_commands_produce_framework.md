
这个文档对应主页提到的**framework重复建构**的问题，即[内嵌依赖的xcframework和pod依赖的第三方库重复冲突，新版Xcode编译失败](https://github.com/XiFengLang/flutter_notes#id-h4-04)，在这里整理了更详细的分析。

### 复现问题

**在Flutter Module & 插件库一侧**

> * mmkv_flutter插件依赖了MMKV，编译后会生成MMKV.framework、MMKVCore.framework
> * sentry_flutter插件依赖了Sentry，编译后会生成Sentry.framework
> * 网络缓存插件依赖了FMDB，编译后会生成FMDB.framework

**在iOS & Pods一侧**

> * Podfile中同样依赖了Sentry和MMKV，还有个私有库依赖了FMDB

我在Flutter Module中使用了一些基于原生库的插件层，编译后会生成相关的framework，按照远程依赖的构建方案(未设置黑名单)，导出的`xcframework`会集成到`FlutterPluginSDK`，`pod update`之后会直接以framework形式内嵌到项目中，在项目中展开`Pods  /   FlutterPluginSDK    /  frameworks`路径的文件夹即可看到相关的`xcframework`。但同样在`Pods`下面也能找到`FMDB、MMKV、...`这个重复的第三方库，不过看到的是源码文件。此时编译iOS项目，会遇到失败并提示错误`Multiple commands produce 'framework'`：

```C
Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/FMDB.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
2) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”


Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/MMKV.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
2) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”


Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/MMKVCore.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
2) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”


Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/Sentry.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
2) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
```

`Multiple commands produce '.framework'`这个问题我以前也遇到过，当时是因为`Today Target`和主工程的Pod都依赖了同一个库，编译时也报这个错误。当时找到的原因是因为Xcode10之后，使用了新的构建系统，会检测重复构建产物。关于Xcode10新的构建系统，即`New Build System`，可以看官方的介绍文档[Build System Release Notes for Xcode 10](https://developer.apple.com/documentation/xcode-release-notes/build-system-release-notes-for-xcode-10)，虽然没提到`Multiple commands produce`，但是Google搜到的说法也是因为新版Xcode默认使用`New Build System`，涉及到重复构建产物。

[Build System Release Notes for Xcode 10](https://developer.apple.com/documentation/xcode-release-notes/build-system-release-notes-for-xcode-10)有提到`duplicate output file`问题，说是在不同的编译阶段`build phases`可能会出现**重复输出文件**错误。

>Targets which have multiple asset catalogs that aren’t in the same build phase may produce an error regarding a “duplicate output file”. (39810274)
>
> Workaround: Ensure that all asset catalogs are processed by the same build phase in the target.

而根据错误信息，`Multiple commands produce`错误都出现在`script phase “[CP] Embed Pods Frameworks”`脚本执行阶段，这个`[CP] Embed Pods Frameworks`在Xcode的`Build Phases`中即可找到，涉及1个shell脚本和几个xcfilelist文件，

> * Pods-MyProj-frameworks.sh
> * Pods-MyProj-frameworks-Debug-input-files.xcfilelist
> * Pods-MyProj-frameworks-Debug-output-files.xcfilelist
> * Pods-MyProj-frameworks-Release-input-files.xcfilelist
> * Pods-MyProj-frameworks-Release-output-files.xcfilelist

![[CP] Embed Pods Frameworks](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210723121210.jpg)

`Pods-MyProj-frameworks.sh`脚本会把Pods中依赖的第三方库都通过调用`install_framework`函数逐个生成签名的framework，不过没找到`Multiple commands produce`字样，但是能找到2个关键的信息，一个是文件导入的路径，即调用`install_framework`时传入的路径参数，另一个是输出的路径，即下面的`destination`和`binary `。

```C
local destination="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
binary="${destination}/${basename}.framework/${basename}"
```

```C
  ...
  install_framework "${BUILT_PRODUCTS_DIR}/FMDB/FMDB.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/MMKV/MMKV.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/MMKVCore/MMKVCore.framework"
  ...
  install_framework "${PODS_XCFRAMEWORKS_BUILD_DIR}/Flutter/Flutter.framework"
  install_framework "${PODS_XCFRAMEWORKS_BUILD_DIR}/FMDB/FMDB.framework"
  install_framework "${PODS_XCFRAMEWORKS_BUILD_DIR}/MMKV/MMKV.framework"
  install_framework "${PODS_XCFRAMEWORKS_BUILD_DIR}/MMKVCore/MMKVCore.framework"
  install_framework "${PODS_XCFRAMEWORKS_BUILD_DIR}/mmkv_flutter/mmkv_flutter.framework"
```

再打开`Pods-MyProj-frameworks-Debug-input-files.xcfilelist` 和 `Pods-MyProj-frameworks-Debug-output-files.xcfilelist`文件，这2个文件分别声明了所有framework的输入路径和输出路径，跟`Pods-MyProj-frameworks.sh`脚本里面的用到的路径是一致的。从输入路径可以看到`FMDB.framework / MMKV.framework / ...`有不同的输入路径，在`Pods-MyProj-frameworks-Debug-input-files.xcfilelist`文件也可以看到，但是`destination`和`binary`计算的输出路径是相同的，这个结论在`Pods-MyProj-frameworks-Debug-output-files.xcfilelist`文件也能得到验证，存在重复的输出路径。结合前面提到的`Multiple commands produce`错误信息，基本能定位到问题所在了，在一个`Build Phase`重复生成framework导致的错误。

> `Multiple commands produce`错误都出现在`script phase “[CP] Embed Pods Frameworks”`脚本执行阶段

`Pods-MyProj-frameworks-Debug-output-files.xcfilelist`文件列出所有framework的输出路径，里面可以找到重复项，而正常情况是不会有重复项的。

```C
...
${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FMDB.framework
...
${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/MMKV.framework
...
${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FMDB.framework
${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/MMKV.framework
```

我目前尝试的可行方案有2种，其它的我没有试了。

* 1. 选择旧的构建系统，具体的操作路径： `Xcode  ->  File -> WorkSpace Settings -> Build System   ->   Legacy Build Sysyte`，可行，但不建议，因为这个构建系统已经标记要废弃掉。
* 2. 选择新的构建系统，但是要避免重复依赖，所以我从`FlutterPluginSDK`删除了重复依赖的`xcframework`。在[`构建脚本 flutter_build_script.sh`](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md)中加了黑名单，把需要删除的`xcframework `加到黑名单即可，这样编译的时候就不会重复framework。

