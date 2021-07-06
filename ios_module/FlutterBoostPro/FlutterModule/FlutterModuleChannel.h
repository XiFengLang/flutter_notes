//
//  FlutterModuleChannel.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "Func.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlutterModuleChannel : NSObject
@property (class, nonatomic, strong, readonly) FlutterModuleChannel * global;

@property (nonatomic, strong, readonly) FlutterMethodChannel* channel;


- (void)initMessageChannelWithEngine:(FlutterEngine * _Nonnull)engine;

- (void)addInterceptorForMethod:(NSString *)method received:(FlutterMethodCallHandler _Nullable)received;

- (void)removeInterceptorForMethod:(NSString *)method;


@end

NS_ASSUME_NONNULL_END

