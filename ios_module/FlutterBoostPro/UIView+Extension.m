//
//  UIView+Extension.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)


- (UIView * _Nonnull (^)(UIColor * _Nullable))jk_backgroundColor {
    return ^UIView *(UIColor * value) {
        self.backgroundColor = value;
        return self;
    };
}

- (UIView * _Nonnull (^)(CGFloat))jk_cornrRadius {
    return ^UIView *(CGFloat value) {
        self.layer.cornerRadius = value;
        return self;
    };
}

- (UIView * _Nonnull (^)(CGFloat))jk_borderWidth {
    return ^UIView *(CGFloat value) {
        self.layer.borderWidth = value;
        self.layer.masksToBounds = value > 0.01;
        return self;
    };
}

- (UIView * _Nonnull (^)(UIColor * _Nullable))jk_borderColor {
    return ^UIView *(UIColor * value) {
        self.layer.borderColor = value.CGColor;
        return self;
    };
}

- (UIView * _Nonnull (^)(BOOL))jk_masksToBounds {
    return ^UIView *(BOOL value) {
        self.layer.masksToBounds = value;
        return self;
    };
}


- (void)setJk_centerX:(CGFloat)jk_centerX {
    CGPoint temp = self.center;
    temp.x = jk_centerX;
    self.center = temp;
}
- (CGFloat)jk_centerX {
    return self.center.x;
}



- (void)setJk_centerY:(CGFloat)jk_centerY {
    CGPoint temp = self.center;
    temp.y = jk_centerY;
    self.center = temp;
}
- (CGFloat)jk_centerY {
    return self.center.y;
}

- (CGPoint)jk_centerOfBounds {
    return CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
}

@end
