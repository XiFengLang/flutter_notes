我们的项目使用`flutter_boost`来实现iOS & Flutter混合项目开发，目前也已经适配到`flutter_boost v3.0.0`。`FlutterBoost`在`3.0.0`新增一个Flutter控制器容器，但我们项目有统一的控制器基类，为了统一控制器页面的某些特性和接口功能， 我在`FlutterBoost`的容器上又封装了一层控制器容器，导致在开发过程遇到了深浅色适配和内存泄漏的问题。

<h3 id="id-h3-01">自定义Flutter(Boost)容器后，Flutter页面退出后没有调用dispose，出现内存泄漏</h3>

效果图展示的搜索页`SearchPage`就是Flutter页面，而APP的主页就是原生页面（可以切换深浅色），另外进入`SearchPage`采用了`Push、Present` 2种转场方式，以对比效果。

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/ezgif-com-gif-make.webp" width="50%" height="50%" alt="效果图"/><br/>

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

但是随后发现`Present`进入`search_page`时同样也会出现内存泄漏，Flutter页面没有被释放。调试发现 'dismissViewControllerAnimated:completion:' 并没有触发'didMoveToParentViewController:'方法，😓怪自己基础不扎实。于是又加了下面的代码，解决了嵌套`FBFlutterViewContainer`页面出现的内存泄漏问题。

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
``