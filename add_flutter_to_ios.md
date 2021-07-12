# 在iOS项目中依赖Flutter组件代码


不管用何种方式在iOS项目依赖Flutter组件/将Flutter添加到现有的iOS项目，都需要使用flutter_module。所以我们先创建一个Flutter模块/组件。

```C
cd some/path/
flutter create --template module flutter_module
```

`flutter_module `目录的结构如下，`.../flutter_module/lib/`里面就是我们写的dart代码文件。

```C
├── flutter_module
│   ├── README.md
│   ├── build
│   ├── flutter_module.iml
│   ├── flutter_module_android.iml
│   ├── lib
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   └── test
```

我们执行Flutter指令就需要先`cd`到`some/path/flutter_module/`，比如`flutter build ios --release`。

建好`flutter_module`后，随便加点flutter代码和第三方组件，就可以测试添加到iOS项目了。下面我们来尝试几种导入/依赖方案，前3种是官方推荐的，[Flutter也有相关的开发文档 Adding Flutter to iOS
](https://flutter.dev/docs/development/add-to-app/ios/project-setup)。


### 1.基于CocoaPods和podhelper.rb脚本本地依赖FlutterModule

这种接入方式是最常见的一种，方便入手，代码也方便拆分，`ios_module `/`flutter_module `/`andriod_module `可以放到不同的Git仓库，依赖时填写好相对的目录即可。为了方便测试代码，我把`ios_module `/`flutter_module `/`andriod_module `放在了一个Git仓库/目录下。`ios_module`就是iOS项目所在目录，整体目录结构如下：

```C
├── andriod_module
│   ├── ...
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

然后在iOS项目的Podfile文件中增加以下代码，借助flutter的[podhelper.rb](https://github.com/XiFengLang/flutter_notes/blob/main/podhelper.rb)脚本编译Flutter组件导入到Pods中。这种方式无论是Debug运行还是Release打包，都行得通，也方便单人开发调试两端，在1台电脑用2个IDE开发调试两端代码即可；模拟器也能正常运行。但也有明显的缺陷，需要所有的iOS开发人员都安装有Flutter开发环境，另外iOS项目编译慢，每天编译的时间损耗还是不小的，打包时间也会增加不少。

```C
  flutter_application_path = '../flutter_module/'
  load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')
  install_all_flutter_pods(flutter_application_path)
```


### 2.编译Flutter Module得到多个`*.xcframwork`，手动添加到iOS项目中

首先需要将FlutterModule编译成iOS的`.xcframwork`动态库，使用的是`flutter build ios-framework --xcframework`指令集。不过这个指令可以设置导出的目录，所以我们可以直接导出到`ios_module/`里，完整的目录结构如下，相比**方案1**，这里只增加了`FlutterFrameworks `目录，专门用来存放Flutter的编译产物`xcframework`。

```C
├── andriod_module
│   ├── ...
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
    ├── FlutterFrameworks
    ├── Podfile
    ├── Podfile.lock
    └── Pods
```

执行这段完整的编译指令，即可导出`Debug`/`Profile`/`Release`3种不同模式的`xcframework`，并存放在这3个目录中。

> 这个过程会耗时1-2分钟

```C
flutter build ios-framework --xcframework --no-universal --output=../ios_module/FlutterFrameworks/
```

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210706122057.jpg)

然后在Xcode项目的跟目录右键添加文件，即`Add file to 'FlutterBoostPro'`，选择`create groups`，记得勾选`Add to targets`。添加好了后，xcode会自动把这些`xcframework `文件添加到`Build Phases`的`Link Binary With Libraries`中。这个过程在[Flutter文档说明中](https://flutter.dev/docs/development/add-to-app/ios/project-setup#embed-the-frameworks)是手动拖的，添加文件就省去拖文件的操作了。

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210706122355.jpg)


[将`framework`添加到`Embed Frameworks`中](https://flutter.dev/docs/development/add-to-app/ios/project-setup#embed-the-frameworks)，但是初次添加时是找不到`Embed Frameworks`的，所以要到`Targets` - `General` 下面的 `Frameworks, Libraries, and Embedded Content`一栏操作，不过我们使用`Add file to 'a project'`添加的文件会自动加到这一栏，不用重复拖入文件。

在`Build Settings`里面设置`Runpath Search Paths`，添加`"$(SRCROOT)/FlutterFrameworks/Release"`，指定相对路径

这个时候试着运行项目，会出现报错:

```C
dyld: Library not loaded: @rpath/Flutter.framework/Flutter
  Referenced from: /private/var/containers/Bundle/Application/0A64CC78-D8D3-433C-B794-B8F928525885/FlutterBoostPro.app/FlutterBoostPro
  Reason: image not found
dyld: launch, loading dependent libraries
DYLD_LIBRARY_PATH=/usr/lib/system/introspection
DYLD_INSERT_LIBRARIES=/Developer/usr/lib/libBacktraceRecording.dylib:/Developer/usr/lib/libMainThreadChecker.dylib:/Developer/Library/PrivateFrameworks/DTDDISupport.framework/libViewDebuggerSupport.dylib
```

是因为我们没有设置`Embed & Sign`，状态是`Do Not Embed`，[Flutter文档说明中](https://flutter.dev/docs/development/add-to-app/ios/project-setup#embed-the-frameworks)也指明了这个操作，都选择`Embed & Sign`即可，设置正确后就能正常运行项目了。

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210706123759.jpg)

这种导入`framework`的方式，增加了编译Flutter、设置Target配置流程，如果需要切换`Debug/Release`环境，还需要重新添加`framework`，并重新设置`FRAMEWORK_SEARCH_PATHS`和`Embed & Sign`，在调试期间会增加不少的手动操作，当然为了方便调试，在`flutter_module/.ios/`下面的Runner项目中也可以依赖iOS的业务代码，也可以快速调试，只是`Flutter clean`后又要重新依赖，相对来说还是有点繁琐的；另外由于把编译产物直接导入到了iOS项目目录中，而`Flutter.xcframework`文件很大，会直接增加git的文件大小，影响git push和pull，每次编译也会影响到其他人员分支的同步。但这种导入`framework`的方式也有个非常大的优点，编译运行iOS项目耗时短，因为已经是编译过的`xcframework`文件，不用每次附加编译Flutter代码，相比之下能节省很多编译时间；另外其他的开发人员也不用安装Flutter开发环境，直接跑iOS项目就行。

> * 模拟器上运行不能正常展示Flutter页面，是空白的，待排查原因

### 3.编译Flutter Module得到多个`*.xcframwork`，使用CocoaPods依赖导入`Flutter.xcframework`

前面2种方法都是依赖本机的编译产物，如果想把`FlutterFrameworks`分享给同事，直接推到Git是行不通的，`Flutter.xcframework`太大，超过了Github单个文件100M的限制，为此Flutter官方特意给`Flutter.xcframework`实现了远程依赖。这种依赖Flutter组件的方法逻辑上跟**方案2**一致，先把flutter_module编译成framwork，存放在`FlutterFrameworks`目录，再手动导入项目。区别在于`Flutter.xcframework`是通过cocoaPods导入，直接依赖了Google的远程文件，这样就避免了git无法提交的问题。

首先还是编译Flutter，需要注意这里增加了`--cocoapods`，编译后的产物包含了一个`Flutter.podspec`，这个`Flutter.podspec`依赖指向了`Flutter.xcframework`的远程文件。

```C
flutter build ios-framework --cocoapods --xcframework --no-universal --output=../ios_module/FlutterFrameworks/
```

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210706145922.jpg)

我们可以看下`Flutter.podspec`里面的具体内容，`Flutter.xcframework`是线上拉取的，并不是我们前面用指令编译出来的，而且编译导出的目录里面也没有`Flutter.xcframework`（编译后就删除了），只有`App.xcframework`、`FlutterPluginRegistrant.xcframework`和`第三方库 flutter_boost.xcframework`。

```C
Pod::Spec.new do |s|
  s.name                  = 'Flutter'
  s.version               = '2.0.300' # 2.0.3
  s.summary               = 'Flutter Engine Framework'
  s.description           = <<-DESC
  	... 一些描述
	DESC
  s.homepage              = 'https://flutter.dev'
  s.license               = { :type => 'MIT', :text => <<-LICENSE
    	... 一些版权声明
  	LICENSE
  }
  s.author                = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source                = { :http => 'https://storage.flutter-io.cn/flutter_infra/flutter/3459eb24361807fb186953a864cf890fa8e9d26a/ios-release/artifacts.zip' }
  s.documentation_url     = 'https://flutter.dev/docs'
  s.platform              = :ios, '8.0'
  s.vendored_frameworks   = 'Flutter.xcframework'
end
```

然后我们在`Podfile`新增依赖`Flutter`，执行`pod install or update`

```C
pod 'Flutter', :podspec => './FlutterFrameworks/Release/Flutter.podspec'
```

首次安装会从云端下载`Flutter.xcframework`，文件大小在200M左右 (各版本Flutter对应的大小不一样)，有点考验网络，解压后的`Flutter.xcframework`大小在480M左右，超出了Github的文件大小限制，所以务必要添加到`.gitignore`中。

```C
-> Installing Flutter (2.0.300)
 > Http download
   $ /usr/bin/curl -f -L -o /var/folders/jp/4slqd1n915b7s_dm47l0mk240000gn/T/d20210706-71545-f6gido/file.zip https://storage.flutter-io.cn/flutter_infra/flutter/3459eb24361807fb186953a864cf890fa8e9d26a/ios-release/artifacts.zip
   --create-dirs --netrc-optional --retry 2 -A 'CocoaPods/1.10.1 cocoapods-downloader/1.4.0'
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100  194M  100  194M    0     0  10.0M      0  0:00:19  0:00:19 --:--:-- 10.8M
```


如果这个时候我们运行项目，是会报错的，因为目前为止只依赖`Flutter.xcframework`，其它的编译产物还是没有导入。所以我们还需要按照**方案2**的流程把`App.xcframework`、`FlutterPluginRegistrant.xcframework`和`第三方库 flutter_boost.xcframework`导入到项目中。不过这里我不使用`Add Files to 'a project'`来添加文件了，而是把这3个文件拖到`Frameworks, Libraries, and Embedded Content`里面，设置`Embed & Sign`，然后在`Build Settings`的`Runpath Search Paths`添加`"$(SRCROOT)/FlutterFrameworks/Release"`，就可以正常运行项目了。


相比**方案2**，`Flutter.xcframework`采用了CocoaPods依赖导入，但是其它的`.xcframework`还是要手动导入。所以它的优缺点和**方案2**是基本一致的。另外在编译过程中可以看到生成了`Flutter.xcframework`，但是并没有发现上传文件，所以`Flutter.xcframework`是远程的静态资源，如果有自定义引擎需求，就得在**方案2**的基础上改了。

> * 模拟器上运行不能正常展示Flutter页面，是空白的，待排查原因


### 4.远程依赖Flutter编译产物（简单版）

在[方案3 使用CocoaPods远程依赖`Flutter.xcframework`](https://github.com/XiFengLang/flutter_notes/blob/main/add_flutter_to_ios.md#3%E5%B0%86flutter%E7%BC%96%E8%AF%91%E6%88%90xcframwork%E4%BD%BF%E7%94%A8cocoapods%E4%BE%9D%E8%B5%96%E5%AF%BC%E5%85%A5flutterxcframework)中提到，`Flutter.xcframework`是远程依赖的，那同样也可以远程依赖`App.xcframework`、`FlutterPluginRegistrant.xcframework`和`其它第三方库 比如 flutter_boost.xcframework`，网上也有现成的实现方案和脚本(几乎都是旧版本的，需要自己改改)。

这个方案基于**方案2**或**方案3**来实现，开头都是先编译，然后收集编译产物，不过这里跟前面的方案不一样，要把收集到的编译产物推送到单独的私有Git仓库，并打上标签。

> 之所以说可以基于**方案2**或**方案3**来实现，是因为如果不需要自定义Flutter Engine，使用各个版本默认的`Flutter.fromework`，那就选择**方案3**的指令，而且**方案3**指令编译出来的framework都已经设置了`Embed`，`Flutter.fromework`使用从Google的云端下载下来的文件。如果有自定义引擎的需求，则需要把编译过的`Flutter.fromework`也上传到内网私有git，选择**方案2**的指令，只是这个文件很大，会增加不少时间。不过还是建议给自定义的`Flutter.fromework`单独建立git仓库以及版本控制，避免经常下载，浪费时间。

我们用**方案3**的指令编译flutter module；`--outpu`输出路径最好指向编译产物所在Git路径，`JKFlutter`就是我专门为编译产物建的私有git。

**注意：Github有文件大小限制，flutter.framework目前已将近480M，超出了文件大小限制，所以是提交不上去的，我用Github（JKFlutter）只是为了方便介绍流程，实际Push到git时是传不上去的。这里建议换成内网的Gitlab仓库，不要用Github**

```C
flutter build ios-framework --cocoapods --xcframework --no-universal --output=../../JKFlutter/
```

![](https://github.com/XiFengLang/flutter_notes/blob/main/assets/20210708120329.png)

为了方便测试，我把`Flutter.fromework (下载的文件)`、`App.xcframework`、`FlutterPluginRegistrant.xcframework`和`其它第三方库 比如 flutter_boost.xcframework`放到了同一个git目录，并且合并成了一个库，即`FlutterModuleSDK`。所以需要额外创建一个描述文件`FlutterModuleSDK.podspec`。`podspec`的主要内容如下，重点则在`s.vendored_frameworks   = '*.xcframework'` ，指向了`JKFlutter.git`里的所有`.xcframework`动态库。

Flutter.podspec

```C
Pod::Spec.new do |s|
  s.name                  = 'FlutterModuleSDK'
  s.version               = '1.0.2'
  s.summary               = 'Flutter Module SDK'
  s.source                = { :git => 'https://github.com/XiFengLang/JKFlutter.git', :tag => "#{s.version}" }
  s.platform              = :ios, '8.0'
  s.requires_arc          = true
  s.vendored_frameworks   = '*.xcframework'
end
```

然后提交git，并打上对应的标签，推到远程仓库`JKFlutter.git`，到这里就完成推到云端的操作了，不用执行CocoaPods组件的发布指令。

这一步就轮到iOS端操作了，在iOS项目的Podfile中，增加`FlutterModuleSDK`的依赖，执行`pod install or update`，即可运行项目了。

```C
platform :ios,'11.0'
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/XiFengLang/JKFlutter.git'

target 'FlutterBoostPro' do

#  flutter_application_path = '../flutter_module/'
#  load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')
#  install_all_flutter_pods(flutter_application_path)
  
#  pod 'Flutter', :podspec => './FlutterFrameworks/Release/Flutter.podspec'

  pod 'FlutterModuleSDK', :git => 'https://github.com/XiFengLang/JKFlutter.git'
  
end
```

这个方案主要就3步，[1.编译]：编译FlutterModule，[2.发布] 收集产物推到云端Git，[3.更新代码] iOS端更新CocoaPods，就此简单实现了FlutterModule远程依赖。

但是细想下，正常情况下，我们改了Dart代码，不加新的第三方组件的话，编译后变的只有`App.framework`，而`FlutterPluginRegistrant.xcframework`和`其它第三方库 比如 flutter_boost.xcframework`是不变的，所以我们也可以参考`Flutter.fromework`的思路，给`FlutterPluginRegistrant.xcframework`和`其它第三方库 比如 flutter_boost.xcframework`再单独建个仓库，通常不用更新，除非第三方组件库的版本换了 或者 增加了新的第三方组件。多数情况只要维护`App.framework`的更新就行，这些想法我会在下一节测试。


### 5.远程依赖Flutter编译产物（多种方案） 

已整理到另一份文档，[请戳 远程依赖Flutter编译产物](https://github.com/XiFengLang/flutter_notes/blob/main/depend_flutter_module_remotely.md)
