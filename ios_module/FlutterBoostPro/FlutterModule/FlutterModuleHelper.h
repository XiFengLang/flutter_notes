//
//  FlutterModuleHelper.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterModuleHelper : NSObject

/// 获取当前展示的window
+ (UIWindow * _Nullable)visibleWindow;

/// 获取当前显示的控制器
+ (UIViewController * _Nullable)visibleViewController;

/// 获取当前控制器的NaviagtionController
+ (UINavigationController * _Nullable)visibleNaviagtionController;

/// 退出控制器
+ (void)exitViewController:(UIViewController *)vc animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
