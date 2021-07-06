深浅色适配和`Push/Present`进入Flutter页面是我在项目开发中真实用到的场景，在Demo中我还原了这2个场景，给原生页面和Flutter页面都适配了深浅色，其中的搜索页`SearchPage`就是Flutter页面，而APP的主页就是原生页面（可以切换深浅色），另外进入`SearchPage`采用了`Push、Present` 2种转场方式，以对比效果。


另外我在`FBFlutterViewContainer `基础上自定义一个Flutter控制器容器，最后所有的Flutter页面都由`FlutterModuleViewController`承载，而`FBFlutterViewContainer`则添加在容器`FlutterModuleViewController`上，但是2者不是继承关系，而是父子控制器的关系。之所以这么做是为了统一控制器页面的某些特性和接口功能。


```C
    FlutterModuleViewController.m

    self.flutterContainer.view.frame = self.view.bounds;
    [self.view insertSubview:self.flutterContainer.view atIndex:0];
    [self addChildViewController:self.flutterContainer];
```

<img src="https://github.com/XiFengLang/flutter_notes/blob/main/assets/flutter_page_container.png"  alt="Flutter控制器容器"/><br/>



下面的动图就是实现后的初始效果，仔细观察，就可以发现下面列出的前2个问题，其它的问题则是代码层面的。

### 1.首次进入Flutter页面出现短暂空白

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