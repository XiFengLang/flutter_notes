//
//  FlutterModuleAgent.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "FlutterModuleAgent.h"

@interface FlutterModuleAgent ()

@property (nonatomic, strong) NSMapTable <NSString *,FlutterModuleViewController *>* vcHashMap;

@end


@implementation FlutterModuleAgent

+ (FlutterModuleAgent *)shared {
    static FlutterModuleAgent * channel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channel = [[FlutterModuleAgent alloc] init];
    });
    return channel;
}

- (instancetype)init {
    if (self = [super init]) {
        self.vcHashMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory];
    }return self;
}

- (FlutterModuleChannel *)globalChannel {
    return FlutterModuleChannel.global;
}



/// 这里会触发main()
- (void)startFlutterInApp:(UIApplication *)application callback:(nonnull void (^)(FlutterEngine * _Nonnull, FlutterModuleAgent * _Nonnull))callback {
    
    /// FlutterBoostPlugin 初始化
    [[FlutterBoost instance] setup:application delegate:self callback:^(FlutterEngine *engine) {
        [self.globalChannel initMessageChannelWithEngine:engine];
        callback ? callback(engine, self) : NULL;
    }];
    
    
    
    /// 发送通知
    [self.globalChannel addInterceptorForMethod:@"notify" received:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        var params = SafeDictionary(call.arguments);
        NSString * title = params[@"name"];
        var userInfo = SafeDictionary(params[@"userinfo"]);
        NSLog(@"Flutter端要求发送通知:%@",params);
        [NSNotificationCenter.defaultCenter postNotificationName:title object:nil userInfo:userInfo];
        result(@"1");
    }];
    
    
}


/// 尽量在启动APP后就进行FlutterModule预加载，提前渲染一个Flutter页面
/// 以解决首次进入Flutter页面闪白的问题
- (void)preloadFlutterModuleAfterDelay:(CGFloat)delay {
    dispatch_block_t preload = ^(){
        [FlutterModuleNavigator push:@"root_page" arguments:@{}];
        
        [self jk_excuteDelayTaskWithKey:"dispose_flutter_module" delayInSeconds:0.6 inMainQueue:^{
            // 这里不能直接调[FlutterNavigator close:]，原因未知，但是会导致
            // FLutter侧 final bool handled = await container?.navigator?.maybePop(); 结果handled = null
            // 从而导致 [FlutterBoost.instance.plugin.delegate popRoute:] 不被调用
            // 所以改成了直接调用，绕过Flutter侧的一些逻辑
            
            [FlutterModuleChannel.global.channel invokeMethod:@"exit_current_page" arguments:@{}];
            // [FlutterBoost.instance.plugin.delegate popRoute:@"root_page"];
        }];
    };
    
    if (delay <= 0.01) {
        dispatch_async(dispatch_get_main_queue(), preload);
    } else {
        [self jk_excuteDelayTaskWithKey:"preload_flutter_module" delayInSeconds:delay inMainQueue:preload];
    }
}



/// 转场打开原生页面
- (void)pushNativeRoute:(NSString *)pageName arguments:(NSDictionary *)arguments {
    //    NSMutableDictionary * parameters = SafeMutDictionary(arguments);
    /// 由原生的路由处理
    //if (!implemented) NSLog(@"⚠️ FlutterBoost pushNativeRoute：arguments：路由未被处理");
    
    NSLog(@"打开原生页面");
}

