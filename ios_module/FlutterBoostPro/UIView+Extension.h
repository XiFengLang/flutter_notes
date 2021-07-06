//
//  UIView+Extension.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <UIKit/UIKit.h>
#import "NSObject+Extension.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Extension)

/**
 不安全的属性，可能会出现野指针错误，请在[UIView jk_chained:]里面调用
 */
@property (nonatomic, copy, readonly) UIView * (^jk_backgroundColor)(UIColor * __nullable color);


@property (nonatomic, copy, readonly) UIView * (^jk_cornrRadius)(CGFloat cornrRadius);

@property (nonatomic, copy, readonly) UIView * (^jk_borderWidth)(CGFloat borderWidth);

@property (nonatomic, copy, readonly) UIView * (^jk_borderColor)(UIColor * __nullable borderColor);

@property (nonatomic, copy, readonly) UIView * (^jk_masksToBounds)(BOOL masksToBounds);

@property (nonatomic, assign) CGFloat jk_centerX;
@property (nonatomic, assign) CGFloat jk_centerY;

/**
 相对View本身bounds的中心点，也就是宽高的一半
 */
@property (nonatomic, assign, readonly) CGPoint jk_centerOfBounds;


@end

NS_ASSUME_NONNULL_END
