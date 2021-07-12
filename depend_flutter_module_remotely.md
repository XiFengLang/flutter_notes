在iOS项目远程依赖FlutterModule组件库代码

在上一篇 [远程依赖Flutter Module组件库编译产物（简单版）](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#4%E8%BF%9C%E7%A8%8B%E4%BE%9D%E8%B5%96flutter%E7%BC%96%E8%AF%91%E4%BA%A7%E7%89%A9) 中实现了简单可用的远程依赖，但是缺点也很明显，`Flutter.framework`太大，有480M，`pod update / clone git` 很慢，而且上传这么大的文件到github是不行的，只能选择内部的gitlab。

在[使用CocoaPods远程依赖`Flutter.xcframework`](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#3%E5%B0%86flutter%E7%BC%96%E8%AF%91%E6%88%90xcframwork%E4%BD%BF%E7%94%A8cocoapods%E4%BE%9D%E8%B5%96%E5%AF%BC%E5%85%A5flutterxcframework)中有提到，`Flutter.xcframework`可以通过中转远程依赖服务器的zip文件，而且`Flutter.xcframework`压缩后不到200M，有条件的话使用CDN加速或者放内网服务器，相比直接clone 源文件git，下载zip就快了不少。所以我的思路也是从这入手，尝试了全部远程依赖zip文件、中转后远程依赖`Flutter.xcframework.zip`文件+Git依赖其它`framework`。另外我把`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`拆分到2个仓库，分别为`flutter_app_sdk.git`和`flutter_module_sdk.git`，因为我想着主要改动的是`App.framework`，其它的framework改动的较少。但实际操作上每次改动后提交的版本号都一样，给git打tag也一样，所以拆不拆分都一样。

> 如果选择拆分部分framework到独立的git，那就需要建立相应的podspec文件，并且把这两个文件放在同一个git


下面几种方案是我最近测试过的，有可行方案也有行不通的。

### 0x01: 可行 -- 本地Flutter.podspec+远程zip，AppSDK和PluginSDK远程依赖Git

还是先编译。不熟悉流程的可以先看[远程依赖Flutter Module组件库编译产物（简单版）](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#4%E8%BF%9C%E7%A8%8B%E4%BE%9D%E8%B5%96flutter%E7%BC%96%E8%AF%91%E4%BA%A7%E7%89%A9)

```C
flutter build ios-framework --cocoapods --xcframework --no-universal --output=../flutter_build/Frameworks/
```

编译后的目录结构如下，**为了简化测试，后面的操作我都是用`flutter_build/Frameworks/Release`里面的编译产物**。

```C
├── andriod_module
│   ├── ...
├── flutter_build
│   ├── Frameworks
│   │   ├── Debug
│   │   ├── Profile
│   │   ├── Release
├── flutter_module
│   ├── README.md
│   ├── build
│   ├── flutter_module.iml
│   ├── flutter_module_android.iml
│   ├── lib
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   └── test
├──ios_module
    ├── FlutterBoostPro
    ├── FlutterBoostPro.xcodeproj
    ├── FlutterBoostPro.xcworkspace
    ├── Podfile
    ├── Podfile.lock
    └── Pods
```

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210712171749.jpg)

将`App.framework`移到`flutter_app_sdk.git`所在目录下，`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`则移到`flutter_module_sdk.git`。**前面说了，拆不拆都一样，放一个Git仓库也可以，流程和思路是一样的。**以`flutter_app_sdk.git`为例，目录里面还需要建一个`FlutterAppSDK.podspec`。

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210712172151.jpg)

```C
Pod::Spec.new do |s|
  s.name                  = 'FlutterAppSDK'
  s.version               = '1.0.1'
  s.homepage              = 'https://github.com'
  s.source                = { :git => 'http://gitlab.private.cn/flutter/flutter_app_sdk.git', :tag => "#{s.version}" }
  s.platform              = :ios, '8.0'
  s.requires_arc          = true
  s.vendored_frameworks   = '*.xcframework'
end
```

然后将`flutter_app_sdk.git`和`flutter_module_sdk.git`打上版本标签，推到Git云端。而`Flutter.framework`则是本地依赖中转到远程服务器的zip文件，所以不需要做什么操作，直接用编译出来的`Flutter.podspec`文件即可。

最后在iOS项目的Podfile中添加依赖，最后执行`pod update`即可。

```C
    pod 'Flutter', :podspec => '../flutter_build/Frameworks/Release/Flutter.podspec'
    pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_app_sdk.git', :tag => '1.0.1'
    pod 'FlutterPluginSDK', :git => 'http://gitlab.private.cn/flutter/flutter_module_sdk.git', :tag => '1.0.1'
```

优点：这种方案利用了现成的`Flutter.framework`远程压缩文件资源，不需要我们压缩文件和上传zip文件，直接用链接即可（但是我不确定要不要翻墙）；`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`则是依赖了内部私有的Git，文件不大，方便管理；不需要其它的开发人员也安装Flutter开发环境，降低了技术选择的成本；
缺点：`flutter_build/Frameworks`会侵入到iOS项目中，Git管理上容易出现冲突，而且`flutter_build/Frameworks`在项目中会显得有点多余。


### 0x02: 可行 -- FlutterSDK、AppSDK和PluginSDK都远程依赖Git

这个方案和[使用CocoaPods远程依赖`Flutter.xcframework`](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#3%E5%B0%86flutter%E7%BC%96%E8%AF%91%E6%88%90xcframwork%E4%BD%BF%E7%94%A8cocoapods%E4%BE%9D%E8%B5%96%E5%AF%BC%E5%85%A5flutterxcframework)思路是一样的，就把`Flutter.xcframework`也放到私有Git（flutter_sdk.git）上去。只是这里我选择给`Flutter.xcframework`单独建个仓库，而不是把所有的framework都放一个仓库。操作上同**`0x01`**，`flutter_sdk.git`里面包含了`Flutter.podspec`和`Flutter.xcframework`，需要注意的是`spec.source`依赖私有git，而不是远程zip文件。`Flutter.xcframework`可以从**`0x01`**的远程zip文件下载得到，也可以通过下面的指令编译得到。为了省事，我选择下载zip文件。

```C
flutter build ios-framework --xcframework --no-universal --output=../flutter_build/Frameworks/
```

`Flutter.podspec`的主要结构如下：

```C
Pod::Spec.new do |s|
  s.name                  = 'Flutter'
  s.version               = '1.0.1'
  s.homepage              = 'https://github.com'
  s.source                = { :git => 'http://gitlab.private.cn/flutter/flutter_sdk.git', :tag => "#{s.version}" }
  s.platform              = :ios, '8.0'
  s.requires_arc          = true
  s.vendored_frameworks   = '*.xcframework'
end
```

同**`0x01`**，需要将`flutter_sdk.git`、`flutter_app_sdk.git`和`flutter_module_sdk.git`打上版本标签，推到Git云端。

最后在iOS项目的Podfile中添加依赖，最后执行`pod update`即可。

```C
    pod 'Flutter', :git => 'http://gitlab.private.cn/flutter/flutter_sdk.git', :tag => '1.0.1'
    pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_app_sdk.git', :tag => '1.0.1'
    pod 'FlutterPluginSDK', :git => 'http://gitlab.private.cn/flutter/flutter_module_sdk.git', :tag => '1.0.1'
```

优点：`Flutter.framework`、`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`统一使用了内部私有Git，iOS端在依赖Flutter相关SDK的Git时，只需要改版本号(tag)即可；不需要其它的开发人员也安装Flutter开发环境，降低了技术选择的成本；
缺点：`Flutter.framework`文件巨大，将近480M，克隆下载慢，如果Git限制了单个文件大小，则可能push失败。


