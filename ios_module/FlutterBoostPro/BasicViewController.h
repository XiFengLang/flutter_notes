//
//  BasicViewController.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import <UIKit/UIKit.h>
#import "Func.h"
#import <JKRetractableGCDDelay/NSObject+GCDDelayTask.h>
#import "BasicNavigationController.h"
#import "UIButton+Extension.h"
#import <Masonry/Masonry.h>

NS_ASSUME_NONNULL_BEGIN

@interface BasicViewController : UIViewController


/** 状态栏样式，默认UIStatusBarStyleDefault，不要在info.plist文件添加全局配置
 */
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;


/** 隐藏状态栏，默认false，不要在info.plist文件添加全局配置
 */
@property (nonatomic, assign) BOOL statusBarHidden;


/** 退出页面的回调，在`viewControllerWillDismissFromStack`中调用
 */
@property (nonatomic, copy) void (^__nullable exitCallBack)(void);



/**    一些初始化配置    */
- (void)didInit NS_REQUIRES_SUPER;


/** 即将退出viewController，子类可重写此方法监听页面退出事件，可实现一些内存管理的事情，移除定时器之类的。
 * 调用popViewController / dismissViewController / removeFromParentViewController 后触发此方法
 * 注意： 作为UISearchController.searchResultController时会被多次调用
 */
- (void)viewControllerWillDismissFromStack NS_REQUIRES_SUPER;


- (void)exitViewControllerAnimated:(BOOL)animated;


- (void)resetStatusBarStyle:(UIStatusBarStyle)statusBarStyle;
@end

NS_ASSUME_NONNULL_END
