//
//  BasicViewController.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "BasicViewController.h"


typedef enum : NSUInteger {
    ViewControllerTransitionOther,    // 其他
    ViewControllerTransitionPresent,  // Push
    ViewControllerTransitionPush,     // Modal
    ViewControllerTransitionAddition, // Addition
} ViewControllerTransition;


@interface BasicViewController ()

/**  标记转场方式  */
@property (nonatomic, assign) ViewControllerTransition transitionStyle;
/**  用来标记当前页面是不是正常的被POP出栈  */
@property (nonatomic, assign) BOOL exitMark;

@end

@implementation BasicViewController


#pragma mark - 初始化

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInit];
    }return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self didInit];
    }return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInit];
    }return self;
}


- (void)didInit {
    self.hidesBottomBarWhenPushed = true;
    _statusBarStyle = UIStatusBarStyleDefault;
    _statusBarHidden = false;
}


#pragma mark - 控制器周期


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = UIColor.whiteColor;
    }
    self.transitionStyle = ViewControllerTransitionOther;
}



- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.presentingViewController || self.isBeingPresented) {
        self.transitionStyle = ViewControllerTransitionPresent;
    } else if (self.navigationController.viewControllers.count > 1 && self.isMovingToParentViewController) {
        self.transitionStyle = ViewControllerTransitionPush;
    } else if (self.parentViewController && self.isMovingToParentViewController) {
        self.transitionStyle = ViewControllerTransitionAddition;
    }
    
    self.statusBarStyle = self.statusBarStyle;
}



- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    /**<
     注意事项：
     1、 赋值UISearchController.searchResultsController时，此处会被多次调用
     
     */
    
    switch (self.transitionStyle) {
        case ViewControllerTransitionPush:
            if (nil == self.navigationController && self.isMovingFromParentViewController)
                [self viewControllerWillDismissFromStack];
            break;
        case ViewControllerTransitionPresent:
            if (nil == self.presentingViewController || self.isBeingDismissed)
                [self viewControllerWillDismissFromStack];
            break;
        case ViewControllerTransitionAddition:
            if (nil == self.parentViewController && self.isMovingFromParentViewController)
                [self viewControllerWillDismissFromStack];
            break;
        default:
            break;
    }
}


- (void)viewControllerWillDismissFromStack {
#ifdef DEBUG
    if (self.exitMark == false) {
        __weak __typeof__(self) weakself = self;
        NSString * delayKey = [NSStringFromClass(self.class) stringByAppendingString:@"_delay"];
        [self jk_excuteDelayTaskWithKey:delayKey.UTF8String delayInSeconds:2.0 inMainQueue:^{
            if (nil != weakself) {
                NSLog(@"==============================================");
                NSLog(@"内存泄漏 Warning ⚠️:   %@ 未及时释放",weakself);
                NSLog(@"==============================================\n.");
            }
        }];
    }
#endif
    self.exitMark = true;
    
    self.exitCallBack ? self.exitCallBack() : NULL;
    self.exitCallBack = nil;
}


- (void)dealloc {
    if (self.exitMark == false) {
        self.exitMark = true;
        // 不是由当前控制器操作时不会调用viewControllerWillDismissFromStack
        [self viewControllerWillDismissFromStack];
    }
    
    
#ifdef DEBUG
    NSString * delayKey = [NSStringFromClass(self.class) stringByAppendingString:@"_delay"];
    [self jk_cancelGCDDelayTaskForKey:delayKey.UTF8String];
    printf("[***** %s     has been released]\n",[self.description UTF8String]);
#endif
}




- (void)exitViewControllerAnimated:(BOOL)animated {
    if (self.navigationController) {
        if (self.navigationController.presentingViewController &&
            self.navigationController.viewControllers.count == 1) {
            [self dismissViewControllerAnimated:animated completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:animated];
        }
    } else if (self.presentationController) {
        [self dismissViewControllerAnimated:animated completion:nil];
    } else {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
}



#pragma mark - 状态栏

- (void)resetStatusBarStyle:(UIStatusBarStyle)statusBarStyle {
    _statusBarStyle = statusBarStyle;
}

/**    隐藏iPhoneX底部的Home条    */
- (BOOL)prefersHomeIndicatorAutoHidden {
    return true;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}


- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle {
    _statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}


- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - 屏幕方向

- (BOOL)shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"\n\t**** [%@ didReceiveMemoryWarning] ****\n.",self.class);
}


@end
