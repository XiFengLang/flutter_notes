//
//  AppleDevice.h
//  AppleDevices
//
//  Created by 溪枫狼 on 2021/4/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN UIWindow * KEY_WINDOW(void);


/// identify current Apple product model with machine model.
/// 识别当前的设备型号
@interface AppleDevice : NSObject

/// identify current Apple product model with machine model, eg: iPhone X, iPad Pro.
/// 当前设备型号
@property (class, nonatomic, copy, readonly) NSString * currentDeviceName;


/// iPhone device with a notch design style, the notch design style is started with the iPhone X, and Xcode simulator is supported.
/// 判断是不是刘海屏，支持模拟器
@property (class, nonatomic, assign, readonly) BOOL isNotchDesignStyle;

@end

NS_ASSUME_NONNULL_END
