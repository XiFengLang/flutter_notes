//
//  FlutterModuleViewController.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "BasicViewController.h"
#import "FlutterModuleConstants.h"


#import <flutter_boost/FBFlutterViewContainer.h>
#import <UINavigationController+FDFullscreenPopGesture.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterModuleViewController : BasicViewController

/// flutter定义的路由
@property (nonatomic, copy) NSString * route;


/// 用Flutter测的路由和参数来初始化，不需要子类重写 `willMountFlutterContainer` 调用 `setName:(NSString *)name params:(NSDictionary *)params;`
/// 2个特殊参数：
/// params.disableFullscreenPopGesture  禁用FDFullscreenPopGesture的全屏侧滑返回效果
/// params.statusBarStyle  控制状态栏的颜色
- (instancetype)initWithRoute:(NSString *)route params:(NSDictionary *)params;


/// 此时设置setInitialRoute没有用，main()拿到的defaultRouteName是'/'
@property(nonatomic, strong, readonly)FBFlutterViewContainer * flutterContainer;


/// Flutter容器刚初始化，还未添加到view上，子类可重写设置路由
- (void)willMountFlutterContainer;

/// 布局，子类可重写
- (void)willLayoutFlutterContainer;


@end

NS_ASSUME_NONNULL_END

