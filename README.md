 flutter_boost采坑 & iOS混合项目依赖FlutterModule

我们的项目使用`flutter_boost`来实现iOS & Flutter混合项目，目前已经适配`3.0.0`。因为我在`FlutterBoost`的容器上又封装了一层控制器容器，导致我在使用`FlutterBoost`开发iOS混合项目时遇到了一些问题，在此整理了相关的问题和解决方案。

深浅色适配和`Push/Present`进入Flutter页面是我在项目开发中真实用到的场景，在Demo中我还原了这2个场景，给原生页面和Flutter页面都适配了深浅色，其中的搜索页`SearchPage`就是Flutter页面，而APP的主页就是原生页面（可以切换深浅色），另外进入`SearchPage`采用了`Push、Present` 2种转场方式，以对比效果。


下面的动图就是实现后的初始效果，仔细观察，就可以发现下面列出的前2个问题，其它的问题则是代码层面的。

### 1.首次进入Flutter页面出现空白

由于缺少缓存，安装APP后首次进入Flutter页面会出现短暂的空白，然后再渲染出Flutter的UI，之后重启APP基本不会出现这个问题。

### 2.在原生页面切换深浅色后进入Flutter页面会先渲染上一次的配色模式

在APP内的原生页面切换深浅色后进入Flutter页面，会先渲染上一次的深浅色样式，再切换当前的配色，先白后黑或者先黑后白；


<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/ezgif.com-gif-maker.webp" width="50%" height="50%" alt="问题图"/><br/>

对于这2个问题，我的解决思路是一样的，就是提前预加载一个Flutter页面，让Flutter提前完成渲染和缓存。

* 首先是在初始化`FlutterBoost`后预加载一个Flutter页面，再立刻(延迟0.6秒)关掉这个页面。
* 切换深浅色之后同样也预加载一个Flutter页面，然后又立刻关掉这个页面，完成Flutter侧的深浅色渲染。

具体的代码参考`[FlutterModuleAgent preloadFlutterModuleAfterDelay:]`和`@"root_page"`空白页的处理逻辑。需要注意的是为了不让用户体察到这个动作，需要用`addChildViewController:flutterVC`的方式把这个页面放在屏幕外面，即设置`flutterVC.view.frame`，而不是采用`push/present`带转场方式。`push/present`会有转场动效，即使无动效也可能干扰到正常的控制器栈，而`addChildViewController: flutterVC `和`addSubview:flutterVC.view`则简单粗暴的多，几乎不会影响到现有的控制器栈。

这是启用预加载之后的效果，无论是首次进入Flutter页面，还是切换深浅色后进入Flutter页面，~~都不会有闪白卡顿的现象~~，流畅了很多，只有第一次启动APP进入Flutter页面才会出现短暂的闪白，原因还未找到，不过影响不大。

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/ezgif-com-gif-make.webp" width="50%" height="50%" alt="优化后"/><br/>



### 3.flutter页面内存泄漏，flutter页面退出后没有调用dispose

在`search_page.dart`文件`_SearchPageState`中重写`dispose()`方法，监听页面内存释放。`search_page`是Push进入的，Pop页面后原生控制器被释放，但是Flutter侧页面并没有释放，没有打印页面已释放，检查2端代码后发现问题出在原生侧自定义的Flutter控制器容器上。

```C
class _SearchPageState extends State<SearchPage> {
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  ...

  @override
  void dispose() {
    print('搜索页已释放');

    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }
  
  ...
}
```

我使用的页面结构如下图所示，之所以这么做是为了统一控制器页面的某些特性和接口功能。选择在`FBFlutterViewContainer `基础上自定义一个Flutter控制器容器，最后所有的Flutter页面都由`FlutterModuleViewController`承载，而`FBFlutterViewContainer`则添加在容器`FlutterModuleViewController`上，但是2者不是继承关系，而是父子控制器的关系。

```C
    FlutterModuleViewController.m

    self.flutterContainer.view.frame = self.view.bounds;
    [self.view insertSubview:self.flutterContainer.view atIndex:0];
    [self addChildViewController:self.flutterContainer];
```

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/flutter_page_container.png"  alt="Flutter控制器容器"/><br/>

由于我漏掉了`[self.flutterContainer removeFromParentViewController]`，导致了`FBFlutterViewContainer`的`notifyWillDealloc`逻辑没有执行，Flutter侧没有移除掉对应的页面Widget，也就不会调用`dispose()`。于是重写了`didMoveToParentViewController:`方法，退出控制器时调用`[self.flutterContainer removeFromParentViewController]`，以触发`notifyWillDealloc`逻辑，完成Flutter侧的内存释放。

```C
FlutterModuleViewController.m

- (void)didMoveToParentViewController:(UIViewController *)parent {
    /// MARK: 下面这行代码在这儿会触发2次notifyWillDealloc，会导致FlutterBoost出现异常
    /// 比如 NoSuchMethodError: The getter 'topPage' was called on null.
    /// [self.flutterContainer didMoveToParentViewController:parent];

    /// 下面只会触发一次notifyWillDealloc，正常
    if (parent == nil && self.flutterContainer.parentViewController) {
        [self.flutterContainer removeFromParentViewController];
    }
    [super didMoveToParentViewController:parent];
}
```

**但是 但是 但是** 我又发现`Present`进入`search_page`时同样也会出现内存泄漏，Flutter页面没有被释放。调试发现 'dismissViewControllerAnimated:completion:' 并没有触发'didMoveToParentViewController:'方法，😓怪自己基础不扎实。于是又加了下面的代码，解决了嵌套`FBFlutterViewContainer`页面出现的内存泄漏问题。

```C
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        /// MARK: 解决NavigationController嵌套CustomFlutterVC导致Flutter页面不释放的问题
        /// 原因是 'dismissViewControllerAnimated:completion:' 并不会触发 'didMoveToParentViewController:'方法
        /// FBFlutterViewContainer 有重写 'dismissViewControllerAnimated:completion:' 方法来移除Flutter页面
        /// 但如果FBFlutterVC又被嵌套在自定义的CustomFlutterVC里面，CustomFlutterVC就需要实现移除Flutter页面的逻辑，主动触发Flutter侧内存释放
        
        [self didMoveToParentViewController:nil];
    }];
}
```





