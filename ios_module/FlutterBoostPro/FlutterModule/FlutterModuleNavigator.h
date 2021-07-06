//
//  FlutterModuleNavigator.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <Foundation/Foundation.h>
#import "FlutterModuleConstants.h"

#import <flutter_boost/FlutterBoost.h>
#import "FlutterModuleViewController.h"


NS_ASSUME_NONNULL_BEGIN

/// 相当于页面navigator
@interface FlutterModuleNavigator : NSObject


/// 关闭页面
+ (void)close:(NSString *)uniqueId;

/// 打开Flutter页面
+ (void)push:(NSString *)url
   arguments:(NSDictionary * _Nullable)arguments;

/// 打开Flutter页面
+ (void)push:(NSString *)url;

/// 打开Flutter页面
+ (void)present:(NSString *)url
      arguments:(NSDictionary * _Nullable)arguments;

/// 打开Flutter页面
+ (void)present:(NSString *)url;


@end

NS_ASSUME_NONNULL_END
