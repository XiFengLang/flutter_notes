[TOC]

这个仓库主要有2部分，整理了如何在iOS项目导入FlutterModule组件代码，以及整理开发过程中遇到的一些问题和对应的解决方案。

## 在iOS项目依赖FlutterModule组件代码


依赖Flutter组件代码的分为本地依赖、远程依赖2种。下面介绍的前3种是本地依赖，同时也是官方推荐的方法，在开发文档[Adding Flutter to iOS
](https://flutter.dev/docs/development/add-to-app/ios/project-setup)有详细介绍。简单的说本地依赖就是直接依赖本机的编译产物，需要每个开发人员都安装Flutter开发环境，同时编译产物会导出到FlutterModule或者iOS项目的Git目录下，依赖指向的也是相对路径，加上Flutter版本不一致就容易造成Git冲突。远程依赖则是将Flutter编译得到的相关framework都推到云端git，在iOS项目通过CocoaPods远程依赖，也就不用要求所有人都安装Flutter开发环境，Flutter Module 、Flutter编译产物、Native 都有独立的Git，某端的更改不会直接影响到另一端。

**iOS项目依赖Flutter module：**

* [1.基于CocoaPods和podhelper.rb脚本本地依赖FlutterModule](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#1%E5%9F%BA%E4%BA%8Ecocoapods%E6%9C%AC%E5%9C%B0%E4%BE%9D%E8%B5%96fluttermodule)
* [2.编译Flutter Module得到多个`*.xcframwork`，手动添加到iOS项目中](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#2%E5%B0%86flutter%E7%BC%96%E8%AF%91%E6%88%90xcframwork%E6%89%8B%E5%8A%A8%E6%B7%BB%E5%8A%A0%E5%88%B0ios%E9%A1%B9%E7%9B%AE%E4%B8%AD)
* [3.编译Flutter Module得到多个`*.xcframwork`，使用CocoaPods远程依赖`Flutter.xcframework`](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#3%E5%B0%86flutter%E7%BC%96%E8%AF%91%E6%88%90xcframwork%E4%BD%BF%E7%94%A8cocoapods%E4%BE%9D%E8%B5%96%E5%AF%BC%E5%85%A5flutterxcframework)
* [4.远程依赖Flutter Module组件库编译产物（简单版）](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#4%E8%BF%9C%E7%A8%8B%E4%BE%9D%E8%B5%96flutter%E7%BC%96%E8%AF%91%E4%BA%A7%E7%89%A9)
* [5.远程依赖Flutter Module组件库编译产物（多方案版）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md)

**构建脚本：**

基于[远程依赖Flutter Module组件库编译产物（多方案版） 方案0x05 ](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md#0x05-%E5%8F%AF%E8%A1%8C----%E5%85%A8%E9%83%A8%E7%BB%8F%E6%9C%AC%E5%9C%B0podspec%E4%B8%AD%E8%BD%AC%E8%BF%9C%E7%A8%8Bzip--git%E6%B7%B7%E5%90%88%E4%BE%9D%E8%B5%96podspec%E6%96%87%E4%BB%B6%E7%BB%9F%E4%B8%80%E6%94%BE%E5%88%B0%E7%8B%AC%E7%AB%8B%E4%BB%93%E5%BA%93flutter_module_sdk_podspec%E7%AE%A1%E7%90%86)写的脚本也已经完成，实现了Futter编译到产物分拣上传的功能，其它的方案也可以参考这个脚本，[远程依赖Flutter Module组件库构建脚本](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md)

**相关脚本：**

另外将Flutter组件库添加到iOS项目中，流程中会涉及到2个关键脚本，一个ruby脚本`podhelper.rb`, 另一个是shell脚本`xcode_backend.sh`，我看的时候加了一些注解。

* [podhelper.rb 注解](https://github.com/XiFengLang/flutter_notes/blob/main/podhelper.rb)，此脚本主要的功能是导入Flutter、App、FlutterPluginRegistrant和其它第三方库的本地依赖，另外设置一个Build Phases执行脚本，在编译Xcode项目时执行[xcode_backend.sh](https://github.com/XiFengLang/flutter_notes/blob/main/xcode_backend.sh)脚本。
* [xcode_backend.sh 注解](https://github.com/XiFengLang/flutter_notes/blob/main/xcode_backend.sh)，此脚本的主要功能是根据编译模式和CPU架构 编译/合成 Flutter相关的framework动态库。
* 待研究：`flutter build ios-framework `对应的源码，路径是`flutter/packages/flutter_tools/lib/src/commands/build_ios_framework.dart`





## flutter_boost混合开发挖坑记录

我们的项目使用`flutter_boost`来实现iOS & Flutter混合项目开发，目前也已经适配到`flutter_boost v3.0.0`。`FlutterBoost`在`3.0.0`新增一个Flutter控制器容器，但我们项目有统一的控制器基类，为了统一控制器页面的某些特性和接口功能， 我在`FlutterBoost`的容器上又封装了一层控制器容器，导致在开发过程遇到了深浅色适配和内存泄漏的问题。

深浅色适配和`Push/Present`进入Flutter页面是我在项目开发中真实用到的场景，在Demo中我还原了这2个场景及遇到的问题，给原生页面和Flutter页面都适配了深浅色，其中的搜索页`SearchPage`就是Flutter页面，而APP的主页就是原生页面（可以切换深浅色），另外进入`SearchPage`采用了`Push、Present` 2种转场方式，以对比效果。


另外我在`FBFlutterViewContainer `基础上自定义一个Flutter控制器容器，最后所有的Flutter页面都由`FlutterModuleViewController`承载，而`FBFlutterViewContainer`则添加在容器`FlutterModuleViewController`上，但是2者不是继承关系，而是父子控制器的关系。之所以这么做是为了统一控制器页面的某些特性和接口功能。


```C
    FlutterModuleViewController.m

    self.flutterContainer.view.frame = self.view.bounds;
    [self.view insertSubview:self.flutterContainer.view atIndex:0];
    [self addChildViewController:self.flutterContainer];
```

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/flutter_page_container.png"  alt="Flutter控制器容器"/><br/>



### 问题1.首次进入Flutter页面出现空白

首次进入Flutter页面，由于Flutter预热时会出现短暂的空白，[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_dark_mode.md)

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/ezgif.com-gif-maker.webp" width="50%" height="50%" alt="问题图"/><br/>

### 问题2.在原生页面切换深浅色后进入Flutter页面会先渲染上一次的配色模式

Flutter适配深浅色后在切换深浅色模式时出现渲染异常，[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_dark_mode.md)


### 问题3. 自定义Flutter(Boost)容器后，Flutter页面退出后没有调用dispose，出现内存泄漏

由于我在`FBFlutterViewContainer `基础上自定义了Flutter控制器容器，导致在退出页面时没有触发`notifyWillDealloc`，致使Flutter页面没有得到释放。[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_memory_leak.md)







