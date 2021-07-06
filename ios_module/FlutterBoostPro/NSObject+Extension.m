//
//  NSObject+Extension.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "NSObject+Extension.h"

@implementation NSObject (Extension)

- (void)jk_chained:(dispatch_block_t)chained {
    chained ? chained() : NULL;
}


- (void)jk_chainedInMainQueue:(dispatch_block_t)chained {
    if (NSThread.isMainThread) {
        chained ? chained() : NULL;
    } else {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf)self = weakSelf;
            [self jk_chained:chained];
        });
    }
}


@end
