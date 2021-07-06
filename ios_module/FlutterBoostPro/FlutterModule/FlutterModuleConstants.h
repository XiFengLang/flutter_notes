//
//  FlutterModuleConstants.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#ifndef FlutterModuleConstants_h
#define FlutterModuleConstants_h
#import <Foundation/Foundation.h>

/// Flutter开关
static const NSInteger kFlutterEnable = 1;


/// 禁用侧滑返回
static NSString * const kDisableFullscreenPopGesture  = @"disable_fullscreen_pop_gesture";

/// 指定状态栏样式
static NSString * const kStatusBarStyle  = @"statusBarStyle";

/// 通过FlutterBoost打开native页面时传的url
static NSString * const kNativePage  = @"native_page";


/// 通过FlutterBoost打开native页面时携带的参数：指定native的路由
static NSString * const kNativeRouteUrl  = @"route_url";


/// 通过FlutterBoost打开native页面时携带的参数：指定native的路由参数
static NSString * const kNativeRouteParams  = @"route_params";


#endif /* FlutterModuleConstants_h */
