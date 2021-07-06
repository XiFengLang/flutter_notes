# JKRetractableGCDDelay
可取消的GCD延迟操作，基于[Dispatch-Cancel](
https://github.com/Spaceman-Labs/Dispatch-Cancel)


### CocoaPods

```C
 source 'https://github.com/CocoaPods/Specs.git'
 
 pod 'JKRetractableGCDDelay', '~> 1.0.1'
```


* 使用performSelector执行延迟任务，以及取消延迟任务。

```Object-C
	
	[self performSelector:@selector(jk_testSEL) withObject:nil afterDelay:5];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(jk_testSEL) object:nil];
    // [NSObject cancelPreviousPerformRequestsWithTarget:self];
```

* 使用dispatch_after执行延迟任务，但是系统没有提供取消任务的API，而dispatch_after可能会强引用外部对象，导致对象延迟释放，出现奇奇怪怪的问题。不过[Dispatch-Cancel](
https://github.com/Spaceman-Labs/Dispatch-Cancel)恰好解决了这个问题，有兴趣的可以看看源码。JKRetractableGCDDelay基于这个框架封装，提供了3种方法执行延迟任务。


**调用函数**

```Object-C

/// 外部需要强引用JKGCDDelayTaskBlock
@property (nonatomic, copy) JKGCDDelayTaskBlock delayTaskBlock;


    __weak typeof(self) weakSelf = self;
    self.delayTaskBlock = JK_GCDDelayTaskBlock(5.0, ^{
        weakSelf.view.backgroundColor = [UIColor redColor];
    });


	JK_CancelGCDDelayedTask(self.delayTaskBlock);
```

**每个对象在同一时段只能执行一个延迟任务**

```Object-C
	 __weak typeof(self) weakSelf = self;
    [self jk_excuteDelayTask:5 inMainQueue:^{
        weakSelf.view.backgroundColor = [UIColor darkGrayColor];
    }];
    
    
    [self jk_cancelGCDDelayTask];
```


**给每个任务绑定Key，根据对应的Key取消任务**

```Object-C
    __weak typeof(self) weakSelf = self;
    [self jk_excuteDelayTaskWithKey:"key" delayInSeconds:5 inMainQueue:^{
        weakSelf.view.backgroundColor = [UIColor blueColor];
    }];
    
    
    [self jk_cancelGCDDelayTaskForKey:"key"];
```

