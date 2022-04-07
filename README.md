<span id="go_top"> </span>

**2022年临时补充：**   
可以把构建产物的中Flutter.podspec文件放到文件服务器上，这样就可以远程依赖Flutter.xcframework；其它的xcframework产物都放一个git仓库(对应一个podspec/组件库)管理，每次构建打个tag，iOS侧同样是远程依赖这个组件库。


> 		目录
>  
> * [在iOS项目依赖FlutterModule组件代码](#id-h2-01)
> 	* [iOS项目依赖Flutter Module方案汇总](#id-h4-01)
> 	* [构建脚本](#id-h4-02)
> 	* [相关脚本](#id-h4-03)
> 	* [内嵌依赖的xcframework和pod依赖的第三方库重复冲突，新版Xcode编译失败](#id-h4-04)
> * [flutter_boost混合开发挖坑记录](#id-h2-02)
> 	* [问题1.首次进入Flutter页面出现空白](#id-h4-21)
> 	* [问题2.在原生页面切换深浅色后进入Flutter页面会先渲染上一次的配色模式](#id-h4-22)
> 	* [问题3. 自定义Flutter(Boost)容器后，Flutter页面退出后没有调用dispose，出现内存泄漏](#id-h4-23)
> 

这个仓库主要有2部分，整理了如何在iOS项目导入FlutterModule组件代码，以及整理开发过程中遇到的一些问题和对应的解决方案。

<h2 id="id-h2-01">在iOS项目依赖FlutterModule组件代码</h2>


依赖Flutter组件代码的分为本地依赖、远程依赖2种。下面介绍的前3种是本地依赖，同时也是官方推荐的方法，在开发文档[Adding Flutter to iOS
](https://flutter.dev/docs/development/add-to-app/ios/project-setup)有详细介绍。简单的说本地依赖就是直接依赖本机的编译产物，需要每个开发人员都安装Flutter开发环境，同时编译产物会导出到FlutterModule或者iOS项目的Git目录下，依赖指向的也是相对路径，加上Flutter版本不一致就容易造成Git冲突。远程依赖则是将Flutter编译得到的相关framework都推到云端git，在iOS项目通过CocoaPods远程依赖，也就不用要求所有人都安装Flutter开发环境，Flutter Module 、Flutter编译产物、Native 都有独立的Git，某端的更改不会直接影响到另一端。

<h4 id="id-h4-01">iOS项目依赖Flutter Module方案汇总</h4>

* [1.基于CocoaPods和podhelper.rb脚本本地依赖FlutterModule](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-1)
* [2.编译FlutterModule，手动添加.xcframwork到iOS项目中](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-2)
* [3.编译FlutterModule，远程依赖Flutter.xcframework，本地依赖其余.xcframwork](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-3)
* [4.远程依赖Flutter Module组件库编译产物（简单版）](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-4)
* [5.在iOS项目远程依赖FlutterModule组件库代码（5个可行方案）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md)
* [6.远程依赖Flutter Module产物 + Git Submodule + Shell脚本 （升级版 ）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_remotely_upgrades.md)


<h4 id="id-h4-02">构建脚本</h4>

* [远程依赖Flutter Module组件库构建脚本`flutter_build_script.sh`](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md)

脚本基于[远程依赖Flutter Module组件库编译产物  方案0x05](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md#id-h3-05)实现，但同样适用于[远程依赖Flutter Module组件库编译产物（升级版 ）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_remotely_upgrades.md)。  
实现了Futter编译到产物分拣上传的功能，其它的方案也可以参考这个脚本。


<h4 id="id-h4-03">相关脚本</h4>

将Flutter组件库添加到iOS项目中，流程中会涉及到2个关键脚本，一个ruby脚本`podhelper.rb`, 另一个是shell脚本`xcode_backend.sh`，我看的时候加了一些注解。

* [podhelper.rb 脚本注解](https://github.com/XiFengLang/flutter_notes/blob/main/podhelper.rb)，此脚本主要的功能是导入Flutter、App、FlutterPluginRegistrant和其它第三方库的本地依赖，另外设置一个Build Phases执行脚本，在编译Xcode项目时执行[xcode_backend.sh](https://github.com/XiFengLang/flutter_notes/blob/main/xcode_backend.sh)脚本。
* [xcode_backend.sh 脚本注解](https://github.com/XiFengLang/flutter_notes/blob/main/xcode_backend.sh)，此脚本的主要功能是根据编译模式和CPU架构 编译/合成 Flutter相关的framework动态库。
* 待研究：`flutter build ios-framework `对应的源码，路径是`flutter/packages/flutter_tools/lib/src/commands/build_ios_framework.dart`

<h4 id="id-h4-04">内嵌依赖的xcframework和pod依赖的第三方库重复冲突，新版Xcode编译失败</h4>

* [内嵌依赖的xcframework和pod依赖的第三方库重复冲突，新版Xcode编译失败](https://github.com/XiFengLang/flutter_notes/blob/main/multiple_commands_produce_framework.md)

`FlutterPluginSDK`里面的`xcframework`和iOS项目原本pod依赖的第三方库重复依赖，编译失败，提示：`Multiple commands produce '.framework'`。比如Flutter侧依赖的插件依赖了FMDB，编译Flutter后就导出了`FMDB.scframework`，按照远程依赖的构建方案，`FMDB.xcframework`会集成到`FlutterPluginSDK`里，同时iOS项目种也有其它的组件库依赖了FMDB。应该是在`“[CP] Embed Pods Frameworks”`编译阶段也导出了`内嵌的FMDB.frameowork`，跟`FlutterPluginSDK`里面的framework重复了，由于新版Xcode编译时默认使用了`New Build System`，编一阶段frameowrk重建时会抛出异常[multiple commands produce framework](https://github.com/XiFengLang/flutter_notes/blob/main/multiple_commands_produce_framework.md)。

```C
Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/FMDB.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”
2) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”

Multiple commands produce '/Users/user/Library/Developer/Xcode/DerivedData/MyProj-flazyqyatfvrvsgcoofvwrizuvot/Build/Products/Debug-iphoneos/MyProj.app/Frameworks/MMKV.framework':
1) That command depends on command in Target 'MyProj' (project 'MyProj'): script phase “[CP] Embed Pods Frameworks”

Multiple commands produce ...

```

这个问题我以前也遇到过，因为`Today Target`和主工程的Pod都依赖了同一个库，编译时也报这个错误。[Build System Release Notes for Xcode 10](https://developer.apple.com/documentation/xcode-release-notes/build-system-release-notes-for-xcode-10) 有相关的介绍。

我目前尝试的可行方案有2种，其它的我没有试了。

* 1. 选择旧的构建系统，具体的操作路径： `Xcode  ->  File -> WorkSpace Settings -> Build System   ->   Legacy Build Sysyte`
* 2. 新的构建系统，但是避免重复依赖，从`FlutterPluginSDK`删除掉重复依赖的`xcframework`。我已经在[`构建脚本 flutter_build_script.sh`](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md)中加了黑名单，把需要删除的`xcframework `加到黑名单即可。



<h2 id="id-h2-02">flutter_boost混合开发挖坑记录</h2>

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



<h4 id="id-h4-21">问题1.首次进入Flutter页面出现空白</h4>

首次进入Flutter页面，由于Flutter预热时会出现短暂的空白，[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_dark_mode.md)

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/ezgif.com-gif-maker.webp" width="50%" height="50%" alt="问题图"/><br/>


<h4 id="id-h4-22">问题2.在原生页面切换深浅色后进入Flutter页面会先渲染上一次的配色模式</h4>


Flutter适配深浅色后在切换深浅色模式时出现渲染异常，[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_dark_mode.md)

<h4 id="id-h4-23">问题3. 自定义Flutter(Boost)容器后，Flutter页面退出后没有调用dispose，出现内存泄漏</h4>

由于我在`FBFlutterViewContainer `基础上自定义了Flutter控制器容器，导致在退出页面时没有触发`notifyWillDealloc`，致使Flutter页面没有得到释放。[点击查看细节和解决方案](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_boost_memory_leak.md)




[回到顶部🔝](#go_top)




