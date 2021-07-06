//
//  NSObject+Extension.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Extension)


/**
 * 作为链式调用的保护层，可以这么写，能有效避免野指针
 * [obj jk_chained:^{
 *    obj.jk_backgroundColor(UIColor.clearColor);
 * }];
 */
- (void)jk_chained:(dispatch_block_t)chained;


/**
 * 作为链式调用的保护层，能有效避免野指针，并且会在主线程安全回调
 * [obj jk_chainedInMainQueue:^{
 *    obj.jk_backgroundColor(UIColor.clearColor);
 * }];
 */
- (void)jk_chainedInMainQueue:(dispatch_block_t)chained;


@end

NS_ASSUME_NONNULL_END
