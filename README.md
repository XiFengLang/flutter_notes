[TOC]

这个仓库主要有2部分，整理了在iOS项目引入FlutterModule组件代码的几种方法，以及整理开发过程中遇到的一些问题和对应的解决方案。

## iOS项目依赖FlutterModule


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