/// 转场打开Flutter混合页面
- (void)pushFlutterRoute:(NSString *)pageName uniqueId:(NSString *)uniqueId arguments:(NSDictionary *)arguments completion:(void (^)(BOOL))completion {
    // One instance of the FlutterEngine can only be attached to one FlutterViewController at a time.
    // Set FlutterEngine.viewController to nil before attaching it to another FlutterViewController.
    FlutterEngine* engine =  [[FlutterBoost instance] engine];
    engine.viewController = nil;
    
    
    BOOL present= [arguments[@"present"] boolValue];
    if (present) { // 处理present
        [self presentFlutterRoute:pageName arguments:arguments completion:completion];
        return;
    }
    
    
    if ([pageName isEqualToString:@"root_page"]) {
        CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
        CGFloat screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
        
        /// 尽量在启动APP后就进行FlutterModule预加载，以及切换深浅色主题后，提前渲染一个Flutter页面
        /// 以解决进入Flutter页面背景色延迟改变的问题
        FlutterModuleViewController * flutterVC = [[FlutterModuleViewController alloc] initWithRoute:pageName params:arguments];
        // 放在屏幕边缘
        flutterVC.view.frame = CGRectMake(screenWidth-0.3, screenHeight-0.3, screenWidth, screenHeight);
        UIViewController * aVC = FlutterModuleHelper.visibleViewController;
        [aVC addChildViewController:flutterVC];
        [aVC.view addSubview:flutterVC.view];
        
        [self.vcHashMap setObject:flutterVC forKey:flutterVC.flutterContainer.uniqueIDString];
        SafeBlockPerformer(completion, true);
        return;
    }
    
    
    // 转场动效
    BOOL animated = arguments[@"animated"] == nil ? true : [arguments[@"animated"] boolValue];
    
    FlutterModuleViewController * flutterVC = [[FlutterModuleViewController alloc] initWithRoute:pageName params:arguments];
    [FlutterModuleHelper.visibleNaviagtionController pushViewController:flutterVC animated:animated];
    [self.vcHashMap setObject:flutterVC forKey:flutterVC.flutterContainer.uniqueIDString];
    dispatch_async(dispatch_get_main_queue(), ^{
        SafeBlockPerformer(completion, true);
    });
}

- (void)presentFlutterRoute:(NSString *)pageName arguments:(NSDictionary *)arguments completion:(void (^)(BOOL))completion {
    // 转场动效
    BOOL animated = arguments[@"animated"] == nil ? true : [arguments[@"animated"] boolValue];
    
    FlutterModuleViewController * flutterVC = [[FlutterModuleViewController alloc] initWithRoute:pageName params:arguments];
    BasicNavigationController * navController = [[BasicNavigationController alloc] initWithRootViewController:flutterVC];
    if (@available(iOS 13.0, *)) {
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    [FlutterModuleHelper.visibleNaviagtionController presentViewController:navController animated:animated completion:^{
        SafeBlockPerformer(completion, true);
    }];
    [self.vcHashMap setObject:flutterVC forKey:flutterVC.flutterContainer.uniqueIDString];
}



/// 退出Flutter混合页面（uniqueId默认指向顶层的vc）
- (void)popRoute:(NSString *)uniqueId {
    if (uniqueId == nil || uniqueId.length == 0) {
        NSLog(@"⚠️ FlutterBoost popRoute：退出失败，uniqueId为空");
        return;
    }
    
    FlutterModuleViewController * flutterVC = [self.vcHashMap objectForKey:uniqueId];
    
    /// FlutterViewController 会嵌套 FLBFlutterViewContainer
    if ([flutterVC isKindOfClass:FBFlutterViewContainer.class] &&
        [flutterVC.parentViewController isKindOfClass:FlutterModuleViewController.class]) {
        flutterVC = (id)flutterVC.parentViewController;
    }
    
    /// 对root_page 特殊处理
    if ([flutterVC.route isEqualToString:@"root_page"]) {
        [flutterVC.view removeFromSuperview];
        [flutterVC removeFromParentViewController];
        [self.vcHashMap removeObjectForKey:uniqueId];
    }
    
    // FIXME: 个别页面会调多个接口，报错了都调closeCurrentPage，就会重复退出
    // 这里要拦截一下，只退出当前的Flutter页面
    else if ([flutterVC isKindOfClass:FlutterModuleViewController.class] ||
             [flutterVC isKindOfClass:FBFlutterViewContainer.class]) {
        [FlutterModuleHelper exitViewController:flutterVC animated:true];
        [self.vcHashMap removeObjectForKey:uniqueId];
    }
}


#pragma mark - Private


/// 加转场动效animated
- (NSDictionary *)processedArguments:(NSDictionary *)arguments {
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithDictionary:arguments];
    if (!dict[@"animated"]) {
        /// 默认加动效
        dict[@"animated"] = @(true);
    }
    return dict.copy;
}



@end

