//
//  UIButton+Extension.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "UIButton+Extension.h"
#import <objc/runtime.h>


typedef NS_OPTIONS(NSUInteger, ControlState) {
    ControlStateHighlighted  = 1 << 0,                  // used when UIControl isHighlighted is set
    ControlStateDisabled     = 1 << 1,
    ControlStateSelected     = 1 << 2,                  // flag usable by app (see below)
    ControlStateFocused      = 1 << 3, // Applicable only when the screen supports focus
    ControlStateNormal       = 1 << 5, /// UIControlStateNormal == 0,不适合做位运算，所以单独设个值
};


@implementation UIButton (Extension)

#pragma mark - Priate

- (void)__setAssociatedState:(ControlState)state {
    objc_setAssociatedObject(self, "jk_state", @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ControlState)__associatedState {
    NSNumber * state = objc_getAssociatedObject(self, "jk_state");
    return state.unsignedIntegerValue;
}

- (void)__enumerateAndEvaluateStateUsingBlock:(void(^)(UIControlState state))block {
    __auto_type stateArray = @[@(ControlStateNormal),@(ControlStateHighlighted),@(ControlStateSelected),@(ControlStateDisabled)];
    NSUInteger associatedState = (NSUInteger)[self __associatedState];
    
    /// 在没有关联时，默认 UIControlStateNormal
    if (associatedState == 0) {
        block(UIControlStateNormal);
        return;
    }
    
    [stateArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger state = obj.unsignedIntegerValue;
        if (associatedState & state) {
            if (state == ControlStateNormal) {
                block(UIControlStateNormal);
            } else {
                block(state);
            }
        }
    }];
}




- (UIButton * _Nonnull (^)(UIFont * _Nonnull))jk_font {
    return ^UIButton *(UIFont * font) {
        self.titleLabel.font = font;
        return self;
    };
}

- (UIButton *)jk_normal {
    [self __setAssociatedState:(ControlStateNormal)];
    return self;
}

- (UIButton *)jk_highlighted {
    [self __setAssociatedState:(ControlStateHighlighted)];
    return self;
}

- (UIButton *)jk_selected {
    [self __setAssociatedState:(ControlStateSelected)];
    return self;
}

- (UIButton *)jk_disabled {
    [self __setAssociatedState:(ControlStateDisabled)];
    return self;
}

- (UIButton *)jk_general {
    [self __setAssociatedState:(ControlStateNormal | ControlStateHighlighted | ControlStateSelected | ControlStateDisabled)];
    return self;
}

- (UIButton * _Nonnull (^)(NSString * _Nullable))jk_title {
    return ^UIButton *(NSString * value) {
        [self __enumerateAndEvaluateStateUsingBlock:^(UIControlState state) {
            [self setTitle:value forState:state];
        }];
        return self;
    };
}



- (UIButton * _Nonnull (^)(UIColor * _Nullable))jk_titleColor {
    return ^UIButton *(UIColor * value) {
        [self __enumerateAndEvaluateStateUsingBlock:^(UIControlState state) {
            [self setTitleColor:value forState:state];
        }];
        return self;
    };
}


- (UIButton * _Nonnull (^)(UIImage * _Nullable))jk_image {
    return ^UIButton *(UIImage * value) {
        [self __enumerateAndEvaluateStateUsingBlock:^(UIControlState state) {
            [self setImage:value forState:state];
        }];
        return self;
    };
}

- (UIButton * _Nonnull (^)(UIImage * _Nullable))jk_backgroundImage {
    return ^UIButton *(UIImage * value) {
        [self __enumerateAndEvaluateStateUsingBlock:^(UIControlState state) {
            [self setBackgroundImage:value forState:state];
        }];
        return self;
    };
}

#pragma mark - 常规


- (void)setTitleFont:(UIFont *)titleFont {
    if (nil == titleFont) titleFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    self.titleLabel.font = titleFont;
}

- (UIFont *)titleFont {
    return self.titleLabel.font;
}


- (void)jk_setTitle:(NSString *)title titleColor:(UIColor *)titleColor forState:(UIControlState)state {
    [self setTitle:title forState:state];
    [self setTitleColor:titleColor forState:state];
}

+ (instancetype)jk_buttonWithFrame:(CGRect)frame {
    UIButton * button = [self buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    button.backgroundColor = UIColor.clearColor;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.contentMode = UIViewContentModeScaleAspectFit;
    
    /// 默认禁用图片高亮
    button.adjustsImageWhenHighlighted = false;
    return button;
}


+ (instancetype)jk_buttonWithFrame:(CGRect)frame titleColor:(UIColor *)color title:(NSString *)title {
    UIButton * button = [self jk_buttonWithFrame:frame];
    if (title) {
        [button jk_setTitle:title titleColor:color forState:UIControlStateNormal];
    }
    return button;
}


@end
