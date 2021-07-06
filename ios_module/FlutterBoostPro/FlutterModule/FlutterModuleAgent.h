//
//  FlutterModuleAgent.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <Foundation/Foundation.h>
#import "FlutterModuleConstants.h"

#import <flutter_boost/FlutterBoost.h>

#import "FlutterModuleNavigator.h"
#import "FlutterModuleChannel.h"
#import "FlutterModuleHelper.h"
#import "FlutterModuleViewController.h"


NS_ASSUME_NONNULL_BEGIN

/// flutter boost页面路由的代理, 差不多就是flutter端的navigator的代理
/// 实现页面的入栈出栈
@interface FlutterModuleAgent : NSObject <FlutterBoostDelegate>

/// 单例
@property (nonatomic, strong, readonly, class) FlutterModuleAgent * shared;

@property (nonatomic, strong, readonly) FlutterModuleChannel * globalChannel;


/// 初始化flutter，会触发flutter的main()，同时Agent内部会实现一个全局的FlutterModuleChannel，用于2端交互
///
/// 在FLBFlutterApplication文件中，初始化引擎后便调用了
/// Class clazz = NSClassFromString(@"GeneratedPluginRegistrant");
/// [clazz performSelector:NSSelectorFromString(@"registerWithRegistry:") withObject:myengine];
/// 所以不需要再手动注册插件，即下面一行代码
/// [GeneratedPluginRegistrant registerWithRegistry:self];
///
- (void)startFlutterInApp:(UIApplication *)application
                 callback:(void (^)(FlutterEngine * engine, FlutterModuleAgent * agent))callback ;



/// 尽量在启动APP后就进行FlutterModule预加载，提前渲染一个Flutter页面
/// 以解决首次进入Flutter页面闪白的问题
/// @param delay 秒
- (void)preloadFlutterModuleAfterDelay:(CGFloat)delay;



@end

NS_ASSUME_NONNULL_END

