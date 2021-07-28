# iOS项目远程依赖Flutter Module产物 + Git Submodule + Shell脚本 （升级版 ）


回顾一下之前整理的方案，[远程依赖Flutter Module组件库编译产物（简单版）]中将`Flutter.xcframework`、其它`.xcframework`、podspec都放在一个Git仓库上，iOS端远程依赖这个Git，但是由于`Flutter.xcframework`文件太大，导致提交到仓库、从仓库拉取耗时过久。[在iOS项目远程依赖FlutterModule组件库代码（5个可行方案）]中，整理了5个可行的远程或中转依赖方案，我个人选择 [远程依赖Flutter Module组件库编译产物  方案0x05]来实现远程依赖，即经本地podspec中转远程zip & git混合依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec.git`管理，并基于这个方案实现了[远程依赖Flutter Module组件库构建脚本`flutter_build_script.sh`]。

但是这个方案在iOS这端，除了克隆本身iOS项目的Git外，还需要克隆`flutter_module_sdk_podspec.git`仓库，并且要求所有人的电脑上这2个本地git仓库的相对路径是一模一样的，不然容器出现Git冲突。这就需要所有人都遵守这个约定/规则，在本机上手动克隆2个仓库，只要大家保持本机上2个git仓库的相对路径一致，就没什么问题。但是到了CI构建的机器上，就需要用脚本来实现这个规则，流程会显得有点繁杂。**所以面临一个问题，就是怎么把`flutter_module_sdk_podspec.git`跟`iOS.git`形成强关系的绑定，而不是靠不稳定的人为约定去保持弱关系的关联。** 碰巧看到了一个大佬整理的[《Git中submodule的使用》](https://zhuanlan.zhihu.com/p/87053283)，详细介绍了`git submodule`，刚好能解决前面的问题，将`flutter_module_sdk_podspec.git` "内嵌"到`iOS.git`里面，形成强关系的绑定。

所以我又基于 [远程依赖Flutter Module组件库编译产物  方案0x05] 增加了`git submodule`，从Flutter编译到产物分发的流程没有变动（即步骤1-8），只是改了iOS一侧的流程，详细的介绍如下。

	插一句：我介绍的例子都有提到2个Git，即flutter_app_sdk.git和flutter_plugin_sdk.git，其实可以整合成一个Git存放xcframework。  
	拆不拆都可以，流程和思路是一样的，我个人建议不拆。

**Flutter编译 -> 产物分发**

* 1.建立Git仓库`flutter_module_sdk_podspec`、`flutter_app_sdk.git`和`flutter_plugin_sdk.git`备用；
* 2.编译出 Flutter.podspec 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework；

```C
  flutter build ios-framework --cocoapods --xcframework --no-universal --output=../flutter_build/Frameworks/
```

* 3.将`App.framework`移到`flutter_app_sdk.git`本地仓库根目录；`FlutterPluginRegistrant.xcframework和其它第三方库`移到`flutter_plugin_sdk.git`本地仓库根目录；
* 4.打相同的版本标签，分别提交到远程仓库，即`flutter_app_sdk.git`和`flutter_plugin_sdk.git`
* 5.在`flutter_module_sdk_podspec`根目录创建`FlutterAppSDK.podspec`和`FlutterPluginSDK.podspec`文件，`s.source`设置成`:git => 'http://gitlab.private.cn/flutter/flutter_..._sdk.git', :tag => '..version'`；
* 6.将`Flutter.podspec`移到`flutter_module_sdk_podspec`根目录，因为有现成的zip资源，就不需要我们上传了，podspec文件也不用改，直接用就行；
* 7.清空删除`flutter_build`，临时中转站，完事就没用了；
* 8.在`flutter_module_sdk_podspec.git`执行`commit & push`，不用打标签；     

> `flutter_module_sdk_podspec.git仓库目录：`
>> * Flutter.podspec
>> * FlutterAppSDK.podspec
>> * FlutterPluginSDK.podspec

**iOS侧导入依赖**

这里我们使用`git submodule` 将`flutter_module_sdk_podspec.git` "内嵌"到`iOS.git`中，这样就能保住每台电脑上这2个git的相对路径是始终一致的，不用担心人为因素导致路径不一致的问题。之后更新子模块 等同于 更新依赖的`flutter_module_sdk_podspec.git`，这里又分3种情况，1.首次添加子模块、2.新同事首次克隆ios.git、3.拉取更新子模块。

* 9.1.首次导入`submodule`需要在`iOS.git`本地路径下添加`git submodule`  

```C
  cd $HOME/Desktop/workspace/ios.git
  git submodule add 'http://gitlab.private.cn/flutter_module_sdk_podspec.git'
```

* 9.2.新同事首次克隆`iOS.git`，可能会遇到2种情况。

> 一：普通常规的克隆指令，可能指定分支，但没有拉取`submodule`子模块，就需要额外执行指令去递归拉取更新子模块。

```C
  git clone -b a_branch http://gitlab.private.cn/ios/ios.git 
  git submodule update --init --recursive
```

> 二：克隆的同时指定递归拉取更新子模块，需要在指令中加上`--recurse-submodules`

```C
  git clone -b a_branch http://gitlab.private.cn/ios/ios.git --recurse-submodules
```

* 9.3.`flutter_module_sdk_podspec.git`发布更新后，需要在`ios.git`中更新本地子模块，加上`foreach`可以帮助我们遍历所有的子模块。

```C
  git submodule foreach 'git pull origin master'
```

* 9.4.前面3种情况，如果更新了子模块，在`ios.git`都会产生`modify`，所以都需要提交更新到`ios.git`。

```C
  git status
  # 下面2步可以在SourceTree之类的客户端操作，可以看到 submodule的
  git add -A && git commit -m "add or modify submodule flutter_module_sdk_podspec.git"
  git push origin --tags && git push origin master 
```

* 10.在Podfile中添加本地依赖，`pod update or install`，即可运行代码；

```C
  pod 'Flutter', :podspec => './flutter_module_sdk_podspec/Flutter.podspec'
  pod 'FlutterAppSDK', :podspec => './flutter_module_sdk_podspec/FlutterAppSDK.podspec'
  pod 'FlutterPluginSDK', :podspec => './flutter_module_sdk_podspec/FlutterPluginSDK.podspec'
```

------

至此`iOS远程Flutter组件库`的尝试就结束了(2021.07.28)，前前后后花了近2周时间，也找到了个人觉得OK的方案。加上构建脚本(传送门🚪[远程依赖Flutter Module组件库构建脚本`flutter_build_script.sh`])，结合起来用能节省很多时间。


--------
[远程依赖Flutter Module组件库编译产物（简单版）]:https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-4
[在iOS项目远程依赖FlutterModule组件库代码（5个可行方案）]:https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md
[远程依赖Flutter Module组件库构建脚本`flutter_build_script.sh`]:https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md
[远程依赖Flutter Module组件库编译产物  方案0x05]:https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md#id-h3-05
