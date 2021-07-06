//
//  FlutterModuleHelper.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "FlutterModuleHelper.h"
#import "BasicViewController.h"

@implementation FlutterModuleHelper



+ (UIWindow *)visibleWindow {
    NSArray <UIWindow *>* windows = [UIApplication sharedApplication].windows;
    __block UIWindow * visible = nil;
    [windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIWindow class]]) {
            if (obj.isHidden == false && obj.isKeyWindow) {
                visible = obj;
                *stop = true;
            }
        }
    }];
    return visible ?: windows.lastObject;
}

+ (UIViewController *)visibleViewController {
    UIViewController * rootVC = self.visibleWindow.rootViewController;
    return [self fetchVisibleViewControllerFor:rootVC];
}


+ (UIViewController *)fetchVisibleViewControllerFor:(UIViewController *)viewController {
    if (viewController.presentedViewController) {
        return [self fetchVisibleViewControllerFor:viewController.presentedViewController];
    } else if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController * splitVC = (UISplitViewController *)viewController;
        if (splitVC.viewControllers.count) {
            return [self fetchVisibleViewControllerFor:splitVC.viewControllers.lastObject];
        } else return viewController;
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController * naviVC = (UINavigationController *)viewController;
        if (naviVC.viewControllers.count) {
            return [self fetchVisibleViewControllerFor:naviVC.visibleViewController];//或 topViewController
        } else return viewController;
    } else if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController * tabBarVC = (UITabBarController *)viewController;
        if (tabBarVC.viewControllers.count) {
            return [self fetchVisibleViewControllerFor:tabBarVC.selectedViewController];
        } else return viewController;
    } else if (viewController.childViewControllers.count) {
        return [self fetchVisibleViewControllerIn:viewController];
    } else return viewController;
}


+ (UIViewController *)fetchVisibleViewControllerIn:(UIViewController *)viewController {
    __block UIViewController * result = nil;
    UIWindow * keyWindow = [self visibleWindow];
    [viewController.childViewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect convertRect = [obj.view.superview convertRect:obj.view.frame toView:keyWindow];
        if (CGRectContainsRect(viewController.view.bounds, convertRect)) {
            result = obj;
            *stop = true;
        }
    }];
    return result ? : [self fetchVisibleViewControllerFor:viewController.childViewControllers.lastObject];
}


+ (UINavigationController *)visibleNaviagtionController {
    UIViewController * topVC = [self visibleViewController];
    if (topVC.navigationController != nil) {
        return topVC.navigationController;
    }
    
    UIViewController * rootVC = [self visibleWindow].rootViewController;
    if ([rootVC isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)rootVC;
    } else if ([rootVC isKindOfClass:UITabBarController.class]) {
        UITabBarController * tabBar = (UITabBarController *)rootVC;
        UIViewController * selected = tabBar.selectedViewController;
        if ([selected isKindOfClass:UINavigationController.class]) {
            return (UINavigationController *)selected;
        }
    }
    
    if (topVC.presentingViewController.navigationController != nil){
        return topVC.presentingViewController.navigationController;
    }
    return nil;
}

+ (void)exitViewController:(UIViewController *)vc animated:(BOOL)animated {
    if ([vc isKindOfClass:BasicViewController.class]) {
        [(BasicViewController *)vc exitViewControllerAnimated:animated];
        return;
    }
    
    if (vc.navigationController) {
        if (vc.navigationController.presentingViewController &&
            vc.navigationController.viewControllers.count == 1) {
            [vc dismissViewControllerAnimated:animated completion:nil];
        } else {
            [vc.navigationController popViewControllerAnimated:animated];
        }
    } else if (vc.presentationController) {
        [vc dismissViewControllerAnimated:animated completion:nil];
    } else {
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }
}


@end
