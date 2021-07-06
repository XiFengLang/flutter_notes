//
//  BasicNavigationController.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "BasicNavigationController.h"

@interface BasicNavigationController ()

@end

@implementation BasicNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
}

#pragma mark - 如果返回visibleViewController，则可能导致UIAlertViewControler闪退,全部用topViewController就好

-(BOOL)shouldAutorotate{
    return self.topViewController.shouldAutorotate;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return self.topViewController.supportedInterfaceOrientations;
}

//一开始的方向
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}


- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return self.topViewController;
}

@end
