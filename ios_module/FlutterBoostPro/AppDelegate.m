//
//  AppDelegate.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "FlutterModuleAgent.h"


@interface AppDelegate ()



@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.blackColor;
    self.window.rootViewController = [[BasicNavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];

    [self.window makeKeyAndVisible];
    
    [FlutterModuleAgent.shared startFlutterInApp:application callback:^(FlutterEngine * _Nonnull engine, FlutterModuleAgent * _Nonnull agent) {
        /// 尽量在启动APP后就进行FlutterModule预加载，提前渲染一个Flutter页面
        /// 以解决首次进入Flutter页面闪白的问题
        [agent preloadFlutterModuleAfterDelay:0.6];
    }];
    
    return YES;
}



@end
