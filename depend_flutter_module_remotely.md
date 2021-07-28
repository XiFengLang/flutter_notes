# 在iOS项目远程依赖FlutterModule组件库代码


<span id="go_top"> </span>
> 		目录
>  
> * [0x01: [可行] 本地Flutter.podspec+远程zip，AppSDK和PluginSDK则是远程依赖Git](#id-h3-01)
> * [0x02: [可行] FlutterSDK、AppSDK和PluginSDK都远程依赖Git](#id-h3-02)
> * [0x03: [可行] 全部经本地podspec中转远程zip依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理](#id-h3-03)
> * [0x04: [可行] 全部经本地podspec中转远程Git依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理](#id-h3-04)
> * [0x05: [可行、推荐] 经本地podspec中转远程zip & git混合依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理](#id-h3-05)
> * [0x06: [行不通] 基于远程podspec做中转，依赖远程zip 或 git资源](#id-h3-06)
> * [0x07: [行不通] 依赖远程服务器上的podspec，通过:http 指向同服务器的zip文件](#id-h3-07)
> * [0x08: [最新推荐] 远程依赖FlutterModule编译产物（升级版）](#id-h3-08)

-----


在上一篇[《在iOS项目中依赖Flutter组件代码》] 的章节 [4.远程依赖Flutter Module组件库编译产物（简单版）]中实现了简单可用的远程依赖，但是缺点也很明显，`Flutter.framework`文件太大，新版Flutter编译出来有480M，`pod update / clone git` 很慢，而且上传这么大的文件到github是被限制的，只能选择内部的gitlab。

而在章节[3.编译FlutterModule，远程依赖Flutter.xcframework，本地依赖其余.xcframwork]中有提到，`Flutter.xcframework`可以通过本地`podspec`中转依赖云端服务器的zip文件，而且`Flutter.xcframework`压缩后不到200M，有条件的话使用CDN加速或者放内网服务器，相比直接clone 源文件git，下载zip就快了不少。所以我的思路也是从这入手，尝试了全部远程依赖zip文件、本地`podspec`中转远程依赖zip文件和本地`podspec`中转依赖Git等多种方案。

另外我把`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`拆分到2个仓库，分别为`flutter_app_sdk.git`和`flutter_plugin_sdk.git`，分别对应`AppSDK`和`PluginSDK `，因为我最初想着主要改动的是`App.framework`，其它的framework改动的较少，就拆成2个SDK/git仓库。**所以我写的例子都是拆分的，但实际操作发现每次改动后都要一起更新Git，版本号和tag都是一样的，拆了还需要多做些操作，所以最好不拆，放一起就好了。**

> 如果选择拆分部分framework到独立的git，那就需要建立相应的podspec文件，并且把framework和podspec放在同一个git目录下。


-----

**下面几种远程依赖方案是我最近测试过的，有可行方案也有行不通的。** 远程依赖方案都是基于本地依赖实现的，建议先浏览[《在iOS项目中依赖Flutter组件代码》] 熟悉下大致的流程和思路。  
另外为了简化测试，所有方案都是将编译产物都导出到`flutter_build`路径下，并且都是用`flutter_build/Frameworks/Release`里面的编译产物。
	

<h3 id="id-h3-01">0x01: [可行] 本地Flutter.podspec+远程zip，AppSDK和PluginSDK则是远程依赖Git</h3>

* 1.编译

```C
# 编译出 Flutter.podspec 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework

flutter build ios-framework --cocoapods --xcframework --no-universal --output=../flutter_build/Frameworks/
```

编译后的目录结构如下：


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

* 2.将`App.framework`移到`flutter_app_sdk.git`本地目录下，`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`则移到`flutter_plugin_sdk.git`本地目录下。**前面说了，拆不拆都可以，放一个Git仓库最好，流程和思路是一样的。**  
下面以`flutter_app_sdk.git`为例，目录里面还需要建一个`FlutterAppSDK.podspec`文件。

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

* 3.给`flutter_app_sdk.git`和`flutter_plugin_sdk.git`打上版本标签，推到远程Git仓库。而`Flutter.framework`则是本地依赖中转到远程服务器的zip文件，所以不需要做什么操作，直接用编译出来的`Flutter.podspec`文件即可。

* 4.最后在iOS项目的Podfile中添加依赖，最后执行`pod update`即可。

```C
    pod 'Flutter', :podspec => '../flutter_build/Frameworks/Release/Flutter.podspec'
    pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_app_sdk.git', :tag => '1.0.1'
    pod 'FlutterPluginSDK', :git => 'http://gitlab.private.cn/flutter/flutter_plugin_sdk.git', :tag => '1.0.1'
```

**优点**:这种方案利用了现成的`Flutter.framework`远程压缩文件，不需要我们压缩文件和上传zip文件，直接用链接即可（但我不确定要不要翻墙）；`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`则是依赖了内部私有的Git，文件不大，方便管理；不需要所有开发人员都安装Flutter开发环境，降低了技术选择的成本；  
**缺点**:`flutter_build/Frameworks`会侵入到iOS项目中，Git管理上容易出现冲突，而且`flutter_build/Frameworks`在项目中会显得有点多余。


<h3 id="id-h3-02">0x02: [可行] FlutterSDK、AppSDK和PluginSDK都远程依赖Git</h3>

这个方案和[4.远程依赖Flutter Module组件库编译产物（简单版）]思路是一样的，就把`Flutter.xcframework`也放到私有Git（flutter_sdk.git）上去。只是这里我选择给`Flutter.xcframework`单独建个仓库，而不是把所有的framework都放一个仓库。思路上同[`方案0x01`](#id-h3-01)，建立`flutter_app_sdk.git`、`flutter_plugin_sdk.git`和`flutter_sdk.git` 3个仓库，`flutter_sdk.git`里面包含了`Flutter.podspec`和`Flutter.xcframework`。需要注意的是`Flutter.podspec`里面`spec.source`依赖私有git，而不是远程zip文件。

* 1.编译

```C
# 编译出 Flutter.podspec 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework

flutter build ios-framework --cocoapods --xcframework --no-universal --output=../flutter_build/Frameworks/
```

`Flutter.xcframework`可以从上面指令编译导出的`Flutter.podspec`依赖的远程zip文件下载得到，也可以通过下面的指令编译得到。为了省事，我选择下载zip文件。

```C
# 编译出 Flutter.xcframework 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework

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

* 2.同[`方案0x01`](#id-h3-01)，需要将`flutter_sdk.git`、`flutter_app_sdk.git`和`flutter_plugin_sdk.git`打上版本标签，推到各自的Git仓库。

* 3.最后在iOS项目的Podfile中添加依赖，最后执行`pod update`即可。

```C
    pod 'Flutter', :git => 'http://gitlab.private.cn/flutter/flutter_sdk.git', :tag => '1.0.1'
    pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_app_sdk.git', :tag => '1.0.1'
    pod 'FlutterPluginSDK', :git => 'http://gitlab.private.cn/flutter/flutter_plugin_sdk.git', :tag => '1.0.1'
```

* 4.没问题之后就可以删除`flutter_build`里面的编译产物，`flutter_build`现在是临时文件夹，用完就清空删除，不需要为`flutter_build`添加Git管理，`flutter_build`/编译产物 也就不会侵入`flutter_module`和`ios_module`2端。

**优点**:`Flutter.framework`、`App.framework`和`FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework`统一使用了内部私有Git，版本控制逻辑一致，iOS端在依赖Flutter相关SDK的Git时，只需要改版本号(tag)即可；不需要其它的开发人员也安装Flutter开发环境，降低了技术选择的成本；  
**缺点**:`Flutter.framework`文件巨大，将近480M，克隆下载慢，如果Git限制了单个文件大小，则可能push失败。


<h3 id="id-h3-03">0x03: [可行] 全部经本地podspec中转远程zip依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理</h3>

* 1.建立Git仓库`flutter_module_sdk_podspec`备用；
* 2.编译；

```C
  # 编译出 Flutter.podspec 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework

  flutter build ios-framework --cocoapods --xcframework --no-universal --output=../flutter_build/Frameworks/
```

* 3.将App.framework压缩成AppSDK.zip ，FlutterPluginRegistrant.xcframework和其它第三方库一起压缩成PluginSDK.zip；
* 4.上传zip文件到内网服务器，记录对应的zip下载链接；
* 5.在`flutter_module_sdk_podspec`根目录创建`FlutterAppSDK.podspec`和`FlutterPluginSDK.podspec`文件，`s.source`都设置成` :http => http://ftp.private.com/flutter/*SDK.zip`，也就是依赖上一步的下载链接；
* 6.将`Flutter.podspec`移到`flutter_module_sdk_podspec`根目录，因为有现成的zip资源，就不需要我们上传了，直接用就行；
* 7.清空删除`flutter_build`，临时中转站，完事就没用了；
* 8.在`flutter_module_sdk_podspec.git`执行`commit & push`，不用打标签；     

> `flutter_module_sdk_podspec.git仓库目录：`
>> * Flutter.podspec
>> * FlutterAppSDK.podspec
>> * FlutterPluginSDK.podspec

* 9.其他的iOS开发，拉取更新`flutter_module_sdk_podspec.git`；**为了保证在所有电脑上相对路径一致，要禁止大家在克隆git时重命名本地仓库名，并且跟iOS项目本地Git在同一个目录下**。
* 10.在Podfile中添加本地依赖，`pod update or install`，即可运行代码；

```C
  pod 'Flutter', :podspec => './../../flutter_module_sdk_podspec/Flutter.podspec'
  pod 'FlutterAppSDK', :podspec => './../../flutter_module_sdk_podspec/FlutterAppSDK.podspec'
  pod 'FlutterPluginSDK', :podspec => './../../flutter_module_sdk_podspec/FlutterPluginSDK.podspec'
```

**优点**:`podspec`可以统一放到Git管理，`framework`全部压缩成zip放到云端；iOS端直接用本地依赖即可，只要相对路径一致，iOS端多成员开发也不会有Git冲突。 
**缺点**:由于zip是放在内部服务器上，版本控制是个问题，如果支持回退，保留旧版本文件，就会导致服务器上积累大量的废旧文件；如果只存放一个文件，那就没法支持版本回退；

由于`podspec`在独立的Git上，每次执行`pod update or install`前要特意去更新`flutter_module_sdk_podspec.git`，即使增加了流程，但是时间损耗小，所以建议用`alias`合并下终端指令，省去人工操作。

```C
  alias pod_update_for_project_a="cd .../flutter_module_sdk_podspec  && git pull origin  && cd ../path_of_ios_project && pod update --verbose --no-repo-update"
```


<h3 id="id-h3-04">0x04: [可行] 全部经本地podspec中转远程Git依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理</h3>

这个方案结合了[`方案0x03`](#id-h3-03)和[`方案0x02`](#id-h3-02)，即Git依赖 + 本地podspec文件中转。核心是把`framework`都放到了Git上来管理，包括`Flutter.framework`文件，再经本地podspec中转远程Git依赖。

流程上参考[`方案0x03`](#id-h3-03)，把`压缩zip && 上传zip`的流程换成 `把framework移到各自的Git目录或统一的Git目录 && commit and push 到Git上`，另外把所有`podspec`文件里面的`s.source`改成`:git => '...git' ,  :tag => '..version'`。至于如何得到`Flutter.framework`，可回到[`方案0x02`](#id-h3-02)选择一种编译方式即可，在这不再阐述。

**优点**:编译产物都是Git上，方便做版本控制；iOS端直接用本地依赖即可，只要相对路径一致，iOS端多成员开发也不会有Git冲突；
缺点：`Flutter.framework`文件太大，拉取下载很费时；  
**缺点**:`Flutter.framework`文件巨大，将近480M，克隆下载慢，如果Git限制了单个文件大小，则可能push失败。

由于`podspec`在独立的Git上，每次执行`pod update or install`前要特意去更新`flutter_module_sdk_podspec.git`，建议用`alias`合并下终端指令，同[`方案0x03`](#id-h3-03)结尾。  



<h3 id="id-h3-05">0x05: [可行、推荐] 经本地podspec中转远程zip & git混合依赖，podspec文件统一放到独立仓库`flutter_module_sdk_podspec`管理</h3>

这个方案是[`方案0x03`](#id-h3-03)和[`方案0x04`](#id-h3-04)的结合，我比较推荐用这个方案做远程依赖，我后面写的[远程依赖FlutterModule构建脚本`flutter_build_script.sh`] 和 [远程依赖FlutterModule编译产物（升级版）] 就是基于这个方案实现的。  
大文件`Flutter.framework`用现成的zip链接资源，剩余压缩、上传流程，另外本机的Flutter版本变更慢，基本上也可以忽略对应的版本控制。主要变更的还是`App.framework、FlutterPluginRegistrant.xcframework和其它第三方库`，但是这些framework文件不大，放到Git上即可，方便控制版本。**前面说了，拆不拆Git都可以，放一个Git仓库最好，流程和思路是一样的。**

* 1.建立Git仓库`flutter_module_sdk_podspec`、`flutter_app_sdk.git`和`flutter_plugin_sdk.git`备用；
* 2.编译；

```C
  # 编译出 Flutter.podspec 、App.framework、FlutterPluginRegistrant.xcframework和其它第三方库 比如 flutter_boost.xcframework

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

* 9.其他的iOS开发，拉取更新`flutter_module_sdk_podspec.git`；**为了保证在所有电脑上相对路径一致，要禁止大家在克隆git时重命名本地仓库名，并且跟iOS项目本地Git在同一个目录下**。
* 10.在Podfile中添加本地依赖，`pod update or install`，即可运行代码；

```C
  pod 'Flutter', :podspec => './../../flutter_module_sdk_podspec/Flutter.podspec'
  pod 'FlutterAppSDK', :podspec => './../../flutter_module_sdk_podspec/FlutterAppSDK.podspec'
  pod 'FlutterPluginSDK', :podspec => './../../flutter_module_sdk_podspec/FlutterPluginSDK.podspec'
```

**优点**:所有的`podspec`可以统一放到Git管理，iOS端直接用本地podspec中转依赖远程的`framework`，避开了`Flutter.framework`文件过大的问题，又能支持Git版本控制，支持回退版本；只要相对路径一致，iOS端多成员开发也不会有Git冲突；  
**缺点**:iOS端需要按统一的标准将`flutter_module_sdk_podspec.git`克隆到本地，保证大家用的相对路径一致；然后每次执行`pod update or install`前还要特意去更新`flutter_module_sdk_podspec.git`，但可以用指令集或脚本来优化。

由于`podspec`在独立的Git上，每次执行`pod update or install`前要特意去更新`flutter_module_sdk_podspec.git`，即使增加了流程，但是时间损耗小，所以建议用`alias`合并下终端指令，省去人工操作。

```C
  alias pod_update_for_project_a="cd .../flutter_module_sdk_podspec  && git pull origin  && cd ../path_of_ios_project && pod update --verbose --no-repo-update"
```

**最新补充：** 在[远程依赖FlutterModule编译产物（升级版）] 中利用`git submodule`解决了**要求各开发机上2个本地仓库相对路径保持一致**的困难；


<h3 id="id-h3-06">0x06: [行不通] 基于远程podspec做中转，依赖远程zip 或 git资源</h3>

Flutter侧的操作跟[`方案0x04`](#id-h3-04)或[`方案0x05`](#id-h3-05)一致，可以都试试，只对iOS侧的操作做了改动，在Podfile中直接依赖了远程的podspec。

```C
  pod 'Flutter', :git => 'http://gitlab.private.cn/flutter/flutter_module_sdk_podspec.git'
  pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_module_sdk_podspec.git'
  pod 'FlutterAppSDK', :git => 'http://gitlab.private.cn/flutter/flutter_module_sdk_podspec.git'
```

> `flutter_module_sdk_podspec.git仓库目录：`,`podspec `里面的`s.source`可以依赖zip也可以依赖git
>> * Flutter.podspec
>> * FlutterAppSDK.podspec
>> * FlutterPluginSDK.podspec


执行`pod update or install`不会报错，但是打开Pod里面的文件夹，是没有相应`*.framework`文件的。因为我们没有把podspec和framework放在同一个Git上，更新Pods后只得到个空架子。

<h3 id="id-h3-07">0x07: [行不通] 依赖远程服务器上的podspec，通过:http 指向同服务器的zip文件</h3>

```C
pod 'Flutter', :podspec => 'http://ftp.private.com/flutter/Flutter.podspec'
```

执行`pod udpate or install`会直接报错。


<h3 id="id-h3-08">0x08: [最新推荐] 远程依赖FlutterModule编译产物（升级版）</h3>

传送门🚪[远程依赖Flutter Module产物 + Git Submodule + Shell脚本   （升级版 ）](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_remotely_upgrades.md)

## 综上所述

我个人推荐用[`方案0x05`](#id-h3-05)来实现**iOS远程依赖Flutter编译产物**，无论是大团队还是小团队，都行得通，有条件的再整上CI生产线，没条件的就整点脚本，闲鱼团队分享的[《Flutter in action》](https://developer.aliyun.com/article/720790)还是19年的事了，加上Flutter编译产物的变化，不知道闲鱼目前是什么方案。另外我还没看`flutter build ios-framework --cocoapods --xcframework`具体做了啥，内部的流程不太情况，比如什么时候执行了[xcode_backend.sh embed](https://github.com/XiFengLang/flutter_notes/blob/main/xcode_backend.sh)，是否执行了`xcode_backend.sh embed_and_thin`也不太清楚，有了解的朋友希望能指点下。

待研究：`flutter build ios-framework`编译的过程可看源码，对应是路径是`flutter/packages/flutter_tools/lib/src/commands/build_ios_framework.dart`


[回到顶部🔝](#go_top)

------
[《在iOS项目中依赖Flutter组件代码》]:https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md
[3.编译FlutterModule，远程依赖Flutter.xcframework，本地依赖其余.xcframwork]:https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-3
[4.远程依赖Flutter Module组件库编译产物（简单版）]:https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#id-h3-4
[远程依赖FlutterModule编译产物（升级版）]:https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_remotely_upgrades.md
[远程依赖FlutterModule构建脚本`flutter_build_script.sh`]:https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md


