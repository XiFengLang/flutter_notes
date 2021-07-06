//
//  UIButton+Extension.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <UIKit/UIKit.h>
#import "UIView+Extension.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (Extension)

/**    设置按钮的标题字体    */
@property (nonatomic, copy, readonly) UIButton * (^jk_font)(UIFont * titleFont);


/**  runtime标记当前为normal状态，并不会改变按钮实际状态  */
@property (nonatomic, copy, readonly) UIButton * jk_normal;

/**  runtime标记当前为highlighted状态，并不会改变按钮实际状态  */
@property (nonatomic, copy, readonly) UIButton * jk_highlighted;

/**  runtime标记当前为selected状态，并不会改变按钮实际状态  */
@property (nonatomic, copy, readonly) UIButton * jk_selected;

/**  runtime标记当前为disabled状态，并不会改变按钮实际状态  */
@property (nonatomic, copy, readonly) UIButton * jk_disabled;

/**  runtime标记通用状态, highlighted + normal + selected + disabled，并不会改变按钮实际状态 */
@property (nonatomic, copy, readonly) UIButton * jk_general;

/** 设置title，默认是.jk_normal，需要配合.jk_normal .jk_highlighted .jk_selected .jk_disabled .jk_general一起使用
 */
@property (nonatomic, copy, readonly) UIButton * (^jk_title)(NSString * __nullable title);

/** 设置titleColor，默认是.jk_normal，需要配合.jk_normal .jk_highlighted .jk_selected .jk_disabled .jk_general一起使用
 */
@property (nonatomic, copy, readonly) UIButton * (^jk_titleColor)(UIColor * __nullable titleColor);

/** 设置image，默认是.jk_normal，需要配合.jk_normal .jk_highlighted .jk_selected .jk_disabled .jk_general一起使用
 */
@property (nonatomic, copy, readonly) UIButton * (^jk_image)(UIImage * __nullable image);

/** 设置backgroundImage，默认是.jk_normal，需要配合.jk_normal .jk_highlighted .jk_selected .jk_disabled .jk_general一起使用
 */
@property (nonatomic, copy, readonly) UIButton * (^jk_backgroundImage)(UIImage * __nullable backgroundImage);


/**    按钮的标题字体    */
@property (nonatomic, strong) UIFont * titleFont;


- (void)jk_setTitle:(NSString * __nullable)title titleColor:(UIColor * __nullable)titleColor forState:(UIControlState)state;


/**    高亮button便利构造方法    */
+ (instancetype)jk_buttonWithFrame:(CGRect)frame;


/**
 普通的文字按钮
 
 @param frame frame
 @param color titleColor
 @param title title
 @return 普通
 */
+ (instancetype)jk_buttonWithFrame:(CGRect)frame titleColor:(UIColor * __nullable)color title:(NSString * __nullable)title;



@end

NS_ASSUME_NONNULL_END
